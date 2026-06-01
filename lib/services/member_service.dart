import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';
import '../models/daily_stats_model.dart';
import '../models/member_model.dart';
import 'widget_service.dart';

class MemberSession {
  final String gymId;
  final String memberId;
  final String name;
  final String email;
  const MemberSession(
      {required this.gymId,
      required this.memberId,
      required this.name,
      required this.email});
}

class MemberService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  static const _kGymId = 'member_gymId';
  static const _kMemberId = 'member_memberId';
  static const _kName = 'member_name';
  static const _kEmail = 'member_email';

  // ── Password hashing ───────────────────────────────────────────────────────
  static String _hash(String password) =>
      sha256.convert(utf8.encode(password)).toString();

  // ── Step 1: Verify gym+memberId+email ─────────────────────────────────────
  Future<Map<String, dynamic>> verifyIdentity({
    required String gymId,
    required String memberId,
    required String email,
  }) async {
    try {
      final id = memberId.trim().toUpperCase();
      final em = email.trim().toLowerCase();
      final gid = gymId.trim();

      final doc = await _db
          .collection('gyms')
          .doc(gid)
          .collection('members')
          .doc(id)
          .get();

      if (!doc.exists) {
        return {
          'success': false,
          'error':
              'Member ID "$id" not found in gym "$gid".\nCheck with your gym owner.'
        };
      }

      final data = doc.data()!;
      final stored = (data['email'] as String? ?? '').toLowerCase().trim();

      if (stored != em) {
        return {
          'success': false,
          'error':
              'Email does not match our records.\nCheck with your gym owner.'
        };
      }
      if (data['isActive'] == false) {
        return {
          'success': false,
          'error': 'Your membership is inactive.\nContact your gym owner.'
        };
      }

      // Check if password has been set
      final hasPassword = (data['passwordHash'] as String?) != null &&
          (data['passwordHash'] as String).isNotEmpty;

      return {
        'success': true,
        'hasPassword': hasPassword,
        'data': data,
        'gymId': gid,
        'memberId': id,
      };
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('permission-denied') ||
          msg.contains('PERMISSION_DENIED')) {
        return {
          'success': false,
          'error':
              'Permission denied.\nAsk your gym owner to deploy Firestore rules.'
        };
      }
      return {'success': false, 'error': 'Verification failed: $msg'};
    }
  }

  // ── Step 2a: Login with password ─────────────────────────────────────────
  Future<Map<String, dynamic>> loginWithPassword({
    required String gymId,
    required String memberId,
    required String password,
    required Map<String, dynamic> memberData,
  }) async {
    final storedHash = memberData['passwordHash'] as String? ?? '';
    if (_hash(password) != storedHash) {
      return {
        'success': false,
        'error': 'Incorrect password. Please try again.'
      };
    }
    await _saveSession(gymId: gymId, memberId: memberId, data: memberData);
    return {'success': true, 'data': memberData};
  }

  // ── Step 2b: Set new password (first-time login) ─────────────────────────
  Future<Map<String, dynamic>> setPasswordAndLogin({
    required String gymId,
    required String memberId,
    required String password,
    required Map<String, dynamic> memberData,
  }) async {
    try {
      final hash = _hash(password);
      await _db
          .collection('gyms')
          .doc(gymId)
          .collection('members')
          .doc(memberId)
          .update({'passwordHash': hash});

      await _saveSession(gymId: gymId, memberId: memberId, data: memberData);
      return {'success': true, 'data': memberData};
    } catch (e) {
      return {
        'success': false,
        'error': 'Failed to set password: ${e.toString()}'
      };
    }
  }

  Future<void> _saveSession({
    required String gymId,
    required String memberId,
    required Map<String, dynamic> data,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kGymId, gymId);
    await prefs.setString(_kMemberId, memberId);
    await prefs.setString(_kName, data['name'] ?? '');
    await prefs.setString(
        _kEmail, (data['email'] ?? '').toString().toLowerCase());
  }

  Future<MemberSession?> getSession() async {
    final prefs = await SharedPreferences.getInstance();
    final gymId = prefs.getString(_kGymId);
    final memberId = prefs.getString(_kMemberId);
    final name = prefs.getString(_kName);
    final email = prefs.getString(_kEmail);
    if (gymId == null || memberId == null) return null;
    return MemberSession(
        gymId: gymId, memberId: memberId, name: name ?? '', email: email ?? '');
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kGymId);
    await prefs.remove(_kMemberId);
    await prefs.remove(_kName);
    await prefs.remove(_kEmail);
  }

  // ── Member profile ────────────────────────────────────────────────────────
  Stream<MemberModel?> memberStream(String gymId, String memberId) {
    return _db
        .collection('gyms')
        .doc(gymId)
        .collection('members')
        .doc(memberId)
        .snapshots()
        .map((s) => s.exists ? MemberModel.fromMap(s.data()!, s.id) : null);
  }

  // ── Daily stats ───────────────────────────────────────────────────────────
  static String todayKey() {
    final n = DateTime.now();
    return '${n.year}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')}';
  }

  Stream<DailyStats> todayStatsStream(String gymId, String memberId) {
    final key = todayKey();
    return _db
        .collection('gyms')
        .doc(gymId)
        .collection('members')
        .doc(memberId)
        .collection('daily_stats')
        .doc(key)
        .snapshots()
        .map((s) =>
            s.exists ? DailyStats.fromMap(s.data()!) : DailyStats(date: key));
  }

  Future<DailyStats> getTodayStats(String gymId, String memberId) async {
    final key = todayKey();
    try {
      final doc = await _db
          .collection('gyms')
          .doc(gymId)
          .collection('members')
          .doc(memberId)
          .collection('daily_stats')
          .doc(key)
          .get();
      if (doc.exists) return DailyStats.fromMap(doc.data()!);
    } catch (_) {}
    return DailyStats(date: key);
  }

  Future<void> _saveStats(
      String gymId, String memberId, DailyStats stats) async {
    final key = stats.date.isEmpty ? todayKey() : stats.date;
    await _db
        .collection('gyms')
        .doc(gymId)
        .collection('members')
        .doc(memberId)
        .collection('daily_stats')
        .doc(key)
        .set(stats.toMap(), SetOptions(merge: true));

    // Point delta
    final prefs = await SharedPreferences.getInstance();
    final pts = stats.score;
    final prev = prefs.getInt('pts_${memberId}_$key') ?? 0;
    final delta = pts - prev;
    await prefs.setInt('pts_${memberId}_$key', pts);
    if (delta != 0) {
      _db
          .collection('gyms')
          .doc(gymId)
          .collection('members')
          .doc(memberId)
          .update({'totalPoints': FieldValue.increment(delta)}).then((_) async {
        // Check milestone achievements after points update
        try {
          final doc = await _db
              .collection('gyms')
              .doc(gymId)
              .collection('members')
              .doc(memberId)
              .get();
          final newTotal = (doc.data()?['totalPoints'] as int?) ?? 0;
          final name = (doc.data()?['name'] as String?) ?? 'Member';
          await _checkAndLogMilestone(gymId, memberId, name, newTotal);
        } catch (_) {}
      }).catchError((_) {});
    }
    WidgetService.update(
        steps: stats.steps, waterMl: stats.waterMl, score: pts);
  }

  Future<void> addWater(String gymId, String memberId) async {
    final stats = await getTodayStats(gymId, memberId);
    await _saveStats(
        gymId, memberId, stats.copyWith(waterMl: stats.waterMl + 250));
  }

  // Sets water to an absolute value — used to sync taps from the home screen widget.
  Future<void> setWater(String gymId, String memberId, int waterMl) async {
    final stats = await getTodayStats(gymId, memberId);
    await _saveStats(gymId, memberId, stats.copyWith(waterMl: waterMl));
  }

  Future<void> updateSteps(String gymId, String memberId, int steps) async {
    final stats = await getTodayStats(gymId, memberId);
    await _saveStats(
        gymId,
        memberId,
        stats.copyWith(
            steps: steps, calories: DailyStats.caloriesFromSteps(steps)));
  }

  // ── Check-in ──────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> checkIn(String gymId, String memberId) async {
    try {
      final key = todayKey();
      final stats = await getTodayStats(gymId, memberId);
      if (stats.checkedIn) {
        return {
          'success': false,
          'error': 'Already checked in today! Come back tomorrow.'
        };
      }

      // Streak calc
      int streak = 0;
      try {
        final mDoc = await _db
            .collection('gyms')
            .doc(gymId)
            .collection('members')
            .doc(memberId)
            .get();
        streak = (mDoc.data()?['currentStreak'] as int?) ?? 0;
      } catch (_) {}

      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final yKey =
          '${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}';
      bool yChecked = false;
      try {
        final yDoc = await _db
            .collection('gyms')
            .doc(gymId)
            .collection('members')
            .doc(memberId)
            .collection('daily_stats')
            .doc(yKey)
            .get();
        yChecked = (yDoc.data()?['checkedIn'] as bool?) ?? false;
      } catch (_) {}

      if (DateTime.now().weekday == DateTime.monday || !yChecked) {
        streak = 1;
      } else {
        streak = streak + 1;
      }

      final checkinPts = DailyStats.streakCheckinPoints(streak);
      await _saveStats(gymId, memberId,
          stats.copyWith(checkedIn: true, currentStreak: streak));

      _db
          .collection('gyms')
          .doc(gymId)
          .collection('attendance')
          .doc(key)
          .set({'count': FieldValue.increment(1)}, SetOptions(merge: true));
      _db
          .collection('gyms')
          .doc(gymId)
          .collection('members')
          .doc(memberId)
          .update({
        'totalAttendance': FieldValue.increment(1),
        'currentStreak': streak,
        'lastVisit': FieldValue.serverTimestamp()
      }).then((_) async {
        try {
          final doc = await _db
              .collection('gyms')
              .doc(gymId)
              .collection('members')
              .doc(memberId)
              .get();
          final pts = (doc.data()?['totalPoints'] as int?) ?? 0;
          final att = (doc.data()?['totalAttendance'] as int?) ?? 0;
          final name = (doc.data()?['name'] as String?) ?? 'Member';
          await _checkAndLogMilestone(gymId, memberId, name, pts,
              attendance: att);
        } catch (_) {}
      }).catchError((_) {});

      return {
        'success': true,
        'points': checkinPts,
        'streak': streak,
        'message': streak >= 3
            ? '🔥 ${streak}d streak! +${checkinPts}pts'
            : streak == 2
                ? '⚡ 2-day streak! +${checkinPts}pts'
                : '✅ Checked in! +${checkinPts}pts',
      };
    } catch (e) {
      return {'success': false, 'error': 'Check-in failed: ${e.toString()}'};
    }
  }

  // ── Workout plan ──────────────────────────────────────────────────────────
  Future<void> saveWorkoutPlan(
      String gymId, String memberId, Map<String, dynamic> plan) async {
    await _db
        .collection('gyms')
        .doc(gymId)
        .collection('members')
        .doc(memberId)
        .update({
      'workoutPlan': plan,
      'planUpdatedAt': FieldValue.serverTimestamp()
    }).catchError((_) {});
  }

  Future<Map<String, dynamic>?> getWorkoutPlan(
      String gymId, String memberId) async {
    try {
      final doc = await _db
          .collection('gyms')
          .doc(gymId)
          .collection('members')
          .doc(memberId)
          .get();
      return doc.data()?['workoutPlan'] as Map<String, dynamic>?;
    } catch (_) {
      return null;
    }
  }

  // ── Announcements (last 24h) ──────────────────────────────────────────────
  Stream<List<Map<String, dynamic>>> announcementsStream(String gymId) {
    final cutoff =
        Timestamp.fromDate(DateTime.now().subtract(const Duration(hours: 24)));
    return _db
        .collection('gyms')
        .doc(gymId)
        .collection('announcements')
        .where('timestamp', isGreaterThan: cutoff)
        .orderBy('timestamp', descending: true)
        .limit(10)
        .snapshots()
        .map((s) => s.docs.map((d) => d.data()).toList());
  }

  // ── Prize ─────────────────────────────────────────────────────────────────
  Stream<String?> prizeStream(String gymId) {
    return _db
        .collection('gyms')
        .doc(gymId)
        .snapshots()
        .map((s) => s.data()?['monthlyPrize'] as String?);
  }

  // ── Leaderboard (client-side sort, no composite index) ───────────────────
  Stream<List<MemberModel>> leaderboardStream(String gymId) {
    return _db
        .collection('gyms')
        .doc(gymId)
        .collection('members')
        .snapshots()
        .map((s) {
      try {
        final all = s.docs
            .map((d) => MemberModel.fromMap(d.data(), d.id))
            .where((m) => m.isActive)
            .toList();
        all.sort((a, b) => b.totalPoints.compareTo(a.totalPoints));
        return all.take(50).toList();
      } catch (_) {
        return <MemberModel>[];
      }
    });
  }

  // ── Week history ──────────────────────────────────────────────────────────
  Future<List<DailyStats>> getWeekHistory(String gymId, String memberId) async {
    final now = DateTime.now();
    final result = <DailyStats>[];
    for (int i = 6; i >= 0; i--) {
      final day = now.subtract(Duration(days: i));
      final key =
          '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
      try {
        final doc = await _db
            .collection('gyms')
            .doc(gymId)
            .collection('members')
            .doc(memberId)
            .collection('daily_stats')
            .doc(key)
            .get();
        result.add(doc.exists
            ? DailyStats.fromMap(doc.data()!)
            : DailyStats(date: key));
      } catch (_) {
        result.add(DailyStats(date: key));
      }
    }
    return result;
  }

  Future<List<DailyStats>> getMemberHistory(String gymId, String memberId,
      {int days = 30}) async {
    final now = DateTime.now();
    final result = <DailyStats>[];
    for (int i = days - 1; i >= 0; i--) {
      final day = now.subtract(Duration(days: i));
      final key =
          '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
      try {
        final doc = await _db
            .collection('gyms')
            .doc(gymId)
            .collection('members')
            .doc(memberId)
            .collection('daily_stats')
            .doc(key)
            .get();
        result.add(doc.exists
            ? DailyStats.fromMap(doc.data()!)
            : DailyStats(date: key));
      } catch (_) {
        result.add(DailyStats(date: key));
      }
    }
    return result;
  }

  Future<int> getMemberRank(String gymId, String memberId) async {
    try {
      final snap = await _db
          .collection('gyms')
          .doc(gymId)
          .collection('members')
          .orderBy('totalPoints', descending: true)
          .get();
      final docs = snap.docs
          .where((d) => (d.data()['isActive'] as bool?) == true)
          .toList();
      final idx = docs.indexWhere((d) => d.id == memberId);
      return idx >= 0 ? idx + 1 : 0;
    } catch (_) {
      return 0;
    }
  }

  // ── Milestone achievement logger ─────────────────────────────────────────
  static const _kPointsMilestones = [100, 250, 500, 1000, 2000, 5000];
  static const _kAttendMilestones = [5, 10, 25, 50, 100];

  Future<void> _checkAndLogMilestone(
      String gymId, String memberId, String memberName, int totalPoints,
      {int attendance = 0}) async {
    final prefs = await SharedPreferences.getInstance();

    // Points milestones
    for (final m in _kPointsMilestones) {
      if (totalPoints >= m) {
        final key = 'milestone_pts_${memberId}_$m';
        if (prefs.getBool(key) != true) {
          await prefs.setBool(key, true);
          _db.collection('gyms').doc(gymId).collection('achievements').add({
            'memberId': memberId,
            'memberName': memberName,
            'type': 'points',
            'milestone': m,
            'title': '$memberName reached $m points!',
            'icon': 'star',
            'timestamp': FieldValue.serverTimestamp(),
          }).catchError((Object _) => _db.collection('gyms').doc(gymId));
        }
      }
    }

    // Attendance milestones
    if (attendance > 0) {
      for (final m in _kAttendMilestones) {
        if (attendance >= m) {
          final key = 'milestone_att_${memberId}_$m';
          if (prefs.getBool(key) != true) {
            await prefs.setBool(key, true);
            _db.collection('gyms').doc(gymId).collection('achievements').add({
              'memberId': memberId,
              'memberName': memberName,
              'type': 'attendance',
              'milestone': m,
              'title': '$memberName hit $m gym visits!',
              'icon': 'fitness_center',
              'timestamp': FieldValue.serverTimestamp(),
            }).catchError((Object _) => _db.collection('gyms').doc(gymId));
          }
        }
      }
    }
  }

  Future<Map<String, dynamic>?> getLatestAnnouncement(String gymId) async {
    try {
      final snap = await _db
          .collection('gyms')
          .doc(gymId)
          .collection('announcements')
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();
      if (snap.docs.isEmpty) return null;
      final data = snap.docs.first.data();
      data['id'] = snap.docs.first.id;
      return data;
    } catch (_) {
      return null;
    }
  }

  Future<void> addPoints(String gymId, String memberId, int points) async {
    try {
      await _db
          .collection('gyms')
          .doc(gymId)
          .collection('members')
          .doc(memberId)
          .update({'totalPoints': FieldValue.increment(points)});
    } catch (_) {}
  }

  /// Upload profile photo — works on web, Android, and iOS.
  ///
  /// Path 1 (preferred): Firebase Auth token → Firebase Storage REST API.
  /// Path 2 (fallback):  base64 data-URL stored directly in Firestore doc.
  ///
  /// BUG FIXES:
  ///   • Added 30 s timeout — previously could hang forever on bad network.
  ///   • Added 401 auto-retry with token refresh — stale token no longer
  ///     causes a silent failure.
  ///   • Added 900 KB size guard — Firestore field limit is 1 MB; base64
  ///     adds ~33% overhead, so raw bytes must stay under ~900 KB.
  ///   • Error is now printed with stack trace so it shows up in DevTools.
  Future<String?> uploadProfilePhotoBytes(
    String gymId,
    String memberId,
    Uint8List bytes, {
    String contentType = 'image/jpeg',
  }) async {
    if (bytes.isEmpty) return null;

    // 900 KB guard: base64 of 900 KB ≈ 1.24 MB → could exceed Firestore limit
    const maxBytes = 900 * 1024;

    try {
      // ── Path 1: Firebase Storage (any authenticated user) ─────────────
      final user = _auth.currentUser;
      if (user != null) {
        String? token = await user.getIdToken();
        if (token != null) {
          const bucket = 'gymforge-f9fe3.firebasestorage.app';
          final objectPath = 'profile_photos/$gymId/$memberId.jpg';
          final encoded = Uri.encodeComponent(objectPath);
          final uploadUrl =
              'https://firebasestorage.googleapis.com/v0/b/$bucket'
              '/o?uploadType=media&name=$encoded';

          var res = await http.post(
            Uri.parse(uploadUrl),
            headers: {'Authorization': 'Bearer $token', 'Content-Type': contentType},
            body: bytes,
          ).timeout(const Duration(seconds: 30));

          // Auto-retry on stale token
          if (res.statusCode == 401) {
            token = await user.getIdToken(true);
            if (token != null) {
              res = await http.post(
                Uri.parse(uploadUrl),
                headers: {'Authorization': 'Bearer $token', 'Content-Type': contentType},
                body: bytes,
              ).timeout(const Duration(seconds: 30));
            }
          }

          if (res.statusCode == 200) {
            final downloadUrl =
                'https://firebasestorage.googleapis.com/v0/b/$bucket'
                '/o/$encoded?alt=media';
            await _db
                .collection('gyms').doc(gymId)
                .collection('members').doc(memberId)
                .update({'photoUrl': downloadUrl});
            return downloadUrl;
          }
          debugPrint('Storage upload failed ${res.statusCode}: ${res.body}');
        }
      }

      // ── Path 2: base64 data-URL in Firestore (member sessions) ────────
      if (bytes.length > maxBytes) {
        debugPrint('Image too large (${bytes.length}B) for Firestore fallback.');
        return null;
      }
      final dataUrl = 'data:$contentType;base64,${base64Encode(bytes)}';
      await _db
          .collection('gyms').doc(gymId)
          .collection('members').doc(memberId)
          .update({'photoUrl': dataUrl});
      return dataUrl;
    } catch (e, st) {
      debugPrint('Photo upload error: $e\n$st');
      return null;
    }
  }

  /// Stream that emits the latest photoUrl for a member.
  Stream<String> photoUrlStream(String gymId, String memberId) {
    return _db
        .collection('gyms')
        .doc(gymId)
        .collection('members')
        .doc(memberId)
        .snapshots()
        .map((doc) => (doc.data()?['photoUrl'] as String?) ?? '');
  }
}

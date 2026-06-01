import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/member_model.dart';
import '../models/staff_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ─── GYM ──────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>?> getGym(String gymId) async {
    try {
      final doc = await _db.collection('gyms').doc(gymId).get();
      return doc.data();
    } catch (_) {
      return null;
    }
  }

  Stream<Map<String, dynamic>?> gymStream(String gymId) {
    return _db
        .collection('gyms')
        .doc(gymId)
        .snapshots()
        .map((snap) => snap.data());
  }

  /// Best-effort: update a field on the gym document.
  /// Never throws — failures are silently ignored.
  void _updateGymSilently(String gymId, Map<String, dynamic> data) {
    _db.collection('gyms').doc(gymId).update(data).catchError((_) {});
  }

  /// Best-effort: add a document to any subcollection.
  /// Never throws — failures are silently ignored.
  void _addSubDocSilently(
      String gymId,
      String sub,
      Map<String, dynamic> data,
      ) {
    _db
        .collection('gyms')
        .doc(gymId)
        .collection(sub)
        .add(data)
        .catchError((Object _) => _db.collection('gyms').doc(gymId));
  }

  // ─── MEMBERS ──────────────────────────────────────────────────────────────

  Stream<List<MemberModel>> membersStream(String gymId) {
    return _db
        .collection('gyms')
        .doc(gymId)
        .collection('members')
        .orderBy('name')
        .snapshots()
        .map((snap) => snap.docs
        .map((doc) => MemberModel.fromMap(doc.data(), doc.id))
        .toList());
  }

  /// Core write: member document.
  /// Secondary writes (counter + payment) are fire-and-forget — they
  /// NEVER block or throw back to the caller.
  Future<void> addMember(MemberModel member) async {
    // Primary write — this is what matters
    await _db
        .collection('gyms')
        .doc(member.gymId)
        .collection('members')
        .doc(member.memberId)
        .set(member.toMap());

    // Secondary: increment counter (best-effort, may fail with old rules)
    _updateGymSilently(member.gymId, {
      'totalMembers': FieldValue.increment(1),
    });

    // Secondary: log payment (best-effort)
    if (member.planFee > 0) {
      _addSubDocSilently(member.gymId, 'payments', {
        'memberId': member.memberId,
        'memberName': member.name,
        'amount': member.planFee,
        'planType': member.planType,
        'paidAt': FieldValue.serverTimestamp(),
        'note': 'Initial registration',
      });
    }
  }

  Future<void> updateMember(MemberModel member) async {
    await _db
        .collection('gyms')
        .doc(member.gymId)
        .collection('members')
        .doc(member.id)
        .update(member.toMap());
  }

  Future<bool> memberIdExists(String gymId, String memberId) async {
    try {
      final doc = await _db
          .collection('gyms')
          .doc(gymId)
          .collection('members')
          .doc(memberId)
          .get();
      return doc.exists;
    } catch (_) {
      return false;
    }
  }

  /// Extends paymentCycleDate by the plan duration.
  /// If already expired, renewal starts from today.
  Future<void> renewMembership(
      String gymId,
      String memberId,
      String planType,
      DateTime currentCycleDate, {
        double planFee = 0.0,
        String memberName = '',
      }) async {
    final now = DateTime.now();
    final base = currentCycleDate.isBefore(now) ? now : currentCycleDate;

    final DateTime newDate;
    switch (planType) {
      case 'Quarterly':
        newDate = DateTime(base.year, base.month + 3, base.day);
        break;
      case 'Annual':
        newDate = DateTime(base.year + 1, base.month, base.day);
        break;
      default:
        newDate = DateTime(base.year, base.month + 1, base.day);
    }

    // Primary write
    await _db
        .collection('gyms')
        .doc(gymId)
        .collection('members')
        .doc(memberId)
        .update({
      'paymentCycleDate': Timestamp.fromDate(newDate),
      'isActive': true,
    });

    // Secondary: log payment (best-effort)
    if (planFee > 0) {
      _addSubDocSilently(gymId, 'payments', {
        'memberId': memberId,
        'memberName': memberName,
        'amount': planFee,
        'planType': planType,
        'paidAt': FieldValue.serverTimestamp(),
        'note': 'Renewal',
      });
    }
  }

  Future<void> toggleMemberStatus(
      String gymId, String memberId, bool isActive) async {
    await _db
        .collection('gyms')
        .doc(gymId)
        .collection('members')
        .doc(memberId)
        .update({'isActive': isActive});

    // Best-effort counter update
    _updateGymSilently(gymId, {
      'totalMembers': FieldValue.increment(isActive ? 1 : -1),
    });
  }

  // ─── STAFF ────────────────────────────────────────────────────────────────

  Stream<List<StaffModel>> staffStream(String gymId) {
    return _db
        .collection('gyms')
        .doc(gymId)
        .collection('staff')
        .orderBy('name')
        .snapshots()
        .map((snap) => snap.docs
        .map((doc) => StaffModel.fromMap(doc.data(), doc.id))
        .toList());
  }

  Future<void> addStaff(StaffModel staff) async {
    await _db
        .collection('gyms')
        .doc(staff.gymId)
        .collection('staff')
        .doc(staff.staffId)
        .set(staff.toMap());
  }

  Future<void> toggleStaffStatus(
      String gymId, String staffId, bool isActive) async {
    await _db
        .collection('gyms')
        .doc(gymId)
        .collection('staff')
        .doc(staffId)
        .update({'isActive': isActive});
  }

  Future<bool> staffIdExists(String gymId, String staffId) async {
    try {
      final doc = await _db
          .collection('gyms')
          .doc(gymId)
          .collection('staff')
          .doc(staffId)
          .get();
      return doc.exists;
    } catch (_) {
      return false;
    }
  }

  // ─── ATTENDANCE ───────────────────────────────────────────────────────────

  Stream<int> todayAttendanceStream(String gymId) {
    final now = DateTime.now();
    final dateKey =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    return _db
        .collection('gyms')
        .doc(gymId)
        .collection('attendance')
        .doc(dateKey)
        .snapshots()
        .map((snap) => (snap.data()?['count'] as int?) ?? 0);
  }

  Future<Map<int, int>> getCheckinHeatmap(String gymId) async {
    final cutoff = DateTime.now().subtract(const Duration(days: 30));
    final Map<int, int> heatmap = {for (int i = 5; i <= 22; i++) i: 0};
    try {
      final snap = await _db
          .collection('gyms')
          .doc(gymId)
          .collection('checkin_logs')
          .where('timestamp', isGreaterThan: Timestamp.fromDate(cutoff))
          .get();
      for (final doc in snap.docs) {
        final ts = (doc['timestamp'] as Timestamp?)?.toDate();
        if (ts != null) {
          heatmap[ts.hour] = (heatmap[ts.hour] ?? 0) + 1;
        }
      }
    } catch (_) {}
    return heatmap;
  }

  // ─── ANNOUNCEMENTS ────────────────────────────────────────────────────────

  Future<void> sendAnnouncement(
      String gymId, String message, String ownerName) async {
    await _db
        .collection('gyms')
        .doc(gymId)
        .collection('announcements')
        .add({
      'message': message,
      'sentBy': ownerName,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  // ─── ACHIEVEMENTS ─────────────────────────────────────────────────────────

  Stream<List<Map<String, dynamic>>> recentAchievementsStream(String gymId) {
    return _db
        .collection('gyms')
        .doc(gymId)
        .collection('achievements')
        .orderBy('timestamp', descending: true)
        .limit(5)
        .snapshots()
        .map((snap) => snap.docs.map((doc) => doc.data()).toList());
  }

  // ─── LEADERBOARD ──────────────────────────────────────────────────────────

  Stream<List<MemberModel>> leaderboardStream(String gymId) {
    // NOTE: Combining .where('isActive') + .orderBy('totalPoints') requires a
    // composite Firestore index. To avoid that requirement (and the silent
    // empty-result failure when the index is missing), we query by totalPoints
    // only (single-field index, auto-created) and filter isActive in Dart.
    return _db
        .collection('gyms')
        .doc(gymId)
        .collection('members')
        .orderBy('totalPoints', descending: true)
        .limit(50)
        .snapshots()
        .map((snap) => snap.docs
        .map((doc) => MemberModel.fromMap(doc.data(), doc.id))
        .where((m) => m.isActive)
        .toList());
  }

  // ─── REVENUE ──────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getRevenueData(String gymId) async {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final startOfLastMonth = DateTime(now.year, now.month - 1, 1);
    try {
      final thisSnap = await _db
          .collection('gyms')
          .doc(gymId)
          .collection('payments')
          .where('paidAt',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
          .get();
      final lastSnap = await _db
          .collection('gyms')
          .doc(gymId)
          .collection('payments')
          .where('paidAt',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startOfLastMonth))
          .where('paidAt', isLessThan: Timestamp.fromDate(startOfMonth))
          .get();

      double thisMonth = 0;
      double lastMonth = 0;
      for (final d in thisSnap.docs) {
        thisMonth += (d.data()['amount'] as num?)?.toDouble() ?? 0;
      }
      for (final d in lastSnap.docs) {
        lastMonth += (d.data()['amount'] as num?)?.toDouble() ?? 0;
      }
      final change = lastMonth > 0
          ? ((thisMonth - lastMonth) / lastMonth * 100).toStringAsFixed(1)
          : '0';
      return {
        'thisMonth': thisMonth,
        'lastMonth': lastMonth,
        'change': change,
      };
    } catch (_) {
      return {'thisMonth': 0.0, 'lastMonth': 0.0, 'change': '0'};
    }
  }

  // ── Prize ─────────────────────────────────────────────────────────────────

  Stream<String?> prizeStream(String gymId) {
    return _db.collection('gyms').doc(gymId)
        .snapshots()
        .map((s) => s.data()?['monthlyPrize'] as String?);
  }

  Future<void> setPrize(String gymId, String prize) async {
    await _db.collection('gyms').doc(gymId).update({'monthlyPrize': prize});
  }

  Future<void> setMonthlyPrize(String gymId, String prize) => setPrize(gymId, prize);

}

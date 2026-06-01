import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// ── GymForge Notification Service ──────────────────────────────────────────
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  // ── Channel IDs ────────────────────────────────────────────────────────────
  static const String _chOwner    = 'gymforge_owner';
  static const String _chMember   = 'gymforge_member';
  static const String _chWater    = 'gymforge_water';
  static const String _chGreeting = 'gymforge_greeting';

  // ── Init ──────────────────────────────────────────────────────────────────
  Future<void> init() async {
    if (_initialized) return;
    tz.initializeTimeZones();
    try { tz.setLocalLocation(tz.local); } catch (_) {}

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios     = DarwinInitializationSettings(
      requestAlertPermission:  false, // we request manually
      requestBadgePermission:  false,
      requestSoundPermission:  false,
    );
    await _plugin.initialize(
      settings: const InitializationSettings(android: android, iOS: ios),
    );
    await _ensureChannels();
    _initialized = true;
  }

  Future<void> _ensureChannels() async {
    if (!Platform.isAndroid) return;
    final ap = _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (ap == null) return;
    for (final ch in [
      const AndroidNotificationChannel(_chGreeting, 'Greetings',
          description: 'Good morning / Good evening messages',
          importance: Importance.high),
      const AndroidNotificationChannel(_chOwner, 'Owner Alerts',
          description: 'Renewal, achievement and retention alerts',
          importance: Importance.high),
      const AndroidNotificationChannel(_chMember, 'Member Alerts',
          description: 'Membership, competition and announcement alerts',
          importance: Importance.high),
      const AndroidNotificationChannel(_chWater, 'Water Reminders',
          description: 'Drink water reminders',
          importance: Importance.defaultImportance),
    ]) {
      await ap.createNotificationChannel(ch);
    }
  }

  // ── Permission ────────────────────────────────────────────────────────────
  /// Returns true if notification permission is granted.
  /// Uses permission_handler for reliable cross-platform behaviour.
  Future<bool> requestPermission() async {
    if (!_initialized) await init();
    // On Android 13+ this shows the system notification permission dialog
    final status = await Permission.notification.status;
    if (status.isGranted) return true;
    if (status.isPermanentlyDenied) return false;
    final result = await Permission.notification.request();
    return result.isGranted;
  }

  /// Call on app start. Requests permission once, then sends greeting.
  Future<void> initAndGreet(String userName, {bool isOwner = false}) async {
    await init();

    // Request permission (shows dialog on first launch only, OS handles repeat)
    await requestPermission();

    // Send greeting based on current hour
    await sendGreeting(userName, isOwner: isOwner);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // GREETING NOTIFICATIONS
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> sendGreeting(String name, {bool isOwner = false}) async {
    if (!_initialized) await init();
    final prefs  = await SharedPreferences.getInstance();
    final today  = DateTime.now().toIso8601String().substring(0, 10);
    final hour   = DateTime.now().hour;
    final period = hour < 12 ? 'morning' : hour < 17 ? 'afternoon' : 'evening';

    // Only send once per period per day
    final key = 'greet_${period}_$today';
    if (prefs.getBool(key) == true) return;
    await prefs.setBool(key, true);

    final String emoji;
    final String title;
    final String body;

    if (hour < 12) {
      emoji = '☀️';
      title = 'Good Morning, $name!';
      body  = isOwner
          ? 'Ready to manage your gym? Check today\'s check-ins and renewals.'
          : 'Morning! Log your workout and track your steps today.';
    } else if (hour < 17) {
      emoji = '🌤️';
      title = 'Good Afternoon, $name!';
      body  = isOwner
          ? 'Afternoon check-in — see who\'s visited the gym today.'
          : 'Keep going! Don\'t forget to log water and steps.';
    } else {
      emoji = '🌙';
      title = 'Good Evening, $name!';
      body  = isOwner
          ? 'Evening wrap-up — review today\'s attendance and renewals.'
          : 'Great evening! Log your water intake before bed.';
    }

    await _show(
      id: 100,
      title: '$emoji $title',
      body: body,
      channel: _chGreeting,
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // OWNER NOTIFICATIONS
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> checkRenewalAlerts(String gymId) async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().substring(0, 10);
    if (prefs.getString('renewal_check_$today') == '1') return;
    await prefs.setString('renewal_check_$today', '1');

    try {
      final snap = await FirebaseFirestore.instance
          .collection('gyms').doc(gymId).collection('members')
          .where('isActive', isEqualTo: true).get();

      for (final doc in snap.docs) {
        final data = doc.data();
        final name = (data['name'] as String?) ?? 'Member';
        final ts   = data['paymentCycleDate'] as Timestamp?;
        if (ts == null) continue;
        final days = ts.toDate().difference(DateTime.now()).inDays;

        if (days <= 0) {
          await _show(id: 1000 + doc.id.hashCode.abs() % 500,
              title: '⚠️ Expired: $name',
              body: 'Membership expired. Tap to renew.',
              channel: _chOwner);
        } else if (days <= 3) {
          await _show(id: 1500 + doc.id.hashCode.abs() % 500,
              title: '🔔 Renewal Due: $name',
              body: '$days day${days == 1 ? '' : 's'} left.',
              channel: _chOwner);
        }
      }
    } catch (_) {}
  }

  Future<void> notifyOwnerAchievement(String memberName, String title) async {
    await _show(id: 2000 + memberName.hashCode.abs() % 999,
        title: '🏆 Achievement!',
        body: '$memberName — $title',
        channel: _chOwner);
  }

  Future<void> checkRetentionAlerts(String gymId) async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().substring(0, 10);
    if (prefs.getString('retention_check_$today') == '1') return;
    await prefs.setString('retention_check_$today', '1');

    try {
      final snap = await FirebaseFirestore.instance
          .collection('gyms').doc(gymId).collection('members')
          .where('isActive', isEqualTo: true).get();
      int atRisk = 0;
      for (final doc in snap.docs) {
        final ts = doc.data()['lastVisit'] as Timestamp?;
        if (ts == null) continue;
        if (DateTime.now().difference(ts.toDate()).inDays >= 10) atRisk++;
      }
      if (atRisk > 0) {
        await _show(id: 3100,
            title: '📉 Retention Alert',
            body: '$atRisk member${atRisk > 1 ? 's haven\'t' : ' hasn\'t'} visited in 10+ days.',
            channel: _chOwner);
      }
    } catch (_) {}
  }

  Future<void> checkLeaderboardChange(String gymId) async {
    final prefs = await SharedPreferences.getInstance();
    final lastTop = prefs.getString('lb_top_$gymId') ?? '';
    try {
      final snap = await FirebaseFirestore.instance
          .collection('gyms').doc(gymId).collection('members')
          .where('isActive', isEqualTo: true)
          .orderBy('totalPoints', descending: true).limit(1).get();
      if (snap.docs.isEmpty) return;
      final newTop = snap.docs.first.data()['name'] as String? ?? '';
      if (newTop.isNotEmpty && lastTop.isNotEmpty && newTop != lastTop) {
        await _show(id: 3200,
            title: '🥇 New #1 Leader!',
            body: '$newTop has taken the top spot!',
            channel: _chOwner);
      }
      if (newTop.isNotEmpty) await prefs.setString('lb_top_$gymId', newTop);
    } catch (_) {}
  }

  // ─────────────────────────────────────────────────────────────────────────
  // MEMBER NOTIFICATIONS
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> checkMembershipExpiry(String gymId, String memberId) async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().substring(0, 10);
    if (prefs.getString('expiry_${memberId}_$today') == '1') return;
    await prefs.setString('expiry_${memberId}_$today', '1');

    try {
      final doc = await FirebaseFirestore.instance
          .collection('gyms').doc(gymId).collection('members').doc(memberId).get();
      if (!doc.exists) return;
      final ts = doc.data()?['paymentCycleDate'] as Timestamp?;
      if (ts == null) return;
      final days = ts.toDate().difference(DateTime.now()).inDays;
      if (days < 0) {
        await _show(id: 5000, title: '⚠️ Membership Expired',
            body: 'Your membership has expired. Contact your gym.',
            channel: _chMember);
      } else if (days <= 5) {
        await _show(id: 5001, title: '🔔 Expiring Soon',
            body: '$days day${days == 1 ? '' : 's'} left on your membership.',
            channel: _chMember);
      }
    } catch (_) {}
  }

  Future<void> notifyWelcome(String memberName, String gymName) async {
    await _show(id: 6000,
        title: '🎉 Welcome to $gymName!',
        body: 'Hi $memberName! Your membership is active. Let\'s crush some goals!',
        channel: _chMember);
  }

  Future<void> checkCompetitionAlerts(
      String gymId, String memberId, String memberName) async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().substring(0, 10);
    if (prefs.getString('comp_${memberId}_$today') == '1') return;
    await prefs.setString('comp_${memberId}_$today', '1');

    try {
      final snap = await FirebaseFirestore.instance
          .collection('gyms').doc(gymId).collection('members')
          .where('isActive', isEqualTo: true)
          .orderBy('totalPoints', descending: true).get();
      final docs  = snap.docs;
      final myIdx = docs.indexWhere((d) => d.id == memberId);
      if (myIdx < 0) return;
      final myPts = (docs[myIdx].data()['totalPoints'] as int?) ?? 0;

      if (myIdx > 0) {
        final aheadPts  = (docs[myIdx - 1].data()['totalPoints'] as int?) ?? 0;
        final aheadName = docs[myIdx - 1].data()['name'] as String? ?? 'the leader';
        final gap = aheadPts - myPts;
        if (gap > 0 && gap <= 10) {
          await _show(id: 7000, title: '⚡ So Close!',
              body: 'Just $gap more points to pass $aheadName! Go for it!',
              channel: _chMember);
        }
      }

      if (myIdx == 0) {
        final prev = prefs.getString('prev_leader_$memberId') ?? '';
        if (prev.isNotEmpty && prev != memberName) {
          await _show(id: 7001, title: '🥇 You\'re #1!',
              body: 'You\'ve taken the top spot. Keep it up!',
              channel: _chMember);
        }
        await prefs.setString('prev_leader_$memberId', memberName);
      }
    } catch (_) {}
  }

  Future<void> notifyAnnouncement(String message, String sentBy) async {
    await _show(id: 8000,
        title: '📢 Gym Announcement',
        body: message.length > 100 ? '${message.substring(0, 100)}…' : message,
        channel: _chMember);
  }

  // ── Water reminders ───────────────────────────────────────────────────────
  Future<void> scheduleWaterReminders({
    int intervalHours = 2, int startHour = 7, int endHour = 22,
  }) async {
    if (!_initialized) await init();
    await cancelWaterReminders();
    final now = DateTime.now();
    int id = 4000;
    for (int hour = startHour; hour <= endHour; hour += intervalHours) {
      var t = DateTime(now.year, now.month, now.day, hour);
      if (t.isBefore(now)) t = t.add(const Duration(days: 1));
      try {
        await _plugin.zonedSchedule(
          id: id++,
          title: '💧 Time to Hydrate!',
          body: 'Stay hydrated! Log your water intake in GymForge.',
          scheduledDate: tz.TZDateTime.from(t, tz.local),
          notificationDetails: const NotificationDetails(
            android: AndroidNotificationDetails(
              _chWater,
              'Water Reminders',
              importance: Importance.defaultImportance,
              priority: Priority.defaultPriority,
            ),
            iOS: DarwinNotificationDetails(),
          ),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.time,
        );
      } catch (_) {}
    }
  }

  Future<void> cancelWaterReminders() async {
    for (int id = 4000; id < 4020; id++) {
      await _plugin.cancel(id: id);
    }
  }

  // ── Quick test ────────────────────────────────────────────────────────────
  /// Call this to instantly verify notifications work.
  Future<void> sendTestNotification() async {
    if (!_initialized) await init();
    await _show(
      id: 9999,
      title: '✅ GymForge Notifications Working!',
      body: 'Notifications are set up correctly. You\'ll receive alerts for renewals, achievements and more.',
      channel: _chGreeting,
    );
  }

  // ── Internal ──────────────────────────────────────────────────────────────
  Future<void> _show({
    required int id, required String title,
    required String body, required String channel,
  }) async {
    if (!_initialized) await init();
    try {
      await _plugin.show(
        id: id,
        title: title,
        body: body,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            channel,
            channel == _chOwner
                ? 'Owner Alerts'
                : channel == _chWater
                    ? 'Water Reminders'
                    : channel == _chGreeting
                        ? 'Greetings'
                        : 'Member Alerts',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: const DarwinNotificationDetails(),
        ),
      );
    } catch (_) {}
  }

  Future<void> cancelAll() => _plugin.cancelAll();
}
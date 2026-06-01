class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  Future<void> init() async {}

  Future<bool> requestPermission() async => false;

  Future<void> initAndGreet(String userName, {bool isOwner = false}) async {}

  Future<void> checkRenewalAlerts(String gymId) async {}

  Future<void> notifyOwnerAchievement(String memberName, String title) async {}

  Future<void> checkRetentionAlerts(String gymId) async {}

  Future<void> checkLeaderboardChange(String gymId) async {}

  Future<void> checkMembershipExpiry(String gymId, String memberId) async {}

  Future<void> notifyWelcome(String memberName, String gymName) async {}

  Future<void> checkCompetitionAlerts(
    String gymId,
    String memberId,
    String memberName,
  ) async {}

  Future<void> notifyAnnouncement(String message, String sentBy) async {}

  Future<void> scheduleWaterReminders({
    int intervalHours = 2,
    int startHour = 7,
    int endHour = 22,
  }) async {}

  Future<void> cancelWaterReminders() async {}

  Future<void> sendTestNotification() async {}

  Future<void> cancelAll() async {}
}

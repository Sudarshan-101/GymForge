class WidgetService {
  static Future<void> init() async {}

  static Future<void> update({
    required int steps,
    required int waterMl,
    required int score,
    int streak = 0,
    List<bool> weekCheckins = const [
      false,
      false,
      false,
      false,
      false,
      false,
      false,
    ],
  }) async {}

  static Future<int> readInt(String key, {int defaultValue = 0}) async {
    return defaultValue;
  }
}

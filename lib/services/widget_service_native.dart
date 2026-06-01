import 'package:home_widget/home_widget.dart';

class WidgetService {
  static const String _appGroupId = 'group.com.gymforge.app';
  static const String _widgetName = 'GymForgeWidget';
  static const String _androidFqn = 'com.gymforge.app.GymForgeWidget';

  static Future<void> init() async {
    try {
      await HomeWidget.setAppGroupId(_appGroupId);
    } catch (_) {}
  }

  /// Save all widget data and trigger a refresh.
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
      false
    ],
  }) async {
    try {
      // weekCheckins: Mon=0 .. Sun=6
      final checkinStr = weekCheckins.map((b) => b ? '1' : '0').join(',');
      await Future.wait([
        HomeWidget.saveWidgetData<int>('steps', steps),
        HomeWidget.saveWidgetData<int>('water_ml', waterMl),
        HomeWidget.saveWidgetData<int>('score', score),
        HomeWidget.saveWidgetData<int>('streak', streak),
        HomeWidget.saveWidgetData<String>('week_checkins', checkinStr),
      ]);
      await HomeWidget.updateWidget(
        androidName: _widgetName,
        qualifiedAndroidName: _androidFqn,
        iOSName: _widgetName,
        name: _widgetName,
      );
    } catch (_) {}
  }

  static Future<int> readInt(String key, {int defaultValue = 0}) async {
    try {
      return await HomeWidget.getWidgetData<int>(
            key,
            defaultValue: defaultValue,
          ) ??
          defaultValue;
    } catch (_) {
      return defaultValue;
    }
  }
}

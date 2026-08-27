import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/reminder_settings.dart';

abstract class SettingsLocalDataSource {
  Future<ReminderSettings> getReminderSettings();
  Future<void> saveReminderSettings(ReminderSettings settings);
}

class SettingsLocalDataSourceImpl implements SettingsLocalDataSource {
  static const _enabledKey = 'reminder_enabled';
  static const _hourKey = 'reminder_hour';
  static const _minuteKey = 'reminder_minute';

  @override
  Future<ReminderSettings> getReminderSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool(_enabledKey);
    if (enabled == null) return ReminderSettings.disabled;
    return ReminderSettings(
      enabled: enabled,
      hour: prefs.getInt(_hourKey) ?? ReminderSettings.disabled.hour,
      minute: prefs.getInt(_minuteKey) ?? ReminderSettings.disabled.minute,
    );
  }

  @override
  Future<void> saveReminderSettings(ReminderSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, settings.enabled);
    await prefs.setInt(_hourKey, settings.hour);
    await prefs.setInt(_minuteKey, settings.minute);
  }
}

import '../entities/reminder_settings.dart';
import '../repositories/settings_repository.dart';

class GetReminderSettings {
  final SettingsRepository repository;
  GetReminderSettings(this.repository);

  Future<ReminderSettings> call() => repository.getReminderSettings();
}

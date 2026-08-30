import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/notifications/notification_service.dart';
import '../../domain/usecases/get_reminder_settings.dart';
import '../../domain/usecases/save_reminder_settings.dart';
import 'settings_state.dart';

class SettingsCubit extends Cubit<SettingsState> {
  final GetReminderSettings getReminderSettingsUseCase;
  final SaveReminderSettings saveReminderSettingsUseCase;
  final NotificationService notificationService;

  SettingsCubit({
    required this.getReminderSettingsUseCase,
    required this.saveReminderSettingsUseCase,
    required this.notificationService,
  }) : super(const SettingsState());

  Future<void> load() async {
    emit(state.copyWith(isLoading: true, errorMessage: null));
    try {
      final settings = await getReminderSettingsUseCase();
      emit(state.copyWith(settings: settings, isLoading: false));
    } catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: e.toString()));
    }
  }

  Future<void> setEnabled(bool enabled) async {
    if (!enabled) {
      try {
        await notificationService.cancelDailyReminder();
        final updated = state.settings.copyWith(enabled: false);
        await saveReminderSettingsUseCase(updated);
        emit(state.copyWith(settings: updated));
      } catch (e) {
        emit(state.copyWith(errorMessage: e.toString()));
      }
      return;
    }

    try {
      final granted = await notificationService.requestPermission();
      if (!granted) {
        emit(state.copyWith(feedback: SettingsFeedback.reminderPermissionDenied));
        return;
      }
      final updated = state.settings.copyWith(enabled: true);
      await notificationService.scheduleDailyReminder(hour: updated.hour, minute: updated.minute);
      await saveReminderSettingsUseCase(updated);
      emit(state.copyWith(settings: updated));
    } catch (e) {
      emit(state.copyWith(errorMessage: e.toString()));
    }
  }

  Future<void> setTime(int hour, int minute) async {
    final updated = state.settings.copyWith(hour: hour, minute: minute);
    try {
      if (updated.enabled) {
        await notificationService.scheduleDailyReminder(hour: hour, minute: minute);
      }
      await saveReminderSettingsUseCase(updated);
      emit(state.copyWith(settings: updated));
    } catch (e) {
      emit(state.copyWith(errorMessage: e.toString()));
    }
  }

  Future<void> sendTestNotification() async {
    try {
      final granted = await notificationService.requestPermission();
      if (!granted) {
        emit(state.copyWith(feedback: SettingsFeedback.testPermissionDenied));
        return;
      }
      await notificationService.showTestNotification();
      emit(state.copyWith(feedback: SettingsFeedback.testNotificationSent));
    } catch (e) {
      emit(state.copyWith(errorMessage: e.toString()));
    }
  }
}

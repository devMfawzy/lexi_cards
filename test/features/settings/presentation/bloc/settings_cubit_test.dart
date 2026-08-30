import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:lexi_cards/core/notifications/notification_service.dart';
import 'package:lexi_cards/features/settings/domain/entities/reminder_settings.dart';
import 'package:lexi_cards/features/settings/domain/usecases/get_reminder_settings.dart';
import 'package:lexi_cards/features/settings/domain/usecases/save_reminder_settings.dart';
import 'package:lexi_cards/features/settings/presentation/bloc/settings_cubit.dart';
import 'package:lexi_cards/features/settings/presentation/bloc/settings_state.dart';

class MockGetReminderSettings extends Mock implements GetReminderSettings {}

class MockSaveReminderSettings extends Mock implements SaveReminderSettings {}

class MockNotificationService extends Mock implements NotificationService {}

void main() {
  late MockGetReminderSettings getReminderSettings;
  late MockSaveReminderSettings saveReminderSettings;
  late MockNotificationService notificationService;

  setUpAll(() {
    registerFallbackValue(ReminderSettings.disabled);
  });

  setUp(() {
    getReminderSettings = MockGetReminderSettings();
    saveReminderSettings = MockSaveReminderSettings();
    notificationService = MockNotificationService();
    when(() => saveReminderSettings(any())).thenAnswer((_) async {});
  });

  SettingsCubit buildCubit({ReminderSettings initial = ReminderSettings.disabled}) {
    when(() => getReminderSettings()).thenAnswer((_) async => initial);
    return SettingsCubit(
      getReminderSettingsUseCase: getReminderSettings,
      saveReminderSettingsUseCase: saveReminderSettings,
      notificationService: notificationService,
    );
  }

  group('setEnabled(true)', () {
    blocTest<SettingsCubit, SettingsState>(
      'requests permission and schedules the reminder when granted',
      build: () {
        when(() => notificationService.requestPermission()).thenAnswer((_) async => true);
        when(() => notificationService.scheduleDailyReminder(
              hour: any(named: 'hour'),
              minute: any(named: 'minute'),
            )).thenAnswer((_) async {});
        return buildCubit();
      },
      act: (cubit) async {
        await cubit.load();
        await cubit.setEnabled(true);
      },
      verify: (cubit) {
        expect(cubit.state.settings.enabled, isTrue);
        expect(cubit.state.errorMessage, isNull);
        verify(() => notificationService.scheduleDailyReminder(hour: 9, minute: 0)).called(1);
        verify(() => saveReminderSettings(const ReminderSettings(enabled: true, hour: 9, minute: 0)))
            .called(1);
      },
    );

    blocTest<SettingsCubit, SettingsState>(
      'stays disabled and surfaces an error when permission is denied',
      build: () {
        when(() => notificationService.requestPermission()).thenAnswer((_) async => false);
        return buildCubit();
      },
      act: (cubit) async {
        await cubit.load();
        await cubit.setEnabled(true);
      },
      verify: (cubit) {
        expect(cubit.state.settings.enabled, isFalse);
        expect(cubit.state.feedback, SettingsFeedback.reminderPermissionDenied);
        verifyNever(() => notificationService.scheduleDailyReminder(
              hour: any(named: 'hour'),
              minute: any(named: 'minute'),
            ));
        verifyNever(() => saveReminderSettings(any()));
      },
    );
  });

  group('setEnabled(false)', () {
    blocTest<SettingsCubit, SettingsState>(
      'cancels the scheduled reminder and saves as disabled',
      build: () {
        when(() => notificationService.cancelDailyReminder()).thenAnswer((_) async {});
        return buildCubit(initial: const ReminderSettings(enabled: true, hour: 8, minute: 0));
      },
      act: (cubit) async {
        await cubit.load();
        await cubit.setEnabled(false);
      },
      verify: (cubit) {
        expect(cubit.state.settings.enabled, isFalse);
        verify(() => notificationService.cancelDailyReminder()).called(1);
        verify(() => saveReminderSettings(const ReminderSettings(enabled: false, hour: 8, minute: 0)))
            .called(1);
      },
    );
  });

  group('setTime', () {
    blocTest<SettingsCubit, SettingsState>(
      'reschedules when the reminder is already enabled',
      build: () {
        when(() => notificationService.scheduleDailyReminder(
              hour: any(named: 'hour'),
              minute: any(named: 'minute'),
            )).thenAnswer((_) async {});
        return buildCubit(initial: const ReminderSettings(enabled: true, hour: 9, minute: 0));
      },
      act: (cubit) async {
        await cubit.load();
        await cubit.setTime(21, 30);
      },
      verify: (cubit) {
        expect(cubit.state.settings.hour, 21);
        expect(cubit.state.settings.minute, 30);
        verify(() => notificationService.scheduleDailyReminder(hour: 21, minute: 30)).called(1);
      },
    );

    blocTest<SettingsCubit, SettingsState>(
      'just saves the new time without scheduling when disabled',
      build: () => buildCubit(),
      act: (cubit) async {
        await cubit.load();
        await cubit.setTime(21, 30);
      },
      verify: (cubit) {
        expect(cubit.state.settings.hour, 21);
        expect(cubit.state.settings.minute, 30);
        verifyNever(() => notificationService.scheduleDailyReminder(
              hour: any(named: 'hour'),
              minute: any(named: 'minute'),
            ));
      },
    );
  });

  group('sendTestNotification', () {
    blocTest<SettingsCubit, SettingsState>(
      'surfaces success feedback when permission is granted',
      build: () {
        when(() => notificationService.requestPermission()).thenAnswer((_) async => true);
        when(() => notificationService.showTestNotification()).thenAnswer((_) async {});
        return buildCubit();
      },
      act: (cubit) async {
        await cubit.load();
        await cubit.sendTestNotification();
      },
      verify: (cubit) {
        expect(cubit.state.feedback, SettingsFeedback.testNotificationSent);
        verify(() => notificationService.showTestNotification()).called(1);
      },
    );

    blocTest<SettingsCubit, SettingsState>(
      'surfaces denial feedback and never sends when permission is denied',
      build: () {
        when(() => notificationService.requestPermission()).thenAnswer((_) async => false);
        return buildCubit();
      },
      act: (cubit) async {
        await cubit.load();
        await cubit.sendTestNotification();
      },
      verify: (cubit) {
        expect(cubit.state.feedback, SettingsFeedback.testPermissionDenied);
        verifyNever(() => notificationService.showTestNotification());
      },
    );
  });
}

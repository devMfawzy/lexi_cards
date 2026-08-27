import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'package:lexi_cards/core/notifications/notification_service.dart';

class MockFlutterLocalNotificationsPlugin extends Mock
    implements FlutterLocalNotificationsPlugin {}

void main() {
  late MockFlutterLocalNotificationsPlugin plugin;
  late NotificationService service;

  setUpAll(() {
    tz.initializeTimeZones();
    registerFallbackValue(const NotificationDetails());
    registerFallbackValue(AndroidScheduleMode.inexactAllowWhileIdle);
    registerFallbackValue(DateTimeComponents.time);
    registerFallbackValue(tz.TZDateTime.now(tz.local));
  });

  setUp(() {
    plugin = MockFlutterLocalNotificationsPlugin();
    service = NotificationService(plugin: plugin);
  });

  group('scheduleDailyReminder', () {
    test('schedules a repeating notification matched to the requested time-of-day', () async {
      when(
        () => plugin.zonedSchedule(
          id: any(named: 'id'),
          title: any(named: 'title'),
          body: any(named: 'body'),
          scheduledDate: any(named: 'scheduledDate'),
          notificationDetails: any(named: 'notificationDetails'),
          androidScheduleMode: any(named: 'androidScheduleMode'),
          matchDateTimeComponents: any(named: 'matchDateTimeComponents'),
          payload: any(named: 'payload'),
        ),
      ).thenAnswer((_) async {});

      await service.scheduleDailyReminder(hour: 9, minute: 30);

      final captured = verify(
        () => plugin.zonedSchedule(
          id: NotificationService.dailyReminderId,
          title: any(named: 'title'),
          body: any(named: 'body'),
          scheduledDate: captureAny(named: 'scheduledDate'),
          notificationDetails: any(named: 'notificationDetails'),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.time,
          payload: any(named: 'payload'),
        ),
      ).captured;

      final scheduledDate = captured.single as tz.TZDateTime;
      expect(scheduledDate.hour, 9);
      expect(scheduledDate.minute, 30);
      expect(scheduledDate.isBefore(tz.TZDateTime.now(tz.local)), isFalse);
    });
  });

  group('cancelDailyReminder', () {
    test('cancels the daily reminder id', () async {
      when(() => plugin.cancel(id: any(named: 'id'))).thenAnswer((_) async {});

      await service.cancelDailyReminder();

      verify(() => plugin.cancel(id: NotificationService.dailyReminderId)).called(1);
    });
  });

  group('showTestNotification', () {
    test('schedules a one-off notification a few seconds out, not repeating', () async {
      when(
        () => plugin.zonedSchedule(
          id: any(named: 'id'),
          title: any(named: 'title'),
          body: any(named: 'body'),
          scheduledDate: any(named: 'scheduledDate'),
          notificationDetails: any(named: 'notificationDetails'),
          androidScheduleMode: any(named: 'androidScheduleMode'),
          matchDateTimeComponents: any(named: 'matchDateTimeComponents'),
          payload: any(named: 'payload'),
        ),
      ).thenAnswer((_) async {});

      await service.showTestNotification();

      final captured = verify(
        () => plugin.zonedSchedule(
          id: NotificationService.testNotificationId,
          title: any(named: 'title'),
          body: any(named: 'body'),
          scheduledDate: captureAny(named: 'scheduledDate'),
          notificationDetails: any(named: 'notificationDetails'),
          androidScheduleMode: any(named: 'androidScheduleMode'),
          matchDateTimeComponents: null,
          payload: any(named: 'payload'),
        ),
      ).captured;

      final scheduledDate = captured.single as tz.TZDateTime;
      expect(scheduledDate.isAfter(tz.TZDateTime.now(tz.local)), isTrue);
    });
  });
}

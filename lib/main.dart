import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';
import 'core/di/injection_container.dart';
import 'core/notifications/notification_service.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/settings/domain/usecases/get_reminder_settings.dart';
import 'hive_registrar.g.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  Hive.registerAdapters();

  await initDependencies();

  final notificationService = getIt<NotificationService>();
  await notificationService.init();
  final reminderSettings = await getIt<GetReminderSettings>()();
  if (reminderSettings.enabled) {
    // Idempotent — re-issuing the same schedule on every launch is cheap and
    // defensive against the OS having dropped it (e.g. app reinstall).
    await notificationService.scheduleDailyReminder(
      hour: reminderSettings.hour,
      minute: reminderSettings.minute,
    );
  }

  runApp(const LexiCardsApp());
}

class LexiCardsApp extends StatelessWidget {
  const LexiCardsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Lexi Cards',
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: ThemeMode.system,
      localizationsDelegates: FlutterQuillLocalizations.localizationsDelegates,
      supportedLocales: FlutterQuillLocalizations.supportedLocales,
      routerConfig: appRouter,
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';
import 'core/di/injection_container.dart';
import 'core/notifications/notification_service.dart';
import 'core/router/app_router.dart';
import 'core/sync/google_drive_storage.dart';
import 'core/theme/app_theme.dart';
import 'features/settings/domain/usecases/get_reminder_settings.dart';
import 'features/settings/presentation/bloc/locale_cubit.dart';
import 'hive_registrar.g.dart';
import 'l10n/app_localizations.dart';

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

  // Local configuration only — no network, and deliberately no sign-in. The
  // account is restored, and any sync run, from the UI once the first frame is
  // up; awaiting either here would hang a cold start on a bad connection.
  await getIt<GoogleDriveStorage>().init();

  await getIt<LocaleCubit>().load();

  runApp(const LexiCardsApp());
}

class LexiCardsApp extends StatelessWidget {
  const LexiCardsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: getIt<LocaleCubit>(),
      child: BlocBuilder<LocaleCubit, Locale?>(
        builder: (context, locale) {
          return MaterialApp.router(
            onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
            debugShowCheckedModeBanner: false,
            theme: lightTheme,
            darkTheme: darkTheme,
            themeMode: ThemeMode.system,
            locale: locale,
            localizationsDelegates: [
              ...AppLocalizations.localizationsDelegates,
              ...FlutterQuillLocalizations.localizationsDelegates,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            routerConfig: appRouter,
          );
        },
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'core/di/injection_container.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/cards/data/models/deck_model.dart';
import 'features/cards/data/models/flashcard_model.dart';
import 'features/cards/data/models/review_log_model.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  Hive.registerAdapter(DeckModelAdapter());
  Hive.registerAdapter(FlashcardModelAdapter());
  Hive.registerAdapter(ReviewLogModelAdapter());

  await initDependencies();

  runApp(const LexiCardsApp());
}

class LexiCardsApp extends StatelessWidget {
  const LexiCardsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Lexi Cards',
      theme: appTheme,
      routerConfig: appRouter,
    );
  }
}

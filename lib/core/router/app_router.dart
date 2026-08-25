import 'package:go_router/go_router.dart';
import '../../features/cards/presentation/pages/cards_page.dart';
import '../../features/cards/presentation/pages/decks_page.dart';
import '../../features/review/presentation/pages/review_page.dart';
import '../../features/stats/presentation/pages/stats_page.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      name: 'decks',
      builder: (context, state) => const DecksPage(),
    ),
    GoRoute(
      path: '/decks/:deckId',
      name: 'cards',
      builder: (context, state) =>
          CardsPage(deckId: state.pathParameters['deckId']!),
    ),
    GoRoute(
      path: '/decks/:deckId/review',
      name: 'review',
      builder: (context, state) =>
          ReviewPage(deckId: state.pathParameters['deckId']!),
    ),
    GoRoute(
      path: '/stats',
      name: 'stats',
      builder: (context, state) => const StatsPage(),
    ),
  ],
);

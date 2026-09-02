import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/widgets/ltr_text.dart';
import '../../../../l10n/app_localizations.dart';
import '../bloc/review_cubit.dart';
import '../bloc/review_state.dart';
import '../widgets/flashcard_flip.dart';
import '../widgets/rating_buttons.dart';

class ReviewPage extends StatelessWidget {
  /// The deck to study, or null to study due cards across every deck.
  final String? deckId;

  const ReviewPage({super.key, this.deckId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ReviewCubit(
        getDueCards: getIt(),
        submitReviewUseCase: getIt(),
        getCards: getIt(),
        getAllCardsUseCase: getIt(),
      )..loadDueCards(deckId: deckId),
      child: _ReviewView(deckId: deckId),
    );
  }
}

class _ReviewView extends StatelessWidget {
  final String? deckId;

  const _ReviewView({required this.deckId});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(deckId == null ? l10n.studyAllTitle : l10n.study),
        actions: [
          if (kDebugMode)
            IconButton(
              icon: Transform.flip(
                flipX: Directionality.of(context) == TextDirection.rtl,
                child: const Icon(Icons.fast_forward),
              ),
              tooltip: l10n.devSkipAheadTooltip,
              onPressed: () => context.read<ReviewCubit>().debugSkipAhead(deckId: deckId),
            ),
        ],
      ),
      body: BlocConsumer<ReviewCubit, ReviewState>(
        listener: (context, state) {
          if (state.errorMessage != null) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.errorMessage!)));
          }
        },
        builder: (context, state) {
          if (state.isLoading && state.queue.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.isComplete) {
            final colorScheme = Theme.of(context).colorScheme;
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.check, size: 48, color: colorScheme.onPrimaryContainer),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    l10n.allCaughtUp,
                    style: Theme.of(
                      context,
                    ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.reviewedCount(state.reviewedCount),
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            );
          }

          final card = state.currentCard!;
          final total = state.reviewedCount + state.queue.length;
          final progress = total == 0 ? 0.0 : state.reviewedCount / total;

          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(value: progress, minHeight: 6),
                ),
                const SizedBox(height: 8),
                LtrText(
                  '${state.reviewedCount} / $total',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                Expanded(
                  child: Center(
                    child: FlashcardFlip(
                      key: ValueKey(card.id),
                      front: card.front,
                      back: card.back,
                      showAnswer: state.showAnswer,
                      onTap: state.showAnswer
                          ? null
                          : () => context.read<ReviewCubit>().revealAnswer(),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                if (!state.showAnswer)
                  ElevatedButton(
                    onPressed: () => context.read<ReviewCubit>().revealAnswer(),
                    child: Text(l10n.showAnswer),
                  )
                else
                  RatingButtons(
                    previews: state.previews,
                    onRate: (rating) => context.read<ReviewCubit>().submitRating(rating),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

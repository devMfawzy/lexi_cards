import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection_container.dart';
import '../bloc/review_cubit.dart';
import '../bloc/review_state.dart';
import '../widgets/rating_buttons.dart';

class ReviewPage extends StatelessWidget {
  final String deckId;

  const ReviewPage({super.key, required this.deckId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ReviewCubit(
        getDueCards: getIt(),
        submitReviewUseCase: getIt(),
        getCards: getIt(),
      )..loadDueCards(deckId),
      child: _ReviewView(deckId: deckId),
    );
  }
}

class _ReviewView extends StatelessWidget {
  final String deckId;

  const _ReviewView({required this.deckId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Study'),
        actions: [
          if (kDebugMode)
            IconButton(
              icon: const Icon(Icons.fast_forward),
              tooltip: 'Dev: skip ahead 15 min',
              onPressed: () => context.read<ReviewCubit>().debugSkipAhead(deckId),
            ),
        ],
      ),
      body: BlocConsumer<ReviewCubit, ReviewState>(
        listener: (context, state) {
          if (state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.errorMessage!)),
            );
          }
        },
        builder: (context, state) {
          if (state.isLoading && state.queue.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.isComplete) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle_outline, size: 64),
                  const SizedBox(height: 16),
                  Text('No more cards due. Reviewed ${state.reviewedCount}.'),
                ],
              ),
            );
          }

          final card = state.currentCard!;
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          card.front,
                          style: Theme.of(context).textTheme.headlineSmall,
                          textAlign: TextAlign.center,
                        ),
                        if (state.showAnswer) ...[
                          const Divider(height: 48),
                          Text(
                            card.back,
                            style: Theme.of(context).textTheme.headlineSmall,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                if (!state.showAnswer)
                  ElevatedButton(
                    onPressed: () => context.read<ReviewCubit>().revealAnswer(),
                    child: const Text('Show Answer'),
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

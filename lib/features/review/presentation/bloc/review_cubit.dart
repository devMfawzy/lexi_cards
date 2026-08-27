import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../cards/domain/entities/flashcard.dart';
import '../../../cards/domain/usecases/get_cards.dart';
import '../../domain/entities/rating.dart';
import '../../domain/scheduler/sm2_scheduler.dart';
import '../../domain/usecases/get_due_cards.dart';
import '../../domain/usecases/submit_review.dart';
import 'review_state.dart';

class ReviewCubit extends Cubit<ReviewState> {
  final GetDueCards getDueCards;
  final SubmitReview submitReviewUseCase;
  final GetCards getCards;

  ReviewCubit({
    required this.getDueCards,
    required this.submitReviewUseCase,
    required this.getCards,
  }) : super(const ReviewState());

  Future<void> loadDueCards(String deckId) async {
    emit(state.copyWith(isLoading: true, errorMessage: null));
    try {
      final cards = await getDueCards(deckId);
      emit(state.copyWith(
        queue: cards,
        pendingRequeue: const [],
        isLoading: false,
        showAnswer: false,
      ));
      _computePreviews();
    } catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: e.toString()));
    }
  }

  void revealAnswer() {
    emit(state.copyWith(showAnswer: true));
  }

  /// Rates the current card and advances the queue. A card that lands back
  /// in learning/relearning (short SM-2 steps) is held in [ReviewState.pendingRequeue]
  /// rather than dropped — any pending card whose due date has arrived by
  /// [now] is spliced onto the end of the queue, so it can resurface later
  /// in this same session instead of only on the next full reload.
  Future<void> submitRating(Rating rating, {DateTime? now}) async {
    final card = state.currentCard;
    if (card == null) return;
    try {
      final updated = await submitReviewUseCase(card.id, rating);
      final effectiveNow = now ?? DateTime.now();

      final remaining = state.queue.skip(1).toList();
      final pending = [
        ...state.pendingRequeue,
        if (updated.state == CardState.learning || updated.state == CardState.relearning)
          updated,
      ];
      final due = pending.where((c) => !c.dueDate.isAfter(effectiveNow)).toList()
        ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
      final stillPending = pending.where((c) => c.dueDate.isAfter(effectiveNow)).toList();

      emit(state.copyWith(
        queue: [...remaining, ...due],
        pendingRequeue: stillPending,
        showAnswer: false,
        reviewedCount: state.reviewedCount + 1,
      ));
      _computePreviews();
    } catch (e) {
      emit(state.copyWith(errorMessage: e.toString()));
    }
  }

  /// Debug-only aid: re-queries due cards as if [by] had already elapsed, so a
  /// pending learning/relearning step doesn't have to be waited out for real
  /// during a demo. Does not persist anything - the underlying due dates are
  /// untouched, this only affects what's shown in this session's queue.
  Future<void> debugSkipAhead(String deckId, {Duration by = const Duration(minutes: 15)}) async {
    final cards = await getCards(deckId);
    final simulatedNow = DateTime.now().add(by);

    final due = cards
        .where((c) => c.state != CardState.newCard && !c.dueDate.isAfter(simulatedNow))
        .toList()
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
    final newCards = cards.where((c) => c.state == CardState.newCard).toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    emit(state.copyWith(
      queue: [...due, ...newCards],
      pendingRequeue: const [],
      showAnswer: false,
    ));
    _computePreviews();
  }

  void _computePreviews() {
    final card = state.currentCard;
    if (card == null) {
      emit(state.copyWith(previews: const {}));
      return;
    }
    final now = DateTime.now();
    final previews = {
      for (final rating in Rating.values)
        rating: computeNextSchedule(card, rating, now: now).newDueDate.difference(now),
    };
    emit(state.copyWith(previews: previews));
  }
}

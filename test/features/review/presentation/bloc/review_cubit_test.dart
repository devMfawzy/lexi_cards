import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:lexi_cards/features/cards/domain/entities/flashcard.dart';
import 'package:lexi_cards/features/cards/domain/usecases/get_cards.dart';
import 'package:lexi_cards/features/review/domain/entities/rating.dart';
import 'package:lexi_cards/features/review/domain/usecases/get_due_cards.dart';
import 'package:lexi_cards/features/review/domain/usecases/submit_review.dart';
import 'package:lexi_cards/features/review/presentation/bloc/review_cubit.dart';
import 'package:lexi_cards/features/review/presentation/bloc/review_state.dart';

class MockGetDueCards extends Mock implements GetDueCards {}

class MockSubmitReview extends Mock implements SubmitReview {}

class MockGetCards extends Mock implements GetCards {}

void main() {
  const deckId = 'deck-1';
  final createdAt = DateTime(2026, 1, 1);

  late MockGetDueCards getDueCards;
  late MockSubmitReview submitReview;
  late MockGetCards getCards;

  Flashcard cardWith({
    required String id,
    CardState state = CardState.newCard,
    DateTime? dueDate,
  }) {
    return Flashcard(
      id: id,
      deckId: deckId,
      front: 'front $id',
      back: 'back $id',
      createdAt: createdAt,
      state: state,
      dueDate: dueDate ?? createdAt,
      intervalDays: 0,
      easeFactor: 2.5,
      learningStepIndex: 0,
      lapses: 0,
      reviewCount: 0,
    );
  }

  setUpAll(() {
    registerFallbackValue(Rating.good);
  });

  setUp(() {
    getDueCards = MockGetDueCards();
    submitReview = MockSubmitReview();
    getCards = MockGetCards();
  });

  ReviewCubit buildCubit() => ReviewCubit(
        getDueCards: getDueCards,
        submitReviewUseCase: submitReview,
        getCards: getCards,
      );

  group('submitRating', () {
    blocTest<ReviewCubit, ReviewState>(
      'holds a card that lands back in relearning in pendingRequeue instead of dropping it',
      build: () {
        final cardA = cardWith(id: 'a');
        final cardB = cardWith(id: 'b');
        when(() => getDueCards(deckId)).thenAnswer((_) async => [cardA, cardB]);
        when(() => submitReview('a', any())).thenAnswer(
          (_) async => cardA.copyWith(
            state: CardState.relearning,
            dueDate: createdAt.add(const Duration(minutes: 10)),
          ),
        );
        return buildCubit();
      },
      act: (cubit) async {
        await cubit.loadDueCards(deckId);
        await cubit.submitRating(Rating.again, now: createdAt);
      },
      verify: (cubit) {
        expect(cubit.state.queue.map((c) => c.id), ['b']);
        expect(cubit.state.pendingRequeue.map((c) => c.id), ['a']);
      },
    );

    blocTest<ReviewCubit, ReviewState>(
      'promotes a pending card back into the queue once its due date arrives',
      build: () {
        final cardA = cardWith(id: 'a');
        final cardB = cardWith(id: 'b');
        when(() => getDueCards(deckId)).thenAnswer((_) async => [cardA, cardB]);
        when(() => submitReview('a', any())).thenAnswer(
          (_) async => cardA.copyWith(
            state: CardState.relearning,
            dueDate: createdAt.add(const Duration(minutes: 10)),
          ),
        );
        when(() => submitReview('b', any())).thenAnswer(
          (_) async => cardB.copyWith(
            state: CardState.review,
            dueDate: createdAt.add(const Duration(days: 4)),
          ),
        );
        return buildCubit();
      },
      act: (cubit) async {
        await cubit.loadDueCards(deckId);
        // Rate 'a' — not yet due again (10 min away), so it's held pending.
        await cubit.submitRating(Rating.again, now: createdAt);
        // Rate 'b' 15 minutes later (in-session elapsed time) — 'a' is now due.
        await cubit.submitRating(
          Rating.good,
          now: createdAt.add(const Duration(minutes: 15)),
        );
      },
      verify: (cubit) {
        expect(cubit.state.queue.map((c) => c.id), ['a']);
        expect(cubit.state.pendingRequeue, isEmpty);
      },
    );

    blocTest<ReviewCubit, ReviewState>(
      'does not hold back a card that graduates to full review state',
      build: () {
        final cardA = cardWith(id: 'a');
        when(() => getDueCards(deckId)).thenAnswer((_) async => [cardA]);
        when(() => submitReview('a', any())).thenAnswer(
          (_) async => cardA.copyWith(
            state: CardState.review,
            dueDate: createdAt.add(const Duration(days: 4)),
          ),
        );
        return buildCubit();
      },
      act: (cubit) async {
        await cubit.loadDueCards(deckId);
        await cubit.submitRating(Rating.easy, now: createdAt);
      },
      verify: (cubit) {
        expect(cubit.state.queue, isEmpty);
        expect(cubit.state.pendingRequeue, isEmpty);
        expect(cubit.state.isComplete, isTrue);
      },
    );

    blocTest<ReviewCubit, ReviewState>(
      'leaves an already-pending card in place if it is still not due',
      build: () {
        final cardA = cardWith(id: 'a');
        final cardB = cardWith(id: 'b');
        final cardC = cardWith(id: 'c');
        when(() => getDueCards(deckId)).thenAnswer((_) async => [cardA, cardB, cardC]);
        when(() => submitReview('a', any())).thenAnswer(
          (_) async => cardA.copyWith(
            state: CardState.relearning,
            dueDate: createdAt.add(const Duration(minutes: 10)),
          ),
        );
        when(() => submitReview('b', any())).thenAnswer(
          (_) async => cardB.copyWith(
            state: CardState.relearning,
            dueDate: createdAt.add(const Duration(minutes: 5)),
          ),
        );
        return buildCubit();
      },
      act: (cubit) async {
        await cubit.loadDueCards(deckId);
        await cubit.submitRating(Rating.again, now: createdAt); // holds 'a' (10m away)
        // Only 2 minutes have passed — 'a' still isn't due, 'b' just landed pending too.
        await cubit.submitRating(
          Rating.again,
          now: createdAt.add(const Duration(minutes: 2)),
        );
      },
      verify: (cubit) {
        expect(cubit.state.queue.map((c) => c.id), ['c']);
        expect(cubit.state.pendingRequeue.map((c) => c.id), unorderedEquals(['a', 'b']));
      },
    );
  });
}

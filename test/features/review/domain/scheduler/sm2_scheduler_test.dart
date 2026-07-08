import 'package:flutter_test/flutter_test.dart';
import 'package:lexi_cards/features/cards/domain/entities/flashcard.dart';
import 'package:lexi_cards/features/review/domain/entities/rating.dart';
import 'package:lexi_cards/features/review/domain/scheduler/sm2_scheduler.dart';

void main() {
  final now = DateTime(2026, 1, 1, 12, 0, 0);

  Flashcard cardWith({
    CardState state = CardState.newCard,
    int intervalDays = 0,
    double easeFactor = 2.5,
    int learningStepIndex = 0,
    int lapses = 0,
    int reviewCount = 0,
  }) {
    return Flashcard(
      id: 'c1',
      deckId: 'd1',
      front: 'front',
      back: 'back',
      createdAt: now,
      state: state,
      dueDate: now,
      intervalDays: intervalDays,
      easeFactor: easeFactor,
      learningStepIndex: learningStepIndex,
      lapses: lapses,
      reviewCount: reviewCount,
    );
  }

  group('new card', () {
    test('Good moves to learning, step 0 -> 1, due +10m', () {
      final result = computeNextSchedule(cardWith(), Rating.good, now: now);
      expect(result.newState, CardState.learning);
      expect(result.newLearningStepIndex, 1);
      expect(result.newDueDate, now.add(const Duration(minutes: 10)));
    });

    test('Again stays at step 0, due +1m', () {
      final result = computeNextSchedule(cardWith(), Rating.again, now: now);
      expect(result.newState, CardState.learning);
      expect(result.newLearningStepIndex, 0);
      expect(result.newDueDate, now.add(const Duration(minutes: 1)));
    });

    test('Hard repeats step 0, same as Again for a brand new card', () {
      final result = computeNextSchedule(cardWith(), Rating.hard, now: now);
      expect(result.newState, CardState.learning);
      expect(result.newLearningStepIndex, 0);
      expect(result.newDueDate, now.add(const Duration(minutes: 1)));
    });

    test('Easy graduates immediately to review, interval 4 days, ease unchanged', () {
      final result = computeNextSchedule(cardWith(), Rating.easy, now: now);
      expect(result.newState, CardState.review);
      expect(result.newIntervalDays, 4);
      expect(result.newEaseFactor, 2.5);
      expect(result.newDueDate, now.add(const Duration(days: 4)));
    });
  });

  group('learning phase', () {
    test('Good on last step graduates to review with graduating interval', () {
      final card = cardWith(state: CardState.learning, learningStepIndex: 1);
      final result = computeNextSchedule(card, Rating.good, now: now);
      expect(result.newState, CardState.review);
      expect(result.newIntervalDays, 1);
      expect(result.newEaseFactor, 2.5);
      expect(result.newDueDate, now.add(const Duration(days: 1)));
    });

    test('Again on last step resets to step 0', () {
      final card = cardWith(state: CardState.learning, learningStepIndex: 1);
      final result = computeNextSchedule(card, Rating.again, now: now);
      expect(result.newState, CardState.learning);
      expect(result.newLearningStepIndex, 0);
      expect(result.newDueDate, now.add(const Duration(minutes: 1)));
    });

    test('Hard on last step repeats current step, does not reset', () {
      final card = cardWith(state: CardState.learning, learningStepIndex: 1);
      final result = computeNextSchedule(card, Rating.hard, now: now);
      expect(result.newState, CardState.learning);
      expect(result.newLearningStepIndex, 1);
      expect(result.newDueDate, now.add(const Duration(minutes: 10)));
    });
  });

  group('review phase', () {
    test('Good: interval = round(interval * ease), ease unchanged', () {
      final card = cardWith(state: CardState.review, intervalDays: 6, easeFactor: 2.5);
      final result = computeNextSchedule(card, Rating.good, now: now);
      expect(result.newState, CardState.review);
      expect(result.newEaseFactor, 2.5);
      expect(result.newIntervalDays, 15);
      expect(result.newDueDate, now.add(const Duration(days: 15)));
    });

    test('Hard: ease -0.15, interval = max(interval+1, round(interval*1.2))', () {
      final card = cardWith(state: CardState.review, intervalDays: 6, easeFactor: 2.5);
      final result = computeNextSchedule(card, Rating.hard, now: now);
      expect(result.newEaseFactor, closeTo(2.35, 1e-9));
      expect(result.newIntervalDays, 7);
    });

    test('Easy: ease +0.15, interval = round(interval * newEase * 1.3)', () {
      final card = cardWith(state: CardState.review, intervalDays: 6, easeFactor: 2.5);
      final result = computeNextSchedule(card, Rating.easy, now: now);
      expect(result.newEaseFactor, closeTo(2.65, 1e-9));
      expect(result.newIntervalDays, 21);
    });

    test('Again: lapses +1, ease -0.20, demotes to relearning', () {
      final card = cardWith(
        state: CardState.review,
        intervalDays: 6,
        easeFactor: 2.5,
        lapses: 2,
      );
      final result = computeNextSchedule(card, Rating.again, now: now);
      expect(result.newState, CardState.relearning);
      expect(result.newLapses, 3);
      expect(result.newEaseFactor, closeTo(2.3, 1e-9));
      expect(result.newLearningStepIndex, 0);
      expect(result.newDueDate, now.add(const Duration(minutes: 10)));
    });

    test('ease floor at 1.3 is applied, not allowed to go lower', () {
      final card = cardWith(state: CardState.review, intervalDays: 6, easeFactor: 1.35);
      final result = computeNextSchedule(card, Rating.again, now: now);
      expect(result.newEaseFactor, closeTo(1.3, 1e-9));
    });

    test('interval is capped at maxIntervalDays (36500)', () {
      final card = cardWith(state: CardState.review, intervalDays: 30000, easeFactor: 2.5);
      final result = computeNextSchedule(card, Rating.easy, now: now);
      expect(result.newIntervalDays, 36500);
    });
  });

  group('relearning phase', () {
    test('Good graduates back to review at the minimum interval', () {
      final card = cardWith(state: CardState.relearning, learningStepIndex: 0, intervalDays: 6);
      final result = computeNextSchedule(card, Rating.good, now: now);
      expect(result.newState, CardState.review);
      expect(result.newIntervalDays, 1);
      expect(result.newDueDate, now.add(const Duration(days: 1)));
    });

    test('Again stays in relearning without double-counting lapses/ease', () {
      final card = cardWith(
        state: CardState.relearning,
        learningStepIndex: 0,
        easeFactor: 2.3,
        lapses: 1,
      );
      final result = computeNextSchedule(card, Rating.again, now: now);
      expect(result.newState, CardState.relearning);
      expect(result.newLearningStepIndex, 0);
      expect(result.newLapses, 1);
      expect(result.newEaseFactor, closeTo(2.3, 1e-9));
      expect(result.newDueDate, now.add(const Duration(minutes: 10)));
    });
  });

  test('determinism: identical inputs and fixed now produce identical results', () {
    final card = cardWith(state: CardState.review, intervalDays: 6, easeFactor: 2.5);
    final r1 = computeNextSchedule(card, Rating.good, now: now);
    final r2 = computeNextSchedule(card, Rating.good, now: now);
    expect(r1, r2);
  });

  test('compounding: three successive Good reviews grow interval multiplicatively', () {
    var card = cardWith(state: CardState.review, intervalDays: 6, easeFactor: 2.5);
    var result = computeNextSchedule(card, Rating.good, now: now);
    expect(result.newIntervalDays, 15);

    card = card.copyWith(
      intervalDays: result.newIntervalDays,
      easeFactor: result.newEaseFactor,
    );
    result = computeNextSchedule(card, Rating.good, now: now);
    expect(result.newIntervalDays, 38); // round(15 * 2.5) = 37.5 -> 38

    card = card.copyWith(
      intervalDays: result.newIntervalDays,
      easeFactor: result.newEaseFactor,
    );
    result = computeNextSchedule(card, Rating.good, now: now);
    expect(result.newIntervalDays, 95); // round(38 * 2.5) = 95
  });
}

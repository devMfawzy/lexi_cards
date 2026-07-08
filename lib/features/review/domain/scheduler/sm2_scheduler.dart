import 'dart:math';
import '../../../cards/domain/entities/flashcard.dart';
import '../entities/rating.dart';
import 'scheduling_result.dart';
import 'sm2_config.dart';

SchedulingResult computeNextSchedule(
  Flashcard card,
  Rating rating, {
  DateTime? now,
  Sm2Config config = const Sm2Config(),
}) {
  final effectiveNow = now ?? DateTime.now();

  if (card.state == CardState.review) {
    return _reviewPhase(card, rating, effectiveNow, config);
  }
  return _learningPhase(card, rating, effectiveNow, config);
}

SchedulingResult _learningPhase(
  Flashcard card,
  Rating rating,
  DateTime now,
  Sm2Config config,
) {
  final isRelearning = card.state == CardState.relearning;
  final steps = isRelearning ? config.relearningSteps : config.learningSteps;
  final activeState = isRelearning ? CardState.relearning : CardState.learning;

  switch (rating) {
    case Rating.again:
      return SchedulingResult(
        newState: activeState,
        newDueDate: now.add(steps[0]),
        newIntervalDays: card.intervalDays,
        newEaseFactor: card.easeFactor,
        newLearningStepIndex: 0,
        newLapses: card.lapses,
        newReviewCount: card.reviewCount + 1,
      );

    case Rating.hard:
      return SchedulingResult(
        newState: activeState,
        newDueDate: now.add(steps[card.learningStepIndex]),
        newIntervalDays: card.intervalDays,
        newEaseFactor: card.easeFactor,
        newLearningStepIndex: card.learningStepIndex,
        newLapses: card.lapses,
        newReviewCount: card.reviewCount + 1,
      );

    case Rating.good:
      final nextIndex = card.learningStepIndex + 1;
      if (nextIndex >= steps.length) {
        final gradInterval =
            isRelearning ? config.minimumIntervalDays : config.graduatingIntervalDays;
        return SchedulingResult(
          newState: CardState.review,
          newDueDate: now.add(Duration(days: gradInterval)),
          newIntervalDays: gradInterval,
          newEaseFactor: card.easeFactor,
          newLearningStepIndex: 0,
          newLapses: card.lapses,
          newReviewCount: card.reviewCount + 1,
        );
      }
      return SchedulingResult(
        newState: activeState,
        newDueDate: now.add(steps[nextIndex]),
        newIntervalDays: card.intervalDays,
        newEaseFactor: card.easeFactor,
        newLearningStepIndex: nextIndex,
        newLapses: card.lapses,
        newReviewCount: card.reviewCount + 1,
      );

    case Rating.easy:
      return SchedulingResult(
        newState: CardState.review,
        newDueDate: now.add(Duration(days: config.easyIntervalDays)),
        newIntervalDays: config.easyIntervalDays,
        newEaseFactor: card.easeFactor,
        newLearningStepIndex: 0,
        newLapses: card.lapses,
        newReviewCount: card.reviewCount + 1,
      );
  }
}

SchedulingResult _reviewPhase(
  Flashcard card,
  Rating rating,
  DateTime now,
  Sm2Config config,
) {
  switch (rating) {
    case Rating.again:
      final newEase = max(config.minEase, card.easeFactor + config.againEaseDelta);
      return SchedulingResult(
        newState: CardState.relearning,
        newDueDate: now.add(config.relearningSteps[0]),
        newIntervalDays: card.intervalDays,
        newEaseFactor: newEase,
        newLearningStepIndex: 0,
        newLapses: card.lapses + 1,
        newReviewCount: card.reviewCount + 1,
      );

    case Rating.hard:
      final newEase = max(config.minEase, card.easeFactor + config.hardEaseDelta);
      final newInterval = _clampInterval(
        card.intervalDays,
        (card.intervalDays * config.hardIntervalMultiplier).round(),
        config,
      );
      return SchedulingResult(
        newState: CardState.review,
        newDueDate: now.add(Duration(days: newInterval)),
        newIntervalDays: newInterval,
        newEaseFactor: newEase,
        newLearningStepIndex: card.learningStepIndex,
        newLapses: card.lapses,
        newReviewCount: card.reviewCount + 1,
      );

    case Rating.good:
      final newInterval = _clampInterval(
        card.intervalDays,
        (card.intervalDays * card.easeFactor).round(),
        config,
      );
      return SchedulingResult(
        newState: CardState.review,
        newDueDate: now.add(Duration(days: newInterval)),
        newIntervalDays: newInterval,
        newEaseFactor: card.easeFactor,
        newLearningStepIndex: card.learningStepIndex,
        newLapses: card.lapses,
        newReviewCount: card.reviewCount + 1,
      );

    case Rating.easy:
      final newEase = card.easeFactor + config.easyEaseDelta;
      final newInterval = _clampInterval(
        card.intervalDays,
        (card.intervalDays * newEase * config.easyBonusMultiplier).round(),
        config,
      );
      return SchedulingResult(
        newState: CardState.review,
        newDueDate: now.add(Duration(days: newInterval)),
        newIntervalDays: newInterval,
        newEaseFactor: newEase,
        newLearningStepIndex: card.learningStepIndex,
        newLapses: card.lapses,
        newReviewCount: card.reviewCount + 1,
      );
  }
}

int _clampInterval(int currentInterval, int rawNewInterval, Sm2Config config) {
  return min(config.maxIntervalDays, max(currentInterval + 1, rawNewInterval));
}

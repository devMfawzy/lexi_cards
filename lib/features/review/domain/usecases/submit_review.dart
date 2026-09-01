import 'package:uuid/uuid.dart';
import '../../../cards/domain/entities/flashcard.dart';
import '../../../cards/domain/entities/review_log.dart';
import '../../../cards/domain/repositories/card_repository.dart';
import '../entities/rating.dart';
import '../scheduler/sm2_scheduler.dart';

class SubmitReview {
  final CardRepository repository;
  final Uuid _uuid;

  SubmitReview(this.repository, {Uuid? uuid}) : _uuid = uuid ?? const Uuid();

  Future<Flashcard> call(String cardId, Rating rating) async {
    final card = await repository.getCard(cardId);
    final result = computeNextSchedule(card, rating);

    final updated = card.copyWith(
      state: result.newState,
      dueDate: result.newDueDate,
      intervalDays: result.newIntervalDays,
      easeFactor: result.newEaseFactor,
      learningStepIndex: result.newLearningStepIndex,
      lapses: result.newLapses,
      reviewCount: result.newReviewCount,
    );

    await repository.updateCardSchedule(updated);
    await repository.addReviewLog(ReviewLog(
      id: _uuid.v4(),
      cardId: cardId,
      reviewedAt: DateTime.now(),
      rating: rating,
      previousIntervalDays: card.intervalDays,
      newIntervalDays: result.newIntervalDays,
      previousEaseFactor: card.easeFactor,
      newEaseFactor: result.newEaseFactor,
    ));

    return updated;
  }
}

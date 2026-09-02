import '../../cards/data/models/deck_model.dart';
import '../../cards/data/models/flashcard_model.dart';
import '../../cards/data/models/review_log_model.dart';
import '../../cards/data/models/tombstone_model.dart';
import '../../cards/domain/entities/flashcard.dart';
import '../../review/domain/entities/rating.dart';
import '../domain/entities/sync_records.dart';

// Converts between what Hive stores and what the merge works on. A missing
// clock (a record written before those fields existed) reads as `createdAt`.

DeckRecord deckToRecord(DeckModel model) => DeckRecord(
  id: model.id,
  name: model.name,
  createdAtMs: model.createdAt.millisecondsSinceEpoch,
  contentUpdatedAtMs: model.contentUpdatedAtMs ?? model.createdAt.millisecondsSinceEpoch,
);

DeckModel deckFromRecord(DeckRecord record) => DeckModel()
  ..id = record.id
  ..name = record.name
  ..createdAt = DateTime.fromMillisecondsSinceEpoch(record.createdAtMs)
  ..contentUpdatedAtMs = record.contentUpdatedAtMs;

CardRecord cardToRecord(FlashcardModel model) {
  final createdAtMs = model.createdAt.millisecondsSinceEpoch;
  return CardRecord(
    id: model.id,
    createdAtMs: createdAtMs,
    deckId: model.deckId,
    front: model.front,
    back: model.back,
    contentUpdatedAtMs: model.contentUpdatedAtMs ?? createdAtMs,
    state: CardState.values[model.state],
    dueDateMs: model.dueDate.millisecondsSinceEpoch,
    intervalDays: model.intervalDays,
    easeFactor: model.easeFactor,
    learningStepIndex: model.learningStepIndex,
    lapses: model.lapses,
    reviewCount: model.reviewCount,
    scheduleUpdatedAtMs: model.scheduleUpdatedAtMs ?? createdAtMs,
  );
}

FlashcardModel cardFromRecord(CardRecord record) => FlashcardModel()
  ..id = record.id
  ..deckId = record.deckId
  ..front = record.front
  ..back = record.back
  ..createdAt = DateTime.fromMillisecondsSinceEpoch(record.createdAtMs)
  ..state = record.state.index
  ..dueDate = DateTime.fromMillisecondsSinceEpoch(record.dueDateMs)
  ..intervalDays = record.intervalDays
  ..easeFactor = record.easeFactor
  ..learningStepIndex = record.learningStepIndex
  ..lapses = record.lapses
  ..reviewCount = record.reviewCount
  ..contentUpdatedAtMs = record.contentUpdatedAtMs
  ..scheduleUpdatedAtMs = record.scheduleUpdatedAtMs;

LogRecord logToRecord(ReviewLogModel model) => LogRecord(
  id: model.id,
  cardId: model.cardId,
  reviewedAtMs: model.reviewedAt.millisecondsSinceEpoch,
  rating: Rating.values[model.rating],
  previousIntervalDays: model.previousIntervalDays,
  newIntervalDays: model.newIntervalDays,
  previousEaseFactor: model.previousEaseFactor,
  newEaseFactor: model.newEaseFactor,
);

ReviewLogModel logFromRecord(LogRecord record) => ReviewLogModel()
  ..id = record.id
  ..cardId = record.cardId
  ..reviewedAt = DateTime.fromMillisecondsSinceEpoch(record.reviewedAtMs)
  ..rating = record.rating.index
  ..previousIntervalDays = record.previousIntervalDays
  ..newIntervalDays = record.newIntervalDays
  ..previousEaseFactor = record.previousEaseFactor
  ..newEaseFactor = record.newEaseFactor;

TombstoneRecord tombstoneToRecord(TombstoneModel model) =>
    TombstoneRecord(id: model.id, entityType: model.entityType, deletedAtMs: model.deletedAtMs);

TombstoneModel tombstoneFromRecord(TombstoneRecord record) => TombstoneModel.of(
  id: record.id,
  entityType: record.entityType,
  deletedAtMs: record.deletedAtMs,
);

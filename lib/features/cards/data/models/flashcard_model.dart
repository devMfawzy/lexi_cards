import 'package:hive_ce_flutter/hive_ce_flutter.dart';
import '../../domain/entities/flashcard.dart';

part 'flashcard_model.g.dart';

@HiveType(typeId: 1)
class FlashcardModel extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String deckId;

  @HiveField(2)
  late String front;

  @HiveField(3)
  late String back;

  @HiveField(4)
  late DateTime createdAt;

  @HiveField(5)
  late int state; // index into CardState: 0=newCard, 1=learning, 2=review, 3=relearning

  @HiveField(6)
  late DateTime dueDate;

  @HiveField(7)
  late int intervalDays;

  @HiveField(8)
  late double easeFactor;

  @HiveField(9)
  late int learningStepIndex;

  @HiveField(10)
  late int lapses;

  @HiveField(11)
  late int reviewCount;

  /// When the card's content and its scheduling last changed, in epoch
  /// milliseconds. Two clocks rather than one `updatedAt`: a card is edited and
  /// reviewed independently, and a single clock forces a merge to discard one.
  ///
  /// Nullable so records written before these fields existed still load — the
  /// generated adapter reads a sparse field map. Sync treats null as
  /// [createdAt]. Kept off [Flashcard] itself, which would change its `==`.
  @HiveField(12)
  int? contentUpdatedAtMs;

  @HiveField(13)
  int? scheduleUpdatedAtMs;

  Flashcard toEntity() => Flashcard(
    id: id,
    deckId: deckId,
    front: front,
    back: back,
    createdAt: createdAt,
    state: CardState.values[state],
    dueDate: dueDate,
    intervalDays: intervalDays,
    easeFactor: easeFactor,
    learningStepIndex: learningStepIndex,
    lapses: lapses,
    reviewCount: reviewCount,
  );

  static FlashcardModel fromEntity(Flashcard entity) => FlashcardModel()
    ..id = entity.id
    ..deckId = entity.deckId
    ..front = entity.front
    ..back = entity.back
    ..createdAt = entity.createdAt
    ..state = entity.state.index
    ..dueDate = entity.dueDate
    ..intervalDays = entity.intervalDays
    ..easeFactor = entity.easeFactor
    ..learningStepIndex = entity.learningStepIndex
    ..lapses = entity.lapses
    ..reviewCount = entity.reviewCount;
}

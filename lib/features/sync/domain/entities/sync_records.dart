import 'package:equatable/equatable.dart';

import '../../../cards/domain/entities/flashcard.dart';
import '../../../review/domain/entities/rating.dart';

// The shapes the merge works on — deliberately not the domain entities, which
// would gain sync clocks in their `Equatable.props` and change `==` for every
// existing consumer.
//
// Timestamps are epoch milliseconds, never `DateTime`: these go on the wire,
// where an ISO-8601 local time carries no offset, and `DateTime` equality also
// compares `isUtc`, so two objects for the same instant can compare unequal.

class DeckRecord extends Equatable {
  final String id;
  final String name;
  final int createdAtMs;
  final int contentUpdatedAtMs;

  const DeckRecord({
    required this.id,
    required this.name,
    required this.createdAtMs,
    required this.contentUpdatedAtMs,
  });

  DeckRecord copyWith({int? createdAtMs, int? contentUpdatedAtMs}) => DeckRecord(
    id: id,
    name: name,
    createdAtMs: createdAtMs ?? this.createdAtMs,
    contentUpdatedAtMs: contentUpdatedAtMs ?? this.contentUpdatedAtMs,
  );

  @override
  List<Object?> get props => [id, name, createdAtMs, contentUpdatedAtMs];
}

class CardRecord extends Equatable {
  final String id;
  final int createdAtMs;

  // Content lane — what the card says, changed by editing it.
  final String deckId;
  final String front;
  final String back;
  final int contentUpdatedAtMs;

  // Schedule lane — when the card is next due, changed by reviewing it.
  final CardState state;
  final int dueDateMs;
  final int intervalDays;
  final double easeFactor;
  final int learningStepIndex;
  final int lapses;
  final int reviewCount;
  final int scheduleUpdatedAtMs;

  const CardRecord({
    required this.id,
    required this.createdAtMs,
    required this.deckId,
    required this.front,
    required this.back,
    required this.contentUpdatedAtMs,
    required this.state,
    required this.dueDateMs,
    required this.intervalDays,
    required this.easeFactor,
    required this.learningStepIndex,
    required this.lapses,
    required this.reviewCount,
    required this.scheduleUpdatedAtMs,
  });

  /// Each lane moves as a whole. Mixing fields within one invents states the
  /// scheduler never produces — a `newCard` with 40 reviews would sit in the
  /// new-card queue forever — or shows the old answer to the new question.
  static CardRecord fromLanes({
    required CardRecord content,
    required CardRecord schedule,
    required int createdAtMs,
  }) => CardRecord(
    id: content.id,
    createdAtMs: createdAtMs,
    deckId: content.deckId,
    front: content.front,
    back: content.back,
    contentUpdatedAtMs: content.contentUpdatedAtMs,
    state: schedule.state,
    dueDateMs: schedule.dueDateMs,
    intervalDays: schedule.intervalDays,
    easeFactor: schedule.easeFactor,
    learningStepIndex: schedule.learningStepIndex,
    lapses: schedule.lapses,
    reviewCount: schedule.reviewCount,
    scheduleUpdatedAtMs: schedule.scheduleUpdatedAtMs,
  );

  @override
  List<Object?> get props => [
    id,
    createdAtMs,
    deckId,
    front,
    back,
    contentUpdatedAtMs,
    state,
    dueDateMs,
    intervalDays,
    easeFactor,
    learningStepIndex,
    lapses,
    reviewCount,
    scheduleUpdatedAtMs,
  ];
}

/// Immutable and append-only, which is why logs merge by plain union.
class LogRecord extends Equatable {
  final String id;
  final String cardId;
  final int reviewedAtMs;
  final Rating rating;
  final int previousIntervalDays;
  final int newIntervalDays;
  final double previousEaseFactor;
  final double newEaseFactor;

  const LogRecord({
    required this.id,
    required this.cardId,
    required this.reviewedAtMs,
    required this.rating,
    required this.previousIntervalDays,
    required this.newIntervalDays,
    required this.previousEaseFactor,
    required this.newEaseFactor,
  });

  @override
  List<Object?> get props => [
    id,
    cardId,
    reviewedAtMs,
    rating,
    previousIntervalDays,
    newIntervalDays,
    previousEaseFactor,
    newEaseFactor,
  ];
}

class TombstoneRecord extends Equatable {
  final String id;
  final String entityType;
  final int deletedAtMs;

  const TombstoneRecord({required this.id, required this.entityType, required this.deletedAtMs});

  String get key => '$entityType:$id';

  @override
  List<Object?> get props => [id, entityType, deletedAtMs];
}

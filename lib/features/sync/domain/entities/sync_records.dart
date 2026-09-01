import 'package:equatable/equatable.dart';

import '../../../cards/domain/entities/flashcard.dart';
import '../../../review/domain/entities/rating.dart';

/// The shapes the merge algorithm works on.
///
/// Deliberately *not* the domain entities. Merge needs each record's
/// modification clocks, and those describe a stored replica rather than a
/// flashcard — putting them on [Flashcard] would pull them into its
/// `Equatable.props`, changing `==` for every existing consumer (bloc emits on
/// state inequality, so a re-review that changed nothing else would start
/// counting as a state change) and forcing new values into every existing test
/// fixture. Keeping them here means `cards/domain` doesn't change at all.
///
/// Every timestamp is epoch milliseconds, never a `DateTime`. Two reasons:
/// these values go on the wire, where an ISO-8601 local time carries no offset
/// and would be reparsed in the receiving device's zone; and `DateTime`
/// equality also compares `isUtc`, so two objects for the same instant can
/// compare unequal, which would quietly break record comparison.

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

  /// Rebuilds this card taking its content from [content] and its scheduling
  /// from [schedule]. Each lane moves as a whole: mixing fields *within* a lane
  /// would invent states the scheduler never produces — a card marked `newCard`
  /// carrying a review count of 40 would sit in the new-card queue forever —
  /// and taking `front` from one side with `back` from the other would show the
  /// old answer to the new question.
  static CardRecord fromLanes({
    required CardRecord content,
    required CardRecord schedule,
    required int createdAtMs,
  }) =>
      CardRecord(
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

/// A review that happened. Immutable and append-only by construction, which is
/// why logs can be merged by plain union and can never conflict.
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

  const TombstoneRecord({
    required this.id,
    required this.entityType,
    required this.deletedAtMs,
  });

  String get key => '$entityType:$id';

  @override
  List<Object?> get props => [id, entityType, deletedAtMs];
}

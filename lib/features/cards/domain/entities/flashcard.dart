import 'package:equatable/equatable.dart';

enum CardState { newCard, learning, review, relearning }

class Flashcard extends Equatable {
  final String id;
  final String deckId;
  final String front;
  final String back;
  final DateTime createdAt;
  final CardState state;
  final DateTime dueDate;
  final int intervalDays;
  final double easeFactor;
  final int learningStepIndex;
  final int lapses;
  final int reviewCount;

  const Flashcard({
    required this.id,
    required this.deckId,
    required this.front,
    required this.back,
    required this.createdAt,
    required this.state,
    required this.dueDate,
    required this.intervalDays,
    required this.easeFactor,
    required this.learningStepIndex,
    required this.lapses,
    required this.reviewCount,
  });

  factory Flashcard.newCard({
    required String id,
    required String deckId,
    required String front,
    required String back,
    required DateTime createdAt,
  }) {
    return Flashcard(
      id: id,
      deckId: deckId,
      front: front,
      back: back,
      createdAt: createdAt,
      state: CardState.newCard,
      dueDate: createdAt,
      intervalDays: 0,
      easeFactor: 2.5,
      learningStepIndex: 0,
      lapses: 0,
      reviewCount: 0,
    );
  }

  Flashcard copyWith({
    String? id,
    String? deckId,
    String? front,
    String? back,
    DateTime? createdAt,
    CardState? state,
    DateTime? dueDate,
    int? intervalDays,
    double? easeFactor,
    int? learningStepIndex,
    int? lapses,
    int? reviewCount,
  }) {
    return Flashcard(
      id: id ?? this.id,
      deckId: deckId ?? this.deckId,
      front: front ?? this.front,
      back: back ?? this.back,
      createdAt: createdAt ?? this.createdAt,
      state: state ?? this.state,
      dueDate: dueDate ?? this.dueDate,
      intervalDays: intervalDays ?? this.intervalDays,
      easeFactor: easeFactor ?? this.easeFactor,
      learningStepIndex: learningStepIndex ?? this.learningStepIndex,
      lapses: lapses ?? this.lapses,
      reviewCount: reviewCount ?? this.reviewCount,
    );
  }

  @override
  List<Object?> get props => [
        id,
        deckId,
        front,
        back,
        createdAt,
        state,
        dueDate,
        intervalDays,
        easeFactor,
        learningStepIndex,
        lapses,
        reviewCount,
      ];
}

import 'package:equatable/equatable.dart';
import '../../../cards/domain/entities/flashcard.dart';

class SchedulingResult extends Equatable {
  final CardState newState;
  final DateTime newDueDate;
  final int newIntervalDays;
  final double newEaseFactor;
  final int newLearningStepIndex;
  final int newLapses;
  final int newReviewCount;

  const SchedulingResult({
    required this.newState,
    required this.newDueDate,
    required this.newIntervalDays,
    required this.newEaseFactor,
    required this.newLearningStepIndex,
    required this.newLapses,
    required this.newReviewCount,
  });

  @override
  List<Object?> get props => [
    newState,
    newDueDate,
    newIntervalDays,
    newEaseFactor,
    newLearningStepIndex,
    newLapses,
    newReviewCount,
  ];
}

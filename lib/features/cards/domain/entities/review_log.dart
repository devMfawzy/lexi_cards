import 'package:equatable/equatable.dart';
import '../../../review/domain/entities/rating.dart';

class ReviewLog extends Equatable {
  final String id;
  final String cardId;
  final DateTime reviewedAt;
  final Rating rating;
  final int previousIntervalDays;
  final int newIntervalDays;
  final double previousEaseFactor;
  final double newEaseFactor;

  const ReviewLog({
    required this.id,
    required this.cardId,
    required this.reviewedAt,
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
    reviewedAt,
    rating,
    previousIntervalDays,
    newIntervalDays,
    previousEaseFactor,
    newEaseFactor,
  ];
}

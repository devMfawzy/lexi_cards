import 'package:equatable/equatable.dart';

class DailyCount extends Equatable {
  final DateTime date;
  final int count;

  const DailyCount({required this.date, required this.count});

  @override
  List<Object?> get props => [date, count];
}

class ReviewStats extends Equatable {
  final int totalReviews;
  final int totalCards;
  final int cardsInProgress;
  final double retentionRate;
  final int currentStreakDays;
  final int longestStreakDays;
  final List<DailyCount> reviewsLast7Days;
  final List<DailyCount> dueNext7Days;

  const ReviewStats({
    required this.totalReviews,
    required this.totalCards,
    required this.cardsInProgress,
    required this.retentionRate,
    required this.currentStreakDays,
    required this.longestStreakDays,
    required this.reviewsLast7Days,
    required this.dueNext7Days,
  });

  @override
  List<Object?> get props => [
    totalReviews,
    totalCards,
    cardsInProgress,
    retentionRate,
    currentStreakDays,
    longestStreakDays,
    reviewsLast7Days,
    dueNext7Days,
  ];
}

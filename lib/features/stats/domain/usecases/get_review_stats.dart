import '../../../cards/domain/entities/flashcard.dart';
import '../../../cards/domain/entities/review_log.dart';
import '../../../cards/domain/repositories/card_repository.dart';
import '../../../review/domain/entities/rating.dart';
import '../entities/review_stats.dart';

class GetReviewStats {
  final CardRepository repository;
  GetReviewStats(this.repository);

  Future<ReviewStats> call({DateTime? now}) async {
    final effectiveNow = now ?? DateTime.now();
    final logs = await repository.getAllReviewLogs();
    final cards = await repository.getAllCards();

    final totalReviews = logs.length;
    final successCount = logs.where((l) => l.rating != Rating.again).length;
    final retentionRate = totalReviews == 0 ? 0.0 : successCount / totalReviews;

    final reviewDays = logs.map((l) => _dateOnly(l.reviewedAt)).toSet();

    return ReviewStats(
      totalReviews: totalReviews,
      totalCards: cards.length,
      cardsInProgress: cards.where((c) => c.state != CardState.newCard).length,
      retentionRate: retentionRate,
      currentStreakDays: _currentStreak(reviewDays, effectiveNow),
      longestStreakDays: _longestStreak(reviewDays),
      reviewsLast7Days: _reviewsLast7Days(logs, effectiveNow),
      dueNext7Days: _dueNext7Days(cards, effectiveNow),
    );
  }

  DateTime _dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

  int _currentStreak(Set<DateTime> reviewDays, DateTime now) {
    final today = _dateOnly(now);
    var cursor = today;
    if (!reviewDays.contains(cursor)) {
      cursor = cursor.subtract(const Duration(days: 1));
      if (!reviewDays.contains(cursor)) return 0;
    }
    var streak = 0;
    while (reviewDays.contains(cursor)) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }

  int _longestStreak(Set<DateTime> reviewDays) {
    if (reviewDays.isEmpty) return 0;
    final sorted = reviewDays.toList()..sort();
    var longest = 1;
    var current = 1;
    for (var i = 1; i < sorted.length; i++) {
      final gap = sorted[i].difference(sorted[i - 1]).inDays;
      current = gap == 1 ? current + 1 : 1;
      if (current > longest) longest = current;
    }
    return longest;
  }

  List<DailyCount> _reviewsLast7Days(List<ReviewLog> logs, DateTime now) {
    final today = _dateOnly(now);
    final counts = <DateTime, int>{
      for (var i = 6; i >= 0; i--) today.subtract(Duration(days: i)): 0,
    };
    for (final log in logs) {
      final day = _dateOnly(log.reviewedAt);
      if (counts.containsKey(day)) counts[day] = counts[day]! + 1;
    }
    return counts.entries.map((e) => DailyCount(date: e.key, count: e.value)).toList();
  }

  List<DailyCount> _dueNext7Days(List<Flashcard> cards, DateTime now) {
    final today = _dateOnly(now);
    final counts = <DateTime, int>{for (var i = 0; i < 7; i++) today.add(Duration(days: i)): 0};
    for (final card in cards) {
      if (card.state == CardState.newCard) continue;
      final due = _dateOnly(card.dueDate);
      final bucket = due.isBefore(today) ? today : due;
      if (counts.containsKey(bucket)) counts[bucket] = counts[bucket]! + 1;
    }
    return counts.entries.map((e) => DailyCount(date: e.key, count: e.value)).toList();
  }
}

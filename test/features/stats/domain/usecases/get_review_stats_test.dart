import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:lexi_cards/features/cards/domain/entities/flashcard.dart';
import 'package:lexi_cards/features/cards/domain/entities/review_log.dart';
import 'package:lexi_cards/features/cards/domain/repositories/card_repository.dart';
import 'package:lexi_cards/features/review/domain/entities/rating.dart';
import 'package:lexi_cards/features/stats/domain/usecases/get_review_stats.dart';

class MockCardRepository extends Mock implements CardRepository {}

void main() {
  late MockCardRepository repository;
  late GetReviewStats getReviewStats;

  final now = DateTime(2026, 1, 15, 18, 0, 0);

  ReviewLog logOn(DateTime day, {Rating rating = Rating.good}) {
    return ReviewLog(
      id: 'log-${day.toIso8601String()}-${rating.name}',
      cardId: 'c1',
      reviewedAt: day,
      rating: rating,
      previousIntervalDays: 0,
      newIntervalDays: 1,
      previousEaseFactor: 2.5,
      newEaseFactor: 2.5,
    );
  }

  setUp(() {
    repository = MockCardRepository();
    getReviewStats = GetReviewStats(repository);
    when(() => repository.getAllCards()).thenAnswer((_) async => <Flashcard>[]);
  });

  Future<int> currentStreakWith(List<ReviewLog> logs) async {
    when(() => repository.getAllReviewLogs()).thenAnswer((_) async => logs);
    final stats = await getReviewStats(now: now);
    return stats.currentStreakDays;
  }

  group('current streak', () {
    test('is 0 when there are no reviews', () async {
      expect(await currentStreakWith([]), 0);
    });

    test('counts consecutive days ending today', () async {
      final logs = [
        logOn(now),
        logOn(now.subtract(const Duration(days: 1))),
        logOn(now.subtract(const Duration(days: 2))),
      ];
      expect(await currentStreakWith(logs), 3);
    });

    test('still counts an active streak if today has no review yet but yesterday does', () async {
      final logs = [
        logOn(now.subtract(const Duration(days: 1))),
        logOn(now.subtract(const Duration(days: 2))),
      ];
      expect(await currentStreakWith(logs), 2);
    });

    test('is 0 when the most recent review was more than a day ago', () async {
      final logs = [logOn(now.subtract(const Duration(days: 2)))];
      expect(await currentStreakWith(logs), 0);
    });

    test('breaks on a gap and only counts the run touching today', () async {
      final logs = [
        logOn(now),
        // gap on day -1
        logOn(now.subtract(const Duration(days: 2))),
        logOn(now.subtract(const Duration(days: 3))),
      ];
      expect(await currentStreakWith(logs), 1);
    });

    test('multiple reviews on the same day only count once', () async {
      final logs = [
        logOn(now),
        logOn(now.add(const Duration(hours: 1))),
        logOn(now.subtract(const Duration(days: 1))),
      ];
      expect(await currentStreakWith(logs), 2);
    });
  });

  group('longest streak', () {
    test('is 0 when there are no reviews', () async {
      when(() => repository.getAllReviewLogs()).thenAnswer((_) async => []);
      final stats = await getReviewStats(now: now);
      expect(stats.longestStreakDays, 0);
    });

    test('finds a past run longer than the current active streak', () async {
      final logs = [
        // 4-day run in the past, ending 10 days ago
        logOn(now.subtract(const Duration(days: 10))),
        logOn(now.subtract(const Duration(days: 11))),
        logOn(now.subtract(const Duration(days: 12))),
        logOn(now.subtract(const Duration(days: 13))),
        // 2-day active run touching today
        logOn(now),
        logOn(now.subtract(const Duration(days: 1))),
      ];
      when(() => repository.getAllReviewLogs()).thenAnswer((_) async => logs);
      final stats = await getReviewStats(now: now);
      expect(stats.longestStreakDays, 4);
      expect(stats.currentStreakDays, 2);
    });
  });

  group('retention rate', () {
    test('is 0.0 when there are no reviews', () async {
      when(() => repository.getAllReviewLogs()).thenAnswer((_) async => []);
      final stats = await getReviewStats(now: now);
      expect(stats.retentionRate, 0.0);
    });

    test('counts hard, good and easy as retained and again as a lapse', () async {
      final logs = [
        logOn(now, rating: Rating.again),
        logOn(now, rating: Rating.hard),
        logOn(now, rating: Rating.good),
        logOn(now, rating: Rating.easy),
      ];
      when(() => repository.getAllReviewLogs()).thenAnswer((_) async => logs);
      final stats = await getReviewStats(now: now);
      expect(stats.retentionRate, 0.75);
      expect(stats.totalReviews, 4);
    });

    test('is 1.0 when no review was rated again', () async {
      final logs = [
        logOn(now, rating: Rating.good),
        logOn(now, rating: Rating.easy),
      ];
      when(() => repository.getAllReviewLogs()).thenAnswer((_) async => logs);
      final stats = await getReviewStats(now: now);
      expect(stats.retentionRate, 1.0);
    });

    test('is 0.0 when every review was rated again', () async {
      final logs = [
        logOn(now, rating: Rating.again),
        logOn(now.subtract(const Duration(days: 1)), rating: Rating.again),
      ];
      when(() => repository.getAllReviewLogs()).thenAnswer((_) async => logs);
      final stats = await getReviewStats(now: now);
      expect(stats.retentionRate, 0.0);
    });
  });
}

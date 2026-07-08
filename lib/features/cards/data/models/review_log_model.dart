import 'package:hive_flutter/hive_flutter.dart';
import '../../../review/domain/entities/rating.dart';
import '../../domain/entities/review_log.dart';

part 'review_log_model.g.dart';

@HiveType(typeId: 2)
class ReviewLogModel extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String cardId;

  @HiveField(2)
  late DateTime reviewedAt;

  @HiveField(3)
  late int rating; // index into Rating: 0=again, 1=hard, 2=good, 3=easy

  @HiveField(4)
  late int previousIntervalDays;

  @HiveField(5)
  late int newIntervalDays;

  @HiveField(6)
  late double previousEaseFactor;

  @HiveField(7)
  late double newEaseFactor;

  ReviewLog toEntity() => ReviewLog(
        id: id,
        cardId: cardId,
        reviewedAt: reviewedAt,
        rating: Rating.values[rating],
        previousIntervalDays: previousIntervalDays,
        newIntervalDays: newIntervalDays,
        previousEaseFactor: previousEaseFactor,
        newEaseFactor: newEaseFactor,
      );

  static ReviewLogModel fromEntity(ReviewLog entity) => ReviewLogModel()
    ..id = entity.id
    ..cardId = entity.cardId
    ..reviewedAt = entity.reviewedAt
    ..rating = entity.rating.index
    ..previousIntervalDays = entity.previousIntervalDays
    ..newIntervalDays = entity.newIntervalDays
    ..previousEaseFactor = entity.previousEaseFactor
    ..newEaseFactor = entity.newEaseFactor;
}

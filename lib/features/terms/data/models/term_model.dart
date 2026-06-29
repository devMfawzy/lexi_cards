import 'package:hive_flutter/hive_flutter.dart';
import '../../domain/entities/term.dart';

part 'term_model.g.dart';

@HiveType(typeId: 1)
class TermModel extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String setId;

  @HiveField(2)
  late String text;

  @HiveField(3)
  late List<String> phrases;

  @HiveField(4)
  late int reviewStatus; // 0=fresh, 1=learning, 2=known

  @HiveField(5)
  late DateTime createdAt;

  Term toEntity() => Term(
        id: id,
        setId: setId,
        text: text,
        phrases: phrases,
        reviewStatus: ReviewStatus.values[reviewStatus],
        createdAt: createdAt,
      );

  static TermModel fromEntity(Term entity) => TermModel()
    ..id = entity.id
    ..setId = entity.setId
    ..text = entity.text
    ..phrases = entity.phrases
    ..reviewStatus = entity.reviewStatus.index
    ..createdAt = entity.createdAt;
}

import 'package:hive_flutter/hive_flutter.dart';
import '../../domain/entities/term_set.dart';

part 'term_set_model.g.dart';

@HiveType(typeId: 0)
class TermSetModel extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String name;

  @HiveField(2)
  late String targetLanguage;

  @HiveField(3)
  late DateTime createdAt;

  TermSet toEntity() => TermSet(
        id: id,
        name: name,
        targetLanguage: targetLanguage,
        createdAt: createdAt,
      );

  static TermSetModel fromEntity(TermSet entity) => TermSetModel()
    ..id = entity.id
    ..name = entity.name
    ..targetLanguage = entity.targetLanguage
    ..createdAt = entity.createdAt;
}

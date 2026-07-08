import 'package:hive_flutter/hive_flutter.dart';
import '../../domain/entities/deck.dart';

part 'deck_model.g.dart';

@HiveType(typeId: 0)
class DeckModel extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String name;

  @HiveField(2)
  late DateTime createdAt;

  Deck toEntity() => Deck(
        id: id,
        name: name,
        createdAt: createdAt,
      );

  static DeckModel fromEntity(Deck entity) => DeckModel()
    ..id = entity.id
    ..name = entity.name
    ..createdAt = entity.createdAt;
}

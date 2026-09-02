import 'package:hive_ce_flutter/hive_ce_flutter.dart';
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

  /// When this deck was last renamed, as epoch milliseconds. See
  /// [FlashcardModel.contentUpdatedAtMs] for why this is nullable, stored as
  /// an int, and kept off the domain entity. A deck has no scheduling state,
  /// so it needs only the one clock.
  @HiveField(3)
  int? contentUpdatedAtMs;

  Deck toEntity() => Deck(id: id, name: name, createdAt: createdAt);

  static DeckModel fromEntity(Deck entity) => DeckModel()
    ..id = entity.id
    ..name = entity.name
    ..createdAt = entity.createdAt;
}

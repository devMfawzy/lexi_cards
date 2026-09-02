import 'package:hive_ce_flutter/hive_ce_flutter.dart';

part 'tombstone_model.g.dart';

/// Stored as strings rather than enum indices, which reordering would break.
class TombstoneEntity {
  static const deck = 'deck';
  static const card = 'card';
}

/// A record of something the user deleted. Without one, sync can't tell
/// "deleted here" from "not created here yet", and the record returns from the
/// other device.
///
/// Deleting a deck records one tombstone for the deck, not one per card — card
/// removal is derived from it at merge time, so a card edited concurrently
/// elsewhere can't outlive its own deck.
@HiveType(typeId: 3)
class TombstoneModel extends HiveObject {
  /// The id of the deleted deck or card.
  @HiveField(0)
  late String id;

  /// One of [TombstoneEntity]'s constants.
  @HiveField(1)
  late String entityType;

  @HiveField(2)
  late int deletedAtMs;

  static TombstoneModel of({
    required String id,
    required String entityType,
    required int deletedAtMs,
  }) => TombstoneModel()
    ..id = id
    ..entityType = entityType
    ..deletedAtMs = deletedAtMs;

  /// The Hive key to store this under: type *and* id, since a deck and a card
  /// could in principle carry the same uuid. Named to avoid colliding with
  /// [HiveObject.key], which is the key an object was actually stored under.
  String get storageKey => '$entityType:$id';
}

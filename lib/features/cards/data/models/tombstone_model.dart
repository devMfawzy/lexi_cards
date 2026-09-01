import 'package:hive_ce_flutter/hive_ce_flutter.dart';

part 'tombstone_model.g.dart';

/// What a [TombstoneModel] refers to. Stored as a string rather than an enum
/// index because the persisted value has to survive the enum being reordered.
class TombstoneEntity {
  static const deck = 'deck';
  static const card = 'card';
}

/// A record of something the user deleted.
///
/// Deletion has to leave a trace, or sync can't tell "deleted here" apart from
/// "not yet created here" — a record deleted on one device would simply come
/// back from the other, which is the classic way local-first sync loses a
/// user's intent.
///
/// Only decks and individual cards get tombstones. Deleting a deck records one
/// tombstone for the deck itself, *not* one per card it contained: the cards'
/// removal is derived at merge time from the deck's tombstone, so a card that
/// was concurrently edited on another device can't survive its own deck and
/// become an unreachable orphan.
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
  }) =>
      TombstoneModel()
        ..id = id
        ..entityType = entityType
        ..deletedAtMs = deletedAtMs;

  /// The Hive key to store this under: type *and* id, since a deck and a card
  /// could in principle carry the same uuid. Named to avoid colliding with
  /// [HiveObject.key], which is the key an object was actually stored under.
  String get storageKey => '$entityType:$id';
}

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive_ce.dart';

import 'package:lexi_cards/features/cards/data/datasources/local_datasource.dart';
import 'package:lexi_cards/features/cards/data/models/deck_model.dart';
import 'package:lexi_cards/features/cards/data/models/flashcard_model.dart';
import 'package:lexi_cards/features/cards/data/models/review_log_model.dart';
import 'package:lexi_cards/features/cards/data/models/tombstone_model.dart';
import 'package:lexi_cards/hive_registrar.g.dart';

void main() {
  late Directory tempDir;
  var clock = DateTime.utc(2026, 1, 1);

  LocalDataSourceImpl buildDataSource() => LocalDataSourceImpl(now: () => clock);

  DeckModel deck(String id, {String name = 'Spanish'}) => DeckModel()
    ..id = id
    ..name = name
    ..createdAt = DateTime.utc(2025, 1, 1);

  FlashcardModel card(String id, {String deckId = 'deck-1'}) => FlashcardModel()
    ..id = id
    ..deckId = deckId
    ..front = 'front'
    ..back = 'back'
    ..createdAt = DateTime.utc(2025, 1, 1)
    ..state = 0
    ..dueDate = DateTime.utc(2025, 1, 1)
    ..intervalDays = 0
    ..easeFactor = 2.5
    ..learningStepIndex = 0
    ..lapses = 0
    ..reviewCount = 0;

  setUpAll(Hive.registerAdapters);

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('lexi_cards_datasource_test');
    Hive.init(tempDir.path);
    clock = DateTime.utc(2026, 1, 1);
  });

  tearDown(() async {
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  group('write clocks', () {
    test('a brand new card has both clocks established at once', () async {
      final dataSource = buildDataSource();

      final saved = await dataSource.saveCard(card('card-1'), kind: WriteKind.content);

      expect(saved.contentUpdatedAtMs, clock.millisecondsSinceEpoch);
      expect(saved.scheduleUpdatedAtMs, clock.millisecondsSinceEpoch);
    });

    test('a content edit advances the content clock and leaves the schedule clock', () async {
      final dataSource = buildDataSource();
      await dataSource.saveCard(card('card-1'), kind: WriteKind.content);
      final scheduledAt = clock.millisecondsSinceEpoch;

      clock = DateTime.utc(2026, 2, 1);
      final edited = await dataSource.saveCard(card('card-1'), kind: WriteKind.content);

      expect(edited.contentUpdatedAtMs, clock.millisecondsSinceEpoch);
      expect(edited.scheduleUpdatedAtMs, scheduledAt);
    });

    test('a review advances the schedule clock and leaves the content clock', () async {
      final dataSource = buildDataSource();
      await dataSource.saveCard(card('card-1'), kind: WriteKind.content);
      final editedAt = clock.millisecondsSinceEpoch;

      clock = DateTime.utc(2026, 2, 1);
      final reviewed = await dataSource.saveCard(card('card-1'), kind: WriteKind.schedule);

      expect(reviewed.contentUpdatedAtMs, editedAt);
      expect(reviewed.scheduleUpdatedAtMs, clock.millisecondsSinceEpoch);
    });

    test('the model handed in carries no clocks, so they must come from storage', () async {
      // Guards the actual bug this design is exposed to: models are rebuilt
      // from domain entities on every write, and the entity has no clocks — so
      // a write that didn't carry the other clock over would silently erase it.
      final dataSource = buildDataSource();
      await dataSource.saveCard(card('card-1'), kind: WriteKind.schedule);

      clock = DateTime.utc(2026, 3, 1);
      final rebuilt = card('card-1');
      expect(rebuilt.scheduleUpdatedAtMs, isNull);

      final saved = await dataSource.saveCard(rebuilt, kind: WriteKind.content);
      expect(saved.scheduleUpdatedAtMs, isNotNull);
    });

    test('a verbatim write keeps the clocks exactly as supplied', () async {
      final dataSource = buildDataSource();
      final incoming = card('card-1')
        ..contentUpdatedAtMs = 111
        ..scheduleUpdatedAtMs = 222;

      final saved = await dataSource.saveCard(incoming, kind: WriteKind.verbatim);

      expect(saved.contentUpdatedAtMs, 111);
      expect(saved.scheduleUpdatedAtMs, 222);
    });

    test('renaming a deck advances its clock, a verbatim write does not', () async {
      final dataSource = buildDataSource();
      await dataSource.saveDeck(deck('deck-1'), kind: WriteKind.content);

      clock = DateTime.utc(2026, 5, 1);
      final renamed = await dataSource.saveDeck(
        deck('deck-1', name: 'Español'),
        kind: WriteKind.content,
      );
      expect(renamed.contentUpdatedAtMs, clock.millisecondsSinceEpoch);

      final applied = await dataSource.saveDeck(
        deck('deck-1')..contentUpdatedAtMs = 999,
        kind: WriteKind.verbatim,
      );
      expect(applied.contentUpdatedAtMs, 999);
    });
  });

  group('tombstones', () {
    test('deleting a card records a tombstone', () async {
      final dataSource = buildDataSource();
      await dataSource.saveCard(card('card-1'), kind: WriteKind.content);

      await dataSource.deleteCard('card-1');

      final tombstones = await dataSource.getTombstones();
      expect(tombstones, hasLength(1));
      expect(tombstones.single.id, 'card-1');
      expect(tombstones.single.entityType, TombstoneEntity.card);
      expect(tombstones.single.deletedAtMs, clock.millisecondsSinceEpoch);
      expect(await dataSource.getCard('card-1'), isNull);
    });

    test('deleting a deck records one tombstone for the deck, not one per card', () async {
      // The cards' removal is derived from the deck's tombstone at merge time.
      // Recording a tombstone per card instead would let a card that was
      // concurrently edited elsewhere outlive its own deck.
      final dataSource = buildDataSource();
      await dataSource.saveDeck(deck('deck-1'), kind: WriteKind.content);
      for (final id in ['card-1', 'card-2', 'card-3']) {
        await dataSource.saveCard(card(id), kind: WriteKind.content);
      }

      await dataSource.deleteDeck('deck-1');

      final tombstones = await dataSource.getTombstones();
      expect(tombstones, hasLength(1));
      expect(tombstones.single.id, 'deck-1');
      expect(tombstones.single.entityType, TombstoneEntity.deck);
    });

    test('deleting a deck leaves no card pointing at it', () async {
      final dataSource = buildDataSource();
      await dataSource.saveDeck(deck('deck-1'), kind: WriteKind.content);
      await dataSource.saveCard(card('card-1'), kind: WriteKind.content);
      await dataSource.saveCard(card('card-2'), kind: WriteKind.content);
      await dataSource.saveCard(card('other', deckId: 'deck-2'), kind: WriteKind.content);

      await dataSource.deleteDeck('deck-1');

      final remaining = await dataSource.getAllCards();
      expect(remaining.map((c) => c.id), ['other']);
      expect(await dataSource.getDeck('deck-1'), isNull);
    });

    test('deleting a card keeps its review logs', () async {
      // Deliberate, and pinned here because it looks like a leak worth
      // "fixing". Stats aggregate over every log without joining back to
      // cards, so dropping them on delete would silently rewrite the user's
      // history — their streak would change because they tidied up a deck.
      final dataSource = buildDataSource();
      await dataSource.saveCard(card('card-1'), kind: WriteKind.content);
      await dataSource.saveReviewLog(
        ReviewLogModel()
          ..id = 'log-1'
          ..cardId = 'card-1'
          ..reviewedAt = DateTime.utc(2025, 6, 1)
          ..rating = 2
          ..previousIntervalDays = 1
          ..newIntervalDays = 3
          ..previousEaseFactor = 2.5
          ..newEaseFactor = 2.5,
      );

      await dataSource.deleteCard('card-1');

      expect(await dataSource.getAllReviewLogs(), hasLength(1));
    });

    test('deleting the same record twice keeps one tombstone, at the later time', () async {
      final dataSource = buildDataSource();
      await dataSource.saveCard(card('card-1'), kind: WriteKind.content);
      await dataSource.deleteCard('card-1');

      clock = DateTime.utc(2026, 6, 1);
      await dataSource.deleteCard('card-1');

      final tombstones = await dataSource.getTombstones();
      expect(tombstones, hasLength(1));
      expect(tombstones.single.deletedAtMs, clock.millisecondsSinceEpoch);
    });
  });
}

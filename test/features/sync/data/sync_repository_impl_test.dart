import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive_ce.dart';

import 'package:lexi_cards/core/sync/cloud_storage.dart';
import 'package:lexi_cards/features/cards/data/datasources/local_datasource.dart';
import 'package:lexi_cards/features/cards/data/models/deck_model.dart';
import 'package:lexi_cards/features/cards/data/models/flashcard_model.dart';
import 'package:lexi_cards/features/cards/domain/entities/flashcard.dart';
import 'package:lexi_cards/features/sync/data/repositories/sync_repository_impl.dart';
import 'package:lexi_cards/features/sync/data/sync_snapshot_codec.dart';
import 'package:lexi_cards/features/sync/domain/entities/sync_records.dart';
import 'package:lexi_cards/features/sync/domain/entities/sync_snapshot.dart';
import 'package:lexi_cards/hive_registrar.g.dart';

/// Stands in for Drive. Holds one blob and a revision, and can be told to
/// reject the next upload so the conflict path is exercised without a network.
class FakeCloudStorage implements CloudStorage {
  CloudAccount? account = const CloudAccount('me@example.com');
  Uint8List? stored;
  String revision = 'r0';
  int uploadCount = 0;
  int rejectNextUploads = 0;

  @override
  CloudAccount? get currentAccount => account;

  @override
  Future<CloudAccount?> restoreAccount() async => account;

  @override
  Future<CloudAccount?> linkAccount() async => account;

  @override
  Future<void> unlinkAccount() async => account = null;

  @override
  Future<RemoteSnapshot?> download() async =>
      stored == null ? null : RemoteSnapshot(bytes: stored!, revision: revision);

  @override
  Future<String> upload(Uint8List bytes, {required String? expectedRevision}) async {
    uploadCount++;
    if (rejectNextUploads > 0) {
      rejectNextUploads--;
      throw const RemoteChangedException();
    }
    if (stored != null && expectedRevision != revision) {
      throw const RemoteChangedException();
    }
    stored = bytes;
    revision = 'r$uploadCount';
    return revision;
  }
}

void main() {
  late Directory tempDir;
  late LocalDataSourceImpl localDataSource;
  late FakeCloudStorage cloud;
  var clock = DateTime.utc(2026, 6, 1);

  SyncRepositoryImpl buildRepository() => SyncRepositoryImpl(
        localDataSource: localDataSource,
        cloudStorage: cloud,
        now: () => clock,
      );

  DeckModel deck(String id, {String name = 'Spanish'}) => DeckModel()
    ..id = id
    ..name = name
    ..createdAt = DateTime.utc(2026, 1, 1);

  FlashcardModel card(String id, {String deckId = 'deck-1', String front = 'front'}) =>
      FlashcardModel()
        ..id = id
        ..deckId = deckId
        ..front = front
        ..back = 'back'
        ..createdAt = DateTime.utc(2026, 1, 1)
        ..state = 0
        ..dueDate = DateTime.utc(2026, 1, 1)
        ..intervalDays = 0
        ..easeFactor = 2.5
        ..learningStepIndex = 0
        ..lapses = 0
        ..reviewCount = 0;

  /// Rewrites what's "in the cloud" the way a second device would have.
  void publishFromAnotherDevice(SyncSnapshot Function(SyncSnapshot) edit) {
    final current = cloud.stored == null
        ? SyncSnapshot.empty
        : SyncSnapshotCodec.decode(cloud.stored!);
    cloud.stored = SyncSnapshotCodec.encode(edit(current));
    cloud.revision = 'remote-edit';
  }

  setUpAll(Hive.registerAdapters);

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('lexi_cards_sync_test');
    Hive.init(tempDir.path);
    localDataSource = LocalDataSourceImpl(now: () => clock);
    cloud = FakeCloudStorage();
    clock = DateTime.utc(2026, 6, 1);
  });

  tearDown(() async {
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  test('the first sync uploads local data and changes nothing locally', () async {
    await localDataSource.saveDeck(deck('deck-1'), kind: WriteKind.content);
    await localDataSource.saveCard(card('card-1'), kind: WriteKind.content);

    final outcome = await buildRepository().sync();

    expect(outcome.isUpToDate, isTrue);
    expect(cloud.stored, isNotNull);
    final uploaded = SyncSnapshotCodec.decode(cloud.stored!);
    expect(uploaded.decks.single.id, 'deck-1');
    expect(uploaded.cards.single.id, 'card-1');
  });

  test('a card added on another device arrives locally', () async {
    await localDataSource.saveDeck(deck('deck-1'), kind: WriteKind.content);
    await buildRepository().sync();

    publishFromAnotherDevice((s) => s.copyWith(cards: [
          ...s.cards,
          const CardRecord(
            id: 'from-other-device',
            createdAtMs: 1000,
            deckId: 'deck-1',
            front: 'hola',
            back: 'hello',
            contentUpdatedAtMs: 2000,
            state: CardState.newCard,
            dueDateMs: 1000,
            intervalDays: 0,
            easeFactor: 2.5,
            learningStepIndex: 0,
            lapses: 0,
            reviewCount: 0,
            scheduleUpdatedAtMs: 2000,
          ),
        ]));

    final outcome = await buildRepository().sync();

    expect(outcome.cardsChanged, 1);
    final stored = await localDataSource.getCard('from-other-device');
    expect(stored, isNotNull);
    expect(stored!.front, 'hola');
    expect(stored.deckId, 'deck-1');
  });

  test('a card deleted here is removed on the other device too', () async {
    await localDataSource.saveDeck(deck('deck-1'), kind: WriteKind.content);
    await localDataSource.saveCard(card('card-1'), kind: WriteKind.content);
    await buildRepository().sync();

    clock = DateTime.utc(2026, 7, 1);
    await localDataSource.deleteCard('card-1');
    await buildRepository().sync();

    final uploaded = SyncSnapshotCodec.decode(cloud.stored!);
    expect(uploaded.cards, isEmpty);
    expect(uploaded.tombstones.single.id, 'card-1');
  });

  test('a card deleted on another device is removed here', () async {
    await localDataSource.saveDeck(deck('deck-1'), kind: WriteKind.content);
    await localDataSource.saveCard(card('card-1'), kind: WriteKind.content);
    await buildRepository().sync();

    publishFromAnotherDevice((s) => s.copyWith(
          cards: const [],
          tombstones: const [
            TombstoneRecord(id: 'card-1', entityType: 'card', deletedAtMs: 9999999999999),
          ],
        ));

    final outcome = await buildRepository().sync();

    expect(outcome.recordsRemoved, 1);
    expect(await localDataSource.getCard('card-1'), isNull);
  });

  test('applying a remote deletion does not restamp the tombstone', () async {
    // Deleting through the normal path records a tombstone stamped "now",
    // which would overwrite the real deletion time from the other device and
    // let the record resurrect itself on the next merge.
    await localDataSource.saveDeck(deck('deck-1'), kind: WriteKind.content);
    await localDataSource.saveCard(card('card-1'), kind: WriteKind.content);
    await buildRepository().sync();

    publishFromAnotherDevice((s) => s.copyWith(
          cards: const [],
          tombstones: const [
            TombstoneRecord(id: 'card-1', entityType: 'card', deletedAtMs: 1780000000000),
          ],
        ));

    clock = DateTime.utc(2027, 1, 1);
    await buildRepository().sync();

    final tombstones = await localDataSource.getTombstones();
    expect(tombstones.single.deletedAtMs, 1780000000000);
  });

  test('a local review survives a content edit made on another device', () async {
    // The whole point of the two clocks, proven through the real stack rather
    // than against the merge function directly.
    await localDataSource.saveDeck(deck('deck-1'), kind: WriteKind.content);
    await localDataSource.saveCard(card('card-1'), kind: WriteKind.content);
    await buildRepository().sync();

    clock = DateTime.utc(2026, 8, 1);
    await localDataSource.saveCard(
      card('card-1')
        ..state = 2
        ..intervalDays = 21
        ..reviewCount = 9,
      kind: WriteKind.schedule,
    );

    publishFromAnotherDevice((s) => s.copyWith(
          cards: [
            for (final c in s.cards)
              CardRecord(
                id: c.id,
                createdAtMs: c.createdAtMs,
                deckId: c.deckId,
                front: 'corrected spelling',
                back: c.back,
                contentUpdatedAtMs: DateTime.utc(2026, 9, 1).millisecondsSinceEpoch,
                state: c.state,
                dueDateMs: c.dueDateMs,
                intervalDays: c.intervalDays,
                easeFactor: c.easeFactor,
                learningStepIndex: c.learningStepIndex,
                lapses: c.lapses,
                reviewCount: c.reviewCount,
                scheduleUpdatedAtMs: c.scheduleUpdatedAtMs,
              ),
          ],
        ));

    clock = DateTime.utc(2026, 10, 1);
    await buildRepository().sync();

    final merged = await localDataSource.getCard('card-1');
    expect(merged!.front, 'corrected spelling');
    expect(merged.reviewCount, 9);
    expect(merged.intervalDays, 21);
  });

  test('a clash with another device is retried against the newer copy', () async {
    await localDataSource.saveDeck(deck('deck-1'), kind: WriteKind.content);
    cloud.rejectNextUploads = 1;

    final outcome = await buildRepository().sync();

    expect(cloud.uploadCount, 2);
    expect(outcome, isNotNull);
  });

  test('a remote that keeps changing eventually gives up rather than looping', () async {
    await localDataSource.saveDeck(deck('deck-1'), kind: WriteKind.content);
    cloud.rejectNextUploads = 99;

    expect(buildRepository().sync(), throwsA(isA<RemoteChangedException>()));
  });

  test('syncing without a linked account is refused', () async {
    cloud.account = null;

    expect(buildRepository().sync(), throwsA(isA<NotLinkedException>()));
  });

  test('syncing twice with nothing new reports no changes', () async {
    await localDataSource.saveDeck(deck('deck-1'), kind: WriteKind.content);
    await localDataSource.saveCard(card('card-1'), kind: WriteKind.content);
    await buildRepository().sync();

    final second = await buildRepository().sync();

    expect(second.isUpToDate, isTrue);
  });
}

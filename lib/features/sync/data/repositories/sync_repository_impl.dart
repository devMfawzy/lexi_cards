import '../../../../core/sync/cloud_storage.dart';
import '../../../cards/data/datasources/local_datasource.dart';
import '../../domain/entities/sync_snapshot.dart';
import '../../domain/merge/merge_snapshots.dart';
import '../../domain/repositories/sync_repository.dart';
import '../record_mapper.dart';
import '../sync_snapshot_codec.dart';

class SyncRepositoryImpl implements SyncRepository {
  final LocalDataSource localDataSource;
  final CloudStorage cloudStorage;
  final DateTime Function() _now;

  /// How many times to re-merge when the remote moves underneath us. Each
  /// retry is a full download-merge-upload against the newer remote; more than
  /// a couple means something else is writing continuously, and failing is
  /// better than looping.
  static const _maxAttempts = 3;

  SyncRepositoryImpl({
    required this.localDataSource,
    required this.cloudStorage,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  @override
  Future<SyncOutcome> sync() async {
    if (cloudStorage.currentAccount == null) throw const NotLinkedException();

    for (var attempt = 1; ; attempt++) {
      final nowMs = _now().millisecondsSinceEpoch;
      final local = clampSnapshot(await _readLocal(nowMs), nowMs: nowMs);

      final remote = await cloudStorage.download();
      // Nothing stored yet — merging against an empty snapshot is the
      // identity, so a first sync needs no special case beyond this.
      final remoteSnapshot = remote == null
          ? SyncSnapshot.empty
          : clampSnapshot(SyncSnapshotCodec.decode(remote.bytes), nowMs: nowMs);

      final result = mergeSnapshots(local: local, remote: remoteSnapshot);

      try {
        await cloudStorage.upload(
          SyncSnapshotCodec.encode(result.merged),
          expectedRevision: remote?.revision,
        );
      } on RemoteChangedException {
        // Another device uploaded between our download and our upload. Its
        // work is in the new remote copy, ours is still local, so merging
        // again from scratch loses nothing.
        if (attempt >= _maxAttempts) rethrow;
        continue;
      }

      // Applied only after the upload is accepted. The reverse order would
      // leave the local database ahead of the cloud if the upload failed,
      // which is recoverable but makes "what does the other device have?"
      // harder to reason about.
      await _apply(result);

      return SyncOutcome(
        decksChanged: result.decksToUpsert.length,
        cardsChanged: result.cardsToUpsert.length,
        reviewsAdded: result.logsToInsert.length,
        recordsRemoved: result.deckIdsToDelete.length + result.cardIdsToDelete.length,
      );
    }
  }

  Future<SyncSnapshot> _readLocal(int nowMs) async {
    final decks = await localDataSource.getDecks();
    final cards = await localDataSource.getAllCards();
    final logs = await localDataSource.getAllReviewLogs();
    final tombstones = await localDataSource.getTombstones();

    return SyncSnapshot(
      exportedAtMs: nowMs,
      decks: decks.map(deckToRecord).toList(),
      cards: cards.map(cardToRecord).toList(),
      logs: logs.map(logToRecord).toList(),
      tombstones: tombstones.map(tombstoneToRecord).toList(),
    );
  }

  Future<void> _apply(SyncMergeResult result) => localDataSource.applyMerge(
        tombstones: result.merged.tombstones.map(tombstoneFromRecord).toList(),
        decks: result.decksToUpsert.map(deckFromRecord).toList(),
        cards: result.cardsToUpsert.map(cardFromRecord).toList(),
        logs: result.logsToInsert.map(logFromRecord).toList(),
        deletedCardIds: result.cardIdsToDelete,
        deletedDeckIds: result.deckIdsToDelete,
      );
}

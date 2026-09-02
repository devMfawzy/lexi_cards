import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import '../../cards/domain/entities/flashcard.dart';
import '../../review/domain/entities/rating.dart';
import '../domain/entities/sync_records.dart';
import '../domain/entities/sync_snapshot.dart';

/// The snapshot was written by a newer build than this one.
///
/// Refused rather than merged: fields this build doesn't understand would be
/// dropped on decode and then *deleted* on the next upload, so a newer device
/// would silently lose data every time an older one synced.
class UnsupportedSnapshotVersionException implements Exception {
  final int version;
  const UnsupportedSnapshotVersionException(this.version);

  @override
  String toString() =>
      'Snapshot schema version $version is newer than this app supports '
      '(${SyncSnapshot.currentSchemaVersion}).';
}

/// The payload could not be read at all — truncated, not gzip, not JSON, or
/// missing required fields. Fails loudly and leaves local data untouched
/// rather than merging a half-understood snapshot.
class CorruptSnapshotException implements Exception {
  final Object cause;
  const CorruptSnapshotException(this.cause);

  @override
  String toString() => 'Snapshot could not be read: $cause';
}

/// Converts a [SyncSnapshot] to and from the bytes that live in the cloud.
///
/// Two rules the format depends on:
///
/// **Every timestamp is an integer of epoch milliseconds.** The obvious
/// alternative, `DateTime.toIso8601String()`, emits no offset for a local
/// time, so the receiving device reparses the same text as an instant in *its*
/// zone. Every timestamp would shift on every crossing — which, beyond
/// corrupting due dates and streaks, means syncing twice with no edits keeps
/// changing the data. Merge would stop being idempotent, and idempotence is
/// the property the entire design rests on.
///
/// **Enums travel by name, never by index.** Hive stores `CardState.index`,
/// which silently reinterprets every stored card if the enum is ever
/// reordered. The wire format shouldn't inherit that fragility.
class SyncSnapshotCodec {
  const SyncSnapshotCodec._();

  static Uint8List encode(SyncSnapshot snapshot) =>
      Uint8List.fromList(gzip.encode(utf8.encode(jsonEncode(_toJson(snapshot)))));

  static SyncSnapshot decode(Uint8List bytes) {
    final Map<String, dynamic> json;
    try {
      json = jsonDecode(utf8.decode(gzip.decode(bytes))) as Map<String, dynamic>;
    } catch (e) {
      throw CorruptSnapshotException(e);
    }

    final version = json['schemaVersion'];
    if (version is! int) throw CorruptSnapshotException('missing schemaVersion');
    if (version > SyncSnapshot.currentSchemaVersion) {
      throw UnsupportedSnapshotVersionException(version);
    }

    try {
      return SyncSnapshot(
        schemaVersion: version,
        exportedAtMs: json['exportedAtMs'] as int,
        decks: [for (final d in json['decks'] as List) _deckFrom(d as Map<String, dynamic>)],
        cards: [for (final c in json['cards'] as List) _cardFrom(c as Map<String, dynamic>)],
        logs: [for (final l in json['logs'] as List) _logFrom(l as Map<String, dynamic>)],
        tombstones: [
          for (final t in json['tombstones'] as List) _tombstoneFrom(t as Map<String, dynamic>),
        ],
      );
    } catch (e) {
      throw CorruptSnapshotException(e);
    }
  }

  static Map<String, dynamic> _toJson(SyncSnapshot s) => {
    'schemaVersion': s.schemaVersion,
    'exportedAtMs': s.exportedAtMs,
    'decks': [
      for (final d in s.decks)
        {
          'id': d.id,
          'name': d.name,
          'createdAtMs': d.createdAtMs,
          'contentUpdatedAtMs': d.contentUpdatedAtMs,
        },
    ],
    'cards': [
      for (final c in s.cards)
        {
          'id': c.id,
          'createdAtMs': c.createdAtMs,
          'deckId': c.deckId,
          'front': c.front,
          'back': c.back,
          'contentUpdatedAtMs': c.contentUpdatedAtMs,
          'state': c.state.name,
          'dueDateMs': c.dueDateMs,
          'intervalDays': c.intervalDays,
          'easeFactor': c.easeFactor,
          'learningStepIndex': c.learningStepIndex,
          'lapses': c.lapses,
          'reviewCount': c.reviewCount,
          'scheduleUpdatedAtMs': c.scheduleUpdatedAtMs,
        },
    ],
    'logs': [
      for (final l in s.logs)
        {
          'id': l.id,
          'cardId': l.cardId,
          'reviewedAtMs': l.reviewedAtMs,
          'rating': l.rating.name,
          'previousIntervalDays': l.previousIntervalDays,
          'newIntervalDays': l.newIntervalDays,
          'previousEaseFactor': l.previousEaseFactor,
          'newEaseFactor': l.newEaseFactor,
        },
    ],
    'tombstones': [
      for (final t in s.tombstones)
        {'id': t.id, 'entityType': t.entityType, 'deletedAtMs': t.deletedAtMs},
    ],
  };

  static DeckRecord _deckFrom(Map<String, dynamic> j) => DeckRecord(
    id: j['id'] as String,
    name: j['name'] as String,
    createdAtMs: j['createdAtMs'] as int,
    contentUpdatedAtMs: j['contentUpdatedAtMs'] as int,
  );

  static CardRecord _cardFrom(Map<String, dynamic> j) => CardRecord(
    id: j['id'] as String,
    createdAtMs: j['createdAtMs'] as int,
    deckId: j['deckId'] as String,
    front: j['front'] as String,
    back: j['back'] as String,
    contentUpdatedAtMs: j['contentUpdatedAtMs'] as int,
    state: _enumByName(CardState.values, j['state'], CardState.newCard),
    dueDateMs: j['dueDateMs'] as int,
    intervalDays: j['intervalDays'] as int,
    easeFactor: (j['easeFactor'] as num).toDouble(),
    learningStepIndex: j['learningStepIndex'] as int,
    lapses: j['lapses'] as int,
    reviewCount: j['reviewCount'] as int,
    scheduleUpdatedAtMs: j['scheduleUpdatedAtMs'] as int,
  );

  static LogRecord _logFrom(Map<String, dynamic> j) => LogRecord(
    id: j['id'] as String,
    cardId: j['cardId'] as String,
    reviewedAtMs: j['reviewedAtMs'] as int,
    // A rating this build doesn't know can only come from a newer schema.
    // Keeping the log with a neutral rating loses less than dropping the
    // review outright, which would silently rewrite the user's history.
    rating: _enumByName(Rating.values, j['rating'], Rating.good),
    previousIntervalDays: j['previousIntervalDays'] as int,
    newIntervalDays: j['newIntervalDays'] as int,
    previousEaseFactor: (j['previousEaseFactor'] as num).toDouble(),
    newEaseFactor: (j['newEaseFactor'] as num).toDouble(),
  );

  static TombstoneRecord _tombstoneFrom(Map<String, dynamic> j) => TombstoneRecord(
    id: j['id'] as String,
    entityType: j['entityType'] as String,
    deletedAtMs: j['deletedAtMs'] as int,
  );

  static T _enumByName<T extends Enum>(List<T> values, Object? name, T fallback) =>
      values.firstWhere((v) => v.name == name, orElse: () => fallback);
}

/// How far ahead of the local clock an incoming timestamp may be before it's
/// treated as wrong rather than merely skewed.
const _skewToleranceMs = Duration.millisecondsPerDay;

/// Pulls impossible timestamps back into range, applied to anything arriving
/// from outside before merge sees it.
///
/// Without this, one device with a wrong date — or a user who set the clock
/// forward to skip a due date, which SRS apps see routinely — writes records
/// stamped years ahead. Those records then win *every* merge on *every* device
/// until that date actually arrives, and a future-dated tombstone makes its
/// record permanently unresurrectable.
///
/// Kept separate from the merge so the merge itself needs no notion of "now",
/// which is what makes two devices merging the same pair of snapshots agree
/// regardless of when they do it.
///
/// [CardRecord.dueDateMs] is deliberately untouched: a due date is *supposed*
/// to be in the future, sometimes years out.
SyncSnapshot clampSnapshot(SyncSnapshot snapshot, {required int nowMs}) {
  final ceiling = nowMs + _skewToleranceMs;
  int atMost(int value) => value > ceiling ? nowMs : value;
  int within(int value, int floor) {
    final capped = atMost(value);
    return capped < floor ? floor : capped;
  }

  return snapshot.copyWith(
    decks: [
      for (final d in snapshot.decks)
        d.copyWith(
          createdAtMs: atMost(d.createdAtMs),
          contentUpdatedAtMs: within(d.contentUpdatedAtMs, atMost(d.createdAtMs)),
        ),
    ],
    cards: [
      for (final c in snapshot.cards)
        CardRecord(
          id: c.id,
          createdAtMs: atMost(c.createdAtMs),
          deckId: c.deckId,
          front: c.front,
          back: c.back,
          contentUpdatedAtMs: within(c.contentUpdatedAtMs, atMost(c.createdAtMs)),
          state: c.state,
          dueDateMs: c.dueDateMs,
          intervalDays: c.intervalDays,
          easeFactor: c.easeFactor,
          learningStepIndex: c.learningStepIndex,
          lapses: c.lapses,
          reviewCount: c.reviewCount,
          scheduleUpdatedAtMs: within(c.scheduleUpdatedAtMs, atMost(c.createdAtMs)),
        ),
    ],
    logs: [
      for (final l in snapshot.logs)
        LogRecord(
          id: l.id,
          cardId: l.cardId,
          reviewedAtMs: atMost(l.reviewedAtMs),
          rating: l.rating,
          previousIntervalDays: l.previousIntervalDays,
          newIntervalDays: l.newIntervalDays,
          previousEaseFactor: l.previousEaseFactor,
          newEaseFactor: l.newEaseFactor,
        ),
    ],
    tombstones: [
      for (final t in snapshot.tombstones)
        TombstoneRecord(id: t.id, entityType: t.entityType, deletedAtMs: atMost(t.deletedAtMs)),
    ],
  );
}

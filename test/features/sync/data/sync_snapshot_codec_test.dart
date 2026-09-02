import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:lexi_cards/features/cards/domain/entities/flashcard.dart';
import 'package:lexi_cards/features/review/domain/entities/rating.dart';
import 'package:lexi_cards/features/sync/data/sync_snapshot_codec.dart';
import 'package:lexi_cards/features/sync/domain/entities/sync_records.dart';
import 'package:lexi_cards/features/sync/domain/entities/sync_snapshot.dart';

const _dayMs = Duration.millisecondsPerDay;

CardRecord card(
  String id, {
  int createdAtMs = 1000,
  int contentUpdatedAtMs = 1000,
  int scheduleUpdatedAtMs = 1000,
  int dueDateMs = 1000,
  CardState state = CardState.review,
}) => CardRecord(
  id: id,
  createdAtMs: createdAtMs,
  deckId: 'deck-1',
  front: 'front',
  back: 'back',
  contentUpdatedAtMs: contentUpdatedAtMs,
  state: state,
  dueDateMs: dueDateMs,
  intervalDays: 7,
  easeFactor: 2.5,
  learningStepIndex: 0,
  lapses: 1,
  reviewCount: 4,
  scheduleUpdatedAtMs: scheduleUpdatedAtMs,
);

SyncSnapshot fullSnapshot() => SyncSnapshot(
  exportedAtMs: 12345,
  decks: const [
    DeckRecord(id: 'deck-1', name: 'Español', createdAtMs: 900, contentUpdatedAtMs: 1500),
  ],
  cards: [card('card-1')],
  logs: const [
    LogRecord(
      id: 'log-1',
      cardId: 'card-1',
      reviewedAtMs: 1200,
      rating: Rating.hard,
      previousIntervalDays: 1,
      newIntervalDays: 3,
      previousEaseFactor: 2.5,
      newEaseFactor: 2.35,
    ),
  ],
  tombstones: const [TombstoneRecord(id: 'card-9', entityType: 'card', deletedAtMs: 1400)],
);

Uint8List gzipJson(Map<String, dynamic> json) =>
    Uint8List.fromList(gzip.encode(utf8.encode(jsonEncode(json))));

void main() {
  group('round trip', () {
    test('a snapshot survives encode and decode unchanged', () {
      final original = fullSnapshot();

      expect(SyncSnapshotCodec.decode(SyncSnapshotCodec.encode(original)), original);
    });

    test('non-ascii text survives intact', () {
      final original = fullSnapshot();

      final decoded = SyncSnapshotCodec.decode(SyncSnapshotCodec.encode(original));

      expect(decoded.decks.single.name, 'Español');
    });

    test('an empty snapshot round-trips', () {
      const original = SyncSnapshot(exportedAtMs: 0);

      expect(SyncSnapshotCodec.decode(SyncSnapshotCodec.encode(original)), original);
    });
  });

  group('timestamps', () {
    test('timestamps survive a round trip between devices in different zones', () {
      // The failure this format exists to avoid: an ISO-8601 local time
      // carries no offset, so the other device reparses it in its own zone and
      // every timestamp shifts. Integers can't drift, which is what keeps
      // merging twice with no edits a no-op.
      final original = fullSnapshot();
      final bytes = SyncSnapshotCodec.encode(original);

      final decoded = SyncSnapshotCodec.decode(bytes);

      expect(decoded.cards.single.contentUpdatedAtMs, original.cards.single.contentUpdatedAtMs);
      expect(decoded.logs.single.reviewedAtMs, original.logs.single.reviewedAtMs);
      expect(decoded.tombstones.single.deletedAtMs, original.tombstones.single.deletedAtMs);
    });

    test('every timestamp on the wire is an integer, never a formatted string', () {
      final json =
          jsonDecode(utf8.decode(gzip.decode(SyncSnapshotCodec.encode(fullSnapshot()))))
              as Map<String, dynamic>;

      final cardJson = (json['cards'] as List).single as Map<String, dynamic>;
      expect(cardJson['createdAtMs'], isA<int>());
      expect(cardJson['contentUpdatedAtMs'], isA<int>());
      expect(cardJson['scheduleUpdatedAtMs'], isA<int>());
      expect(cardJson['dueDateMs'], isA<int>());
    });
  });

  group('enums', () {
    test('enums are written by name, not by index', () {
      // Hive stores the index, which silently reinterprets every card if the
      // enum is ever reordered. The wire format must not inherit that.
      final json =
          jsonDecode(utf8.decode(gzip.decode(SyncSnapshotCodec.encode(fullSnapshot()))))
              as Map<String, dynamic>;

      expect(((json['cards'] as List).single as Map)['state'], 'review');
      expect(((json['logs'] as List).single as Map)['rating'], 'hard');
    });

    test('an unknown card state from a newer schema falls back instead of throwing', () {
      final json =
          jsonDecode(utf8.decode(gzip.decode(SyncSnapshotCodec.encode(fullSnapshot()))))
              as Map<String, dynamic>;
      ((json['cards'] as List).single as Map)['state'] = 'suspended';

      final decoded = SyncSnapshotCodec.decode(gzipJson(json));

      expect(decoded.cards.single.state, CardState.newCard);
    });

    test('an unknown rating keeps the log rather than dropping the review', () {
      final json =
          jsonDecode(utf8.decode(gzip.decode(SyncSnapshotCodec.encode(fullSnapshot()))))
              as Map<String, dynamic>;
      ((json['logs'] as List).single as Map)['rating'] = 'skipped';

      final decoded = SyncSnapshotCodec.decode(gzipJson(json));

      expect(decoded.logs, hasLength(1));
      expect(decoded.logs.single.rating, Rating.good);
    });
  });

  group('failure modes', () {
    test('a snapshot from a newer schema is refused outright', () {
      // Decoding it would drop the fields this build doesn't know, and the
      // next upload would then delete them for the newer device too.
      final json =
          jsonDecode(utf8.decode(gzip.decode(SyncSnapshotCodec.encode(fullSnapshot()))))
              as Map<String, dynamic>;
      json['schemaVersion'] = SyncSnapshot.currentSchemaVersion + 1;

      expect(
        () => SyncSnapshotCodec.decode(gzipJson(json)),
        throwsA(isA<UnsupportedSnapshotVersionException>()),
      );
    });

    test('a truncated payload fails loudly rather than half-decoding', () {
      final bytes = SyncSnapshotCodec.encode(fullSnapshot());

      expect(
        () => SyncSnapshotCodec.decode(bytes.sublist(0, bytes.length ~/ 2)),
        throwsA(isA<CorruptSnapshotException>()),
      );
    });

    test('bytes that are not gzip at all are rejected', () {
      expect(
        () => SyncSnapshotCodec.decode(Uint8List.fromList(utf8.encode('not gzip'))),
        throwsA(isA<CorruptSnapshotException>()),
      );
    });

    test('a missing required field is rejected rather than silently defaulted', () {
      final json =
          jsonDecode(utf8.decode(gzip.decode(SyncSnapshotCodec.encode(fullSnapshot()))))
              as Map<String, dynamic>;
      ((json['cards'] as List).single as Map).remove('reviewCount');

      expect(
        () => SyncSnapshotCodec.decode(gzipJson(json)),
        throwsA(isA<CorruptSnapshotException>()),
      );
    });
  });

  group('clamping hostile clocks', () {
    const now = 1000000;

    test('a timestamp far in the future is pulled back to now', () {
      // Otherwise one device with a wrong date wins every merge on every
      // device until that date actually arrives.
      final snapshot = SyncSnapshot(
        exportedAtMs: now,
        cards: [card('card-1', contentUpdatedAtMs: now + 400 * _dayMs)],
      );

      final clamped = clampSnapshot(snapshot, nowMs: now);

      expect(clamped.cards.single.contentUpdatedAtMs, now);
    });

    test('a future-dated tombstone cannot suppress a record forever', () {
      final snapshot = SyncSnapshot(
        exportedAtMs: now,
        tombstones: [
          TombstoneRecord(id: 'card-1', entityType: 'card', deletedAtMs: now + 400 * _dayMs),
        ],
      );

      expect(clampSnapshot(snapshot, nowMs: now).tombstones.single.deletedAtMs, now);
    });

    test('a review dated in the future cannot inflate a streak', () {
      final snapshot = SyncSnapshot(
        exportedAtMs: now,
        logs: [
          LogRecord(
            id: 'log-1',
            cardId: 'card-1',
            reviewedAtMs: now + 400 * _dayMs,
            rating: Rating.good,
            previousIntervalDays: 1,
            newIntervalDays: 3,
            previousEaseFactor: 2.5,
            newEaseFactor: 2.5,
          ),
        ],
      );

      expect(clampSnapshot(snapshot, nowMs: now).logs.single.reviewedAtMs, now);
    });

    test('a modification earlier than creation is lifted to creation', () {
      final snapshot = SyncSnapshot(
        exportedAtMs: now,
        cards: [card('card-1', createdAtMs: 5000, contentUpdatedAtMs: 100)],
      );

      expect(clampSnapshot(snapshot, nowMs: now).cards.single.contentUpdatedAtMs, 5000);
    });

    test('a due date in the future is left alone', () {
      // Due dates are supposed to be ahead of now — sometimes years, since the
      // scheduler caps intervals at a hundred years rather than at today.
      final snapshot = SyncSnapshot(
        exportedAtMs: now,
        cards: [card('card-1', dueDateMs: now + 400 * _dayMs)],
      );

      expect(clampSnapshot(snapshot, nowMs: now).cards.single.dueDateMs, now + 400 * _dayMs);
    });

    test('ordinary timestamps within tolerance are untouched', () {
      final snapshot = SyncSnapshot(exportedAtMs: now, cards: [card('card-1')]);

      expect(clampSnapshot(snapshot, nowMs: now), snapshot);
    });
  });
}

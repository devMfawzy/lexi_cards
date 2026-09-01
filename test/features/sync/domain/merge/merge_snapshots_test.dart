import 'package:flutter_test/flutter_test.dart';

import 'package:lexi_cards/features/cards/domain/entities/flashcard.dart';
import 'package:lexi_cards/features/review/domain/entities/rating.dart';
import 'package:lexi_cards/features/sync/domain/entities/sync_records.dart';
import 'package:lexi_cards/features/sync/domain/entities/sync_snapshot.dart';
import 'package:lexi_cards/features/sync/domain/merge/merge_snapshots.dart';

DeckRecord deck(
  String id, {
  String name = 'Spanish',
  int createdAtMs = 1000,
  int contentUpdatedAtMs = 1000,
}) =>
    DeckRecord(
      id: id,
      name: name,
      createdAtMs: createdAtMs,
      contentUpdatedAtMs: contentUpdatedAtMs,
    );

CardRecord card(
  String id, {
  String deckId = 'deck-1',
  String front = 'front',
  String back = 'back',
  int createdAtMs = 1000,
  CardState state = CardState.newCard,
  int dueDateMs = 1000,
  int intervalDays = 0,
  double easeFactor = 2.5,
  int learningStepIndex = 0,
  int lapses = 0,
  int reviewCount = 0,
  int contentUpdatedAtMs = 1000,
  int scheduleUpdatedAtMs = 1000,
}) =>
    CardRecord(
      id: id,
      createdAtMs: createdAtMs,
      deckId: deckId,
      front: front,
      back: back,
      contentUpdatedAtMs: contentUpdatedAtMs,
      state: state,
      dueDateMs: dueDateMs,
      intervalDays: intervalDays,
      easeFactor: easeFactor,
      learningStepIndex: learningStepIndex,
      lapses: lapses,
      reviewCount: reviewCount,
      scheduleUpdatedAtMs: scheduleUpdatedAtMs,
    );

LogRecord log(String id, {String cardId = 'card-1', int reviewedAtMs = 1000}) => LogRecord(
      id: id,
      cardId: cardId,
      reviewedAtMs: reviewedAtMs,
      rating: Rating.good,
      previousIntervalDays: 1,
      newIntervalDays: 3,
      previousEaseFactor: 2.5,
      newEaseFactor: 2.5,
    );

TombstoneRecord deckGone(String id, int at) =>
    TombstoneRecord(id: id, entityType: 'deck', deletedAtMs: at);

TombstoneRecord cardGone(String id, int at) =>
    TombstoneRecord(id: id, entityType: 'card', deletedAtMs: at);

/// Includes `deck-1` by default, since a card can never survive without the
/// deck it points at.
SyncSnapshot snapshot({
  List<DeckRecord>? decks,
  List<CardRecord> cards = const [],
  List<LogRecord> logs = const [],
  List<TombstoneRecord> tombstones = const [],
  int exportedAtMs = 5000,
}) =>
    SyncSnapshot(
      exportedAtMs: exportedAtMs,
      decks: decks ?? [deck('deck-1')],
      cards: cards,
      logs: logs,
      tombstones: tombstones,
    );

void main() {
  group('algebraic properties', () {
    test('merging a snapshot with itself returns it unchanged', () {
      final only = snapshot(cards: [card('card-1')], logs: [log('log-1')]);

      final result = mergeSnapshots(local: only, remote: only);

      expect(result.merged.decks, only.decks);
      expect(result.merged.cards, only.cards);
      expect(result.merged.logs, only.logs);
      expect(result.changedLocally, isFalse);
    });

    test('merging A into B gives the same answer as merging B into A', () {
      final a = snapshot(
        cards: [card('card-1', front: 'from A', contentUpdatedAtMs: 3000)],
        logs: [log('log-a')],
        tombstones: [cardGone('card-9', 2000)],
      );
      final b = snapshot(
        cards: [card('card-1', front: 'from B', contentUpdatedAtMs: 2000)],
        logs: [log('log-b')],
      );

      expect(
        mergeSnapshots(local: a, remote: b).merged,
        mergeSnapshots(local: b, remote: a).merged,
      );
    });

    test('merging twice in a row changes nothing the second time', () {
      // Idempotence is the property everything else rests on: without it, two
      // devices left alone would keep rewriting each other forever.
      final a = snapshot(cards: [card('card-1', reviewCount: 2, scheduleUpdatedAtMs: 4000)]);
      final b = snapshot(cards: [card('card-1', front: 'edited', contentUpdatedAtMs: 6000)]);

      final once = mergeSnapshots(local: a, remote: b).merged;
      final twice = mergeSnapshots(local: once, remote: once);

      expect(twice.merged, once);
      expect(twice.changedLocally, isFalse);
    });

    test('merging three snapshots reaches the same state in any order', () {
      final a = snapshot(cards: [card('card-1', front: 'a', contentUpdatedAtMs: 1000)]);
      final b = snapshot(cards: [card('card-1', front: 'b', contentUpdatedAtMs: 2000)]);
      final c = snapshot(cards: [card('card-1', front: 'c', contentUpdatedAtMs: 3000)]);

      SyncSnapshot mergeAll(List<SyncSnapshot> all) => all.reduce(
            (x, y) => mergeSnapshots(local: x, remote: y).merged,
          );

      expect(mergeAll([a, b, c]), mergeAll([c, a, b]));
      expect(mergeAll([a, b, c]), mergeAll([b, c, a]));
    });
  });

  group('decks', () {
    test('a deck only on the remote is added, one only on the local is kept', () {
      final local = snapshot(decks: [deck('deck-1')]);
      final remote = snapshot(decks: [deck('deck-2')]);

      final merged = mergeSnapshots(local: local, remote: remote).merged;

      expect(merged.decks.map((d) => d.id), ['deck-1', 'deck-2']);
    });

    test('the deck with the later clock wins the name', () {
      final local = snapshot(decks: [deck('deck-1', name: 'Old', contentUpdatedAtMs: 1000)]);
      final remote = snapshot(decks: [deck('deck-1', name: 'New', contentUpdatedAtMs: 2000)]);

      final merged = mergeSnapshots(local: local, remote: remote).merged;

      expect(merged.decks.single.name, 'New');
    });

    test('equal clocks resolve to the same winner whichever side is local', () {
      final local = snapshot(decks: [deck('deck-1', name: 'Alpha', contentUpdatedAtMs: 1000)]);
      final remote = snapshot(decks: [deck('deck-1', name: 'Beta', contentUpdatedAtMs: 1000)]);

      expect(
        mergeSnapshots(local: local, remote: remote).merged.decks.single,
        mergeSnapshots(local: remote, remote: local).merged.decks.single,
      );
    });

    test('createdAt takes the earlier of the two, not the winner\'s', () {
      final local = snapshot(decks: [deck('deck-1', createdAtMs: 500, contentUpdatedAtMs: 1000)]);
      final remote = snapshot(decks: [deck('deck-1', createdAtMs: 900, contentUpdatedAtMs: 9000)]);

      final merged = mergeSnapshots(local: local, remote: remote).merged;

      expect(merged.decks.single.createdAtMs, 500);
    });
  });

  group('cards — the two lanes', () {
    test('a content edit does not roll back a newer review', () {
      // The failure the whole two-clock design exists to prevent.
      final reviewed = snapshot(cards: [
        card('card-1',
            state: CardState.review,
            intervalDays: 15,
            reviewCount: 8,
            scheduleUpdatedAtMs: 5000),
      ]);
      final edited = snapshot(cards: [
        card('card-1',
            front: 'typo fixed',
            contentUpdatedAtMs: 9000,
            intervalDays: 6,
            reviewCount: 7,
            scheduleUpdatedAtMs: 1000),
      ]);

      final merged = mergeSnapshots(local: reviewed, remote: edited).merged;

      expect(merged.cards.single.front, 'typo fixed');
      expect(merged.cards.single.intervalDays, 15);
      expect(merged.cards.single.reviewCount, 8);
      expect(merged.cards.single.state, CardState.review);
    });

    test('a review does not revert a newer content edit', () {
      final edited = snapshot(cards: [
        card('card-1', front: 'typo fixed', contentUpdatedAtMs: 9000, reviewCount: 1),
      ]);
      final reviewed = snapshot(cards: [
        card('card-1', front: 'stale', contentUpdatedAtMs: 1000, reviewCount: 5,
            intervalDays: 20, scheduleUpdatedAtMs: 9500),
      ]);

      final merged = mergeSnapshots(local: edited, remote: reviewed).merged;

      expect(merged.cards.single.front, 'typo fixed');
      expect(merged.cards.single.reviewCount, 5);
      expect(merged.cards.single.intervalDays, 20);
    });

    test('the whole scheduling lane moves together, never field by field', () {
      final a = snapshot(cards: [
        card('card-1',
            state: CardState.review,
            dueDateMs: 8000,
            intervalDays: 30,
            easeFactor: 2.9,
            learningStepIndex: 0,
            lapses: 1,
            reviewCount: 12,
            scheduleUpdatedAtMs: 7000),
      ]);
      final b = snapshot(cards: [
        card('card-1',
            state: CardState.learning,
            dueDateMs: 2000,
            intervalDays: 1,
            easeFactor: 1.9,
            learningStepIndex: 1,
            lapses: 4,
            reviewCount: 3,
            scheduleUpdatedAtMs: 9999),
      ]);

      final winner = mergeSnapshots(local: a, remote: b).merged.cards.single;

      expect(winner.reviewCount, 12);
      expect(winner.state, CardState.review);
      expect(winner.dueDateMs, 8000);
      expect(winner.intervalDays, 30);
      expect(winner.easeFactor, 2.9);
      expect(winner.lapses, 1);
    });

    test('the side with more reviews wins scheduling even with an older clock', () {
      // reviewCount is a logical clock the scheduler already maintains, so a
      // device with a badly wrong wall clock cannot win a scheduling conflict.
      final moreReviews = snapshot(cards: [
        card('card-1', reviewCount: 9, intervalDays: 40, scheduleUpdatedAtMs: 100),
      ]);
      final wrongClock = snapshot(cards: [
        card('card-1', reviewCount: 2, intervalDays: 3, scheduleUpdatedAtMs: 99999999),
      ]);

      final merged = mergeSnapshots(local: moreReviews, remote: wrongClock).merged;

      expect(merged.cards.single.reviewCount, 9);
      expect(merged.cards.single.intervalDays, 40);
    });

    test('reviewCount never decreases across a merge', () {
      final a = snapshot(cards: [card('card-1', reviewCount: 6)]);
      final b = snapshot(cards: [card('card-1', reviewCount: 2, scheduleUpdatedAtMs: 9999)]);

      final merged = mergeSnapshots(local: a, remote: b).merged;

      expect(merged.cards.single.reviewCount, greaterThanOrEqualTo(6));
    });

    test('front and back always come from the same side', () {
      final a = snapshot(cards: [
        card('card-1', front: 'Q old', back: 'A old', contentUpdatedAtMs: 1000),
      ]);
      final b = snapshot(cards: [
        card('card-1', front: 'Q new', back: 'A new', contentUpdatedAtMs: 2000),
      ]);

      final merged = mergeSnapshots(local: a, remote: b).merged;

      expect(merged.cards.single.front, 'Q new');
      expect(merged.cards.single.back, 'A new');
    });
  });

  group('deletion', () {
    test('a card deleted on one side is deleted on the other', () {
      final local = snapshot(cards: [card('card-1')]);
      final remote = snapshot(cards: [], tombstones: [cardGone('card-1', 5000)]);

      final result = mergeSnapshots(local: local, remote: remote);

      expect(result.merged.cards, isEmpty);
      expect(result.cardIdsToDelete, ['card-1']);
    });

    test('a card edited after it was deleted elsewhere is resurrected', () {
      final edited = snapshot(cards: [card('card-1', front: 'still wanted', contentUpdatedAtMs: 9000)]);
      final deleted = snapshot(cards: [], tombstones: [cardGone('card-1', 5000)]);

      final merged = mergeSnapshots(local: edited, remote: deleted).merged;

      expect(merged.cards.single.front, 'still wanted');
    });

    test('a card reviewed after it was deleted elsewhere stays deleted', () {
      // Cards are rated from a queue loaded before the delete happened, so
      // letting a review resurrect them would make deletes impossible to make
      // stick while studying on another device.
      final reviewed = snapshot(cards: [
        card('card-1', contentUpdatedAtMs: 1000, reviewCount: 4, scheduleUpdatedAtMs: 9000),
      ]);
      final deleted = snapshot(cards: [], tombstones: [cardGone('card-1', 5000)]);

      expect(mergeSnapshots(local: reviewed, remote: deleted).merged.cards, isEmpty);
    });

    test('a delete wins a tie against an edit at the same instant', () {
      final edited = snapshot(cards: [card('card-1', contentUpdatedAtMs: 5000)]);
      final deleted = snapshot(cards: [], tombstones: [cardGone('card-1', 5000)]);

      expect(mergeSnapshots(local: edited, remote: deleted).merged.cards, isEmpty);
    });

    test('deleting a deck also removes its cards on the other device', () {
      final hasCards = snapshot(
        decks: [deck('deck-1')],
        cards: [card('card-1'), card('card-2')],
      );
      final deletedDeck = snapshot(decks: [], tombstones: [deckGone('deck-1', 5000)]);

      final result = mergeSnapshots(local: hasCards, remote: deletedDeck);

      expect(result.merged.decks, isEmpty);
      expect(result.merged.cards, isEmpty);
      expect(result.deckIdsToDelete, ['deck-1']);
      expect(result.cardIdsToDelete, ['card-1', 'card-2']);
    });

    test('a card edited elsewhere still dies with its deck', () {
      // It costs that edit — but a card outliving its deck belongs to nothing,
      // appears on no deck page, and would still be served by "study all".
      final edited = snapshot(
        decks: [deck('deck-1')],
        cards: [card('card-1', front: 'edited late', contentUpdatedAtMs: 9999)],
      );
      final deletedDeck = snapshot(decks: [], tombstones: [deckGone('deck-1', 5000)]);

      expect(mergeSnapshots(local: edited, remote: deletedDeck).merged.cards, isEmpty);
    });

    test('a card moved out of a deck survives that deck being deleted', () {
      final moved = snapshot(
        decks: [deck('deck-1'), deck('deck-2')],
        cards: [card('card-1', deckId: 'deck-2', contentUpdatedAtMs: 9000)],
      );
      final deletedDeck = snapshot(
        decks: [deck('deck-2')],
        cards: [card('card-1', deckId: 'deck-1', contentUpdatedAtMs: 1000)],
        tombstones: [deckGone('deck-1', 5000)],
      );

      final merged = mergeSnapshots(local: moved, remote: deletedDeck).merged;

      expect(merged.cards.single.deckId, 'deck-2');
    });

    test('no surviving card references a deck that did not survive', () {
      final orphaning = snapshot(
        decks: [deck('deck-1')],
        cards: [card('card-1'), card('stray', deckId: 'deck-missing')],
      );

      final merged = mergeSnapshots(local: orphaning, remote: SyncSnapshot.empty).merged;

      final deckIds = merged.decks.map((d) => d.id).toSet();
      for (final survivor in merged.cards) {
        expect(deckIds, contains(survivor.deckId));
      }
    });

    test('deleting on both sides keeps one tombstone at the later time', () {
      final a = snapshot(tombstones: [cardGone('card-1', 3000)]);
      final b = snapshot(tombstones: [cardGone('card-1', 7000)]);

      final merged = mergeSnapshots(local: a, remote: b).merged;

      expect(merged.tombstones, hasLength(1));
      expect(merged.tombstones.single.deletedAtMs, 7000);
    });

    test('tombstones are retained rather than aged out', () {
      // Dropping them after some age is unsound at any age: a device offline
      // longer than the window would resurrect everything it had deleted.
      final ancient = snapshot(tombstones: [cardGone('card-1', 1)]);

      final merged = mergeSnapshots(local: ancient, remote: SyncSnapshot.empty).merged;

      expect(merged.tombstones, hasLength(1));
    });
  });

  group('review logs', () {
    test('logs from both sides are unioned', () {
      final a = snapshot(logs: [log('log-1'), log('log-2')]);
      final b = snapshot(logs: [log('log-3')]);

      final merged = mergeSnapshots(local: a, remote: b).merged;

      expect(merged.logs.map((l) => l.id), ['log-1', 'log-2', 'log-3']);
    });

    test('the same log id on both sides appears once', () {
      final a = snapshot(logs: [log('log-1')]);
      final b = snapshot(logs: [log('log-1')]);

      expect(mergeSnapshots(local: a, remote: b).merged.logs, hasLength(1));
    });

    test('both devices keep their review even when one loses the scheduling', () {
      // The redeeming property of scheduling conflicts: the card can only take
      // one side's schedule, but neither review disappears, so streaks and
      // retention stay complete.
      final a = snapshot(
        cards: [card('card-1', reviewCount: 5, scheduleUpdatedAtMs: 9000)],
        logs: [log('log-a', reviewedAtMs: 9000)],
      );
      final b = snapshot(
        cards: [card('card-1', reviewCount: 2, scheduleUpdatedAtMs: 3000)],
        logs: [log('log-b', reviewedAtMs: 3000)],
      );

      final merged = mergeSnapshots(local: a, remote: b).merged;

      expect(merged.cards.single.reviewCount, 5);
      expect(merged.logs.map((l) => l.id), ['log-a', 'log-b']);
    });

    test('a log whose card was deleted is retained', () {
      final a = snapshot(cards: [], logs: [log('log-1', cardId: 'gone')],
          tombstones: [cardGone('gone', 5000)]);

      expect(mergeSnapshots(local: a, remote: SyncSnapshot.empty).merged.logs, hasLength(1));
    });
  });

  group('what to write locally', () {
    test('an unchanged record is not queued for a local write', () {
      // Hive appends a frame per put and only compacts on deletes, so blindly
      // rewriting every card would grow the database and never reclaim it.
      final same = snapshot(cards: [card('card-1')]);

      final result = mergeSnapshots(local: same, remote: same);

      expect(result.cardsToUpsert, isEmpty);
      expect(result.decksToUpsert, isEmpty);
      expect(result.changedLocally, isFalse);
    });

    test('only the records that actually differ are queued', () {
      final local = snapshot(cards: [card('card-1'), card('card-2')]);
      final remote = snapshot(cards: [
        card('card-1'),
        card('card-2', front: 'changed', contentUpdatedAtMs: 9000),
      ]);

      final result = mergeSnapshots(local: local, remote: remote);

      expect(result.cardsToUpsert.map((c) => c.id), ['card-2']);
    });

    test('a first sync against an empty remote uploads everything and writes nothing', () {
      final local = snapshot(cards: [card('card-1')], logs: [log('log-1')]);

      final result = mergeSnapshots(local: local, remote: SyncSnapshot.empty);

      expect(result.merged.cards, hasLength(1));
      expect(result.merged.logs, hasLength(1));
      expect(result.changedLocally, isFalse);
    });
  });
}

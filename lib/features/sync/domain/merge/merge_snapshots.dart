import '../entities/sync_records.dart';
import '../entities/sync_snapshot.dart';

/// What a merge produced: the state both devices should converge on, plus the
/// subset of it the local database doesn't already match.
///
/// The local diff matters for more than speed. Hive appends a new frame on
/// every `put` and only compacts in response to *deletes*, so re-writing every
/// card on every sync would grow the database without bound and never reclaim
/// any of it.
class SyncMergeResult {
  /// The merged state — what to upload, and what both devices end up with.
  final SyncSnapshot merged;

  final List<DeckRecord> decksToUpsert;
  final List<CardRecord> cardsToUpsert;
  final List<LogRecord> logsToInsert;
  final List<String> deckIdsToDelete;
  final List<String> cardIdsToDelete;

  const SyncMergeResult({
    required this.merged,
    required this.decksToUpsert,
    required this.cardsToUpsert,
    required this.logsToInsert,
    required this.deckIdsToDelete,
    required this.cardIdsToDelete,
  });

  bool get changedLocally =>
      decksToUpsert.isNotEmpty ||
      cardsToUpsert.isNotEmpty ||
      logsToInsert.isNotEmpty ||
      deckIdsToDelete.isNotEmpty ||
      cardIdsToDelete.isNotEmpty;
}

/// Reconciles two snapshots into the single state both devices should hold.
///
/// Last-write-wins, with three refinements that ordinary record-level LWW gets
/// wrong for this app:
///
/// 1. **A card has two independent clocks.** Editing a card and reviewing it
///    are different acts, and both are real. Whole-record LWW would have to
///    discard one of them — silently rolling back a review because the other
///    device fixed a typo, or reverting the typo fix because the other device
///    reviewed. Each lane is resolved separately and moved as a whole.
///
/// 2. **Scheduling is ordered by `reviewCount`, not by the clock.** The
///    scheduler increments it exactly once per review, which makes it a
///    logical clock the app already maintains — and one that a wrong device
///    clock can't corrupt. The timestamp is only a tiebreak.
///
/// 3. **Deleting a deck deletes its cards, unconditionally.** Card removal is
///    derived from the deck's tombstone rather than recorded per card, so a
///    card edited concurrently on another device can't outlive its own deck.
///
/// Deliberately takes no `now`. Nothing here depends on the current time, so
/// two devices merging the same pair of snapshots reach the same answer no
/// matter when they do it — convergence is structural rather than something a
/// test has to keep honest. Defending against hostile timestamps is
/// [clampSnapshot]'s job, applied on the way in.
SyncMergeResult mergeSnapshots({
  required SyncSnapshot local,
  required SyncSnapshot remote,
}) {
  final tombstones = _mergeTombstones(local.tombstones, remote.tombstones);
  final deckTombstones = {
    for (final t in tombstones.where((t) => t.entityType == _deckType)) t.id: t,
  };
  final cardTombstones = {
    for (final t in tombstones.where((t) => t.entityType == _cardType)) t.id: t,
  };

  final decks = _mergeDecks(local.decks, remote.decks, deckTombstones);
  final survivingDeckIds = {for (final d in decks) d.id};
  final cards = _mergeCards(
    local.cards,
    remote.cards,
    cardTombstones,
    deckTombstones,
    survivingDeckIds,
  );
  final logs = _mergeLogs(local.logs, remote.logs);

  final merged = SyncSnapshot(
    exportedAtMs: local.exportedAtMs > remote.exportedAtMs
        ? local.exportedAtMs
        : remote.exportedAtMs,
    decks: decks,
    cards: cards,
    logs: logs,
    tombstones: tombstones,
  );

  final localDecks = {for (final d in local.decks) d.id: d};
  final localCards = {for (final c in local.cards) c.id: c};
  final localLogIds = {for (final l in local.logs) l.id};

  return SyncMergeResult(
    merged: merged,
    decksToUpsert: [
      for (final deck in decks)
        if (localDecks[deck.id] != deck) deck,
    ],
    cardsToUpsert: [
      for (final card in cards)
        if (localCards[card.id] != card) card,
    ],
    logsToInsert: [
      for (final log in logs)
        if (!localLogIds.contains(log.id)) log,
    ],
    deckIdsToDelete: [
      for (final id in localDecks.keys)
        if (!survivingDeckIds.contains(id)) id,
    ],
    cardIdsToDelete: [
      for (final id in localCards.keys)
        if (!cards.any((c) => c.id == id)) id,
    ],
  );
}

const _deckType = 'deck';
const _cardType = 'card';

List<TombstoneRecord> _mergeTombstones(
  List<TombstoneRecord> local,
  List<TombstoneRecord> remote,
) {
  final byKey = <String, TombstoneRecord>{};
  for (final tombstone in [...local, ...remote]) {
    final existing = byKey[tombstone.key];
    // A record can be deleted on both devices; keep the later deletion so the
    // window in which an edit could resurrect it is the narrower one.
    if (existing == null || tombstone.deletedAtMs > existing.deletedAtMs) {
      byKey[tombstone.key] = tombstone;
    }
  }
  // Never garbage-collected. Dropping a tombstone after some age is unsound at
  // any age: a device that was offline longer than the window still holds the
  // record, and would silently resurrect everything it had deleted. They cost
  // a few dozen bytes each, against a snapshot whose cards are measured in
  // megabytes, so there is nothing to reclaim by trying.
  return _sortedById(byKey.values.toList());
}

List<DeckRecord> _mergeDecks(
  List<DeckRecord> local,
  List<DeckRecord> remote,
  Map<String, TombstoneRecord> deckTombstones,
) {
  final merged = <DeckRecord>[];
  for (final id in _allIds(local.map((d) => d.id), remote.map((d) => d.id))) {
    final a = local.where((d) => d.id == id).firstOrNull;
    final b = remote.where((d) => d.id == id).firstOrNull;
    final winner = _pick(a, b, (d) => d.contentUpdatedAtMs, _deckFingerprint);
    if (winner == null) continue;

    final deck = winner.copyWith(createdAtMs: _earliest(a?.createdAtMs, b?.createdAtMs));
    // A deletion wins ties, so resurrecting a deck takes an edit that is
    // strictly newer than the delete rather than merely simultaneous with it.
    final tombstone = deckTombstones[id];
    if (tombstone != null && tombstone.deletedAtMs >= deck.contentUpdatedAtMs) continue;
    merged.add(deck);
  }
  return _sortedById(merged);
}

List<CardRecord> _mergeCards(
  List<CardRecord> local,
  List<CardRecord> remote,
  Map<String, TombstoneRecord> cardTombstones,
  Map<String, TombstoneRecord> deckTombstones,
  Set<String> survivingDeckIds,
) {
  final merged = <CardRecord>[];
  for (final id in _allIds(local.map((c) => c.id), remote.map((c) => c.id))) {
    final a = local.where((c) => c.id == id).firstOrNull;
    final b = remote.where((c) => c.id == id).firstOrNull;

    final content = _pick(a, b, (c) => c.contentUpdatedAtMs, _cardFingerprint);
    final schedule = _pickSchedule(a, b);
    if (content == null || schedule == null) continue;

    final card = CardRecord.fromLanes(
      content: content,
      schedule: schedule,
      createdAtMs: _earliest(a?.createdAtMs, b?.createdAtMs),
    );

    // Resurrection is content-only. A *review* arriving after a delete must
    // not undo it: cards are rated from a queue loaded before the delete
    // happened, so otherwise the user could tidy up a deck on one device and
    // watch the card reappear simply because they were studying on the other.
    final tombstone = cardTombstones[id];
    if (tombstone != null && tombstone.deletedAtMs >= card.contentUpdatedAtMs) continue;

    // Its deck was deleted. Unconditional, and it costs a concurrent edit to
    // this card — but the alternative is worse: a card that outlives its deck
    // belongs to nothing, shows up on no deck's page, and yet still appears in
    // "study all decks" and in the stats totals, with no way to reach it. Note
    // this tests the *merged* deckId, so a card moved to another deck on the
    // other device escapes its old deck's deletion.
    if (deckTombstones.containsKey(card.deckId)) continue;

    // Belt and braces on the same invariant: nothing may survive pointing at a
    // deck that didn't.
    if (!survivingDeckIds.contains(card.deckId)) continue;

    merged.add(card);
  }
  return _sortedById(merged);
}

/// Union by id. Reviews are immutable once written, so two devices can never
/// disagree about one — which means no review is ever lost to a conflict, even
/// when the card's scheduling from that same review is.
List<LogRecord> _mergeLogs(List<LogRecord> local, List<LogRecord> remote) {
  final byId = <String, LogRecord>{};
  for (final log in [...local, ...remote]) {
    byId.putIfAbsent(log.id, () => log);
  }
  return _sortedById(byId.values.toList(), (l) => l.id);
}

/// Picks the record with the greater clock, falling back to a stable
/// fingerprint so that a tie resolves the same way on both devices — otherwise
/// the two would disagree forever, each preferring its own copy.
T? _pick<T>(T? a, T? b, int Function(T) clock, String Function(T) fingerprint) {
  if (a == null) return b;
  if (b == null) return a;
  if (clock(a) != clock(b)) return clock(a) > clock(b) ? a : b;
  return fingerprint(a).compareTo(fingerprint(b)) <= 0 ? a : b;
}

/// Scheduling is ordered by `reviewCount` first. The scheduler increments it
/// exactly once per review, so more reviews is unambiguously later — no
/// appeal to wall-clock time, and therefore nothing a wrong device clock can
/// corrupt. The timestamp only breaks a tie between equal counts.
CardRecord? _pickSchedule(CardRecord? a, CardRecord? b) {
  if (a == null) return b;
  if (b == null) return a;
  if (a.reviewCount != b.reviewCount) return a.reviewCount > b.reviewCount ? a : b;
  return _pick(a, b, (c) => c.scheduleUpdatedAtMs, _cardFingerprint);
}

/// Creation time is the earlier of the two, never the winner's. Letting it
/// move would reshuffle the order new cards are introduced in, which is
/// ordered by creation — and it would do so differently on each device.
int _earliest(int? a, int? b) {
  if (a == null) return b!;
  if (b == null) return a;
  return a < b ? a : b;
}

Iterable<String> _allIds(Iterable<String> a, Iterable<String> b) =>
    {...a, ...b}.toList()..sort();

List<T> _sortedById<T>(List<T> records, [String Function(T)? id]) {
  String keyOf(T record) {
    if (id != null) return id(record);
    if (record is DeckRecord) return record.id;
    if (record is CardRecord) return record.id;
    if (record is TombstoneRecord) return record.key;
    return '';
  }

  return records..sort((a, b) => keyOf(a).compareTo(keyOf(b)));
}

String _deckFingerprint(DeckRecord deck) => _stableHash('${deck.id} ${deck.name}');

String _cardFingerprint(CardRecord card) => _stableHash(
      '${card.id} ${card.deckId} ${card.front} ${card.back}'
      ' ${card.state.name} ${card.dueDateMs} ${card.intervalDays}'
      ' ${card.easeFactor} ${card.reviewCount}',
    );

/// FNV-1a. Dart's own `hashCode` is not guaranteed stable across VM versions
/// or platforms, and a tiebreak that differs between two devices is worse than
/// no tiebreak at all — they would each keep their own copy indefinitely.
String _stableHash(String input) {
  var hash = 0xcbf29ce484222325;
  const mask = 0xFFFFFFFFFFFFFFFF;
  for (final unit in input.codeUnits) {
    hash = (hash ^ unit) & mask;
    hash = (hash * 0x100000001b3) & mask;
  }
  return hash.toRadixString(16).padLeft(16, '0');
}

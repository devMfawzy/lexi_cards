import '../entities/sync_records.dart';
import '../entities/sync_snapshot.dart';

/// The state both devices should converge on, plus the subset of it the local
/// database doesn't already match.
///
/// The local diff isn't only an optimisation: Hive appends a frame per `put`
/// and compacts only on deletes, so rewriting every card each sync would grow
/// the box without bound.
class SyncMergeResult {
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

/// Reconciles two snapshots. Last-write-wins, with three refinements:
///
/// 1. A card has two clocks, content and scheduling, resolved separately. With
///    one clock a merge must discard either the review or the edit whenever
///    both happened before a sync.
/// 2. Scheduling is ordered by `reviewCount` first — a logical clock the
///    scheduler already maintains, and one a wrong device clock can't corrupt.
/// 3. Deleting a deck deletes its cards unconditionally, derived from the
///    deck's tombstone, so a card can't outlive its deck.
///
/// Takes no `now`: nothing here depends on the current time, so two devices
/// merging the same pair agree whenever they run it. Clamping hostile
/// timestamps is [clampSnapshot]'s job, applied on the way in.
SyncMergeResult mergeSnapshots({required SyncSnapshot local, required SyncSnapshot remote}) {
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

/// Union by key, keeping the later deletion. Never garbage-collected: a device
/// offline longer than any expiry window would resurrect everything it deleted.
List<TombstoneRecord> _mergeTombstones(List<TombstoneRecord> local, List<TombstoneRecord> remote) {
  final byKey = <String, TombstoneRecord>{};
  for (final tombstone in [...local, ...remote]) {
    final existing = byKey[tombstone.key];
    if (existing == null || tombstone.deletedAtMs > existing.deletedAtMs) {
      byKey[tombstone.key] = tombstone;
    }
  }
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
    // Deletion wins ties, so resurrecting takes a strictly newer edit.
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

    // Resurrection is content-only. Cards are rated from a queue loaded before
    // the delete, so a review must not undo it.
    final tombstone = cardTombstones[id];
    if (tombstone != null && tombstone.deletedAtMs >= card.contentUpdatedAtMs) continue;

    // Its deck was deleted. Tested against the *merged* deckId, so a card moved
    // elsewhere escapes. Costs a concurrent edit, but a card outliving its deck
    // is unreachable while still appearing in "study all" and the stats.
    if (deckTombstones.containsKey(card.deckId)) continue;
    if (!survivingDeckIds.contains(card.deckId)) continue;

    merged.add(card);
  }
  return _sortedById(merged);
}

/// Union by id. Reviews are immutable, so they never conflict — which is why a
/// scheduling clash still keeps both devices' review history.
List<LogRecord> _mergeLogs(List<LogRecord> local, List<LogRecord> remote) {
  final byId = <String, LogRecord>{};
  for (final log in [...local, ...remote]) {
    byId.putIfAbsent(log.id, () => log);
  }
  return _sortedById(byId.values.toList(), (l) => l.id);
}

/// Greater clock wins; ties fall back to a stable fingerprint so both devices
/// resolve them identically rather than each preferring its own copy.
T? _pick<T>(T? a, T? b, int Function(T) clock, String Function(T) fingerprint) {
  if (a == null) return b;
  if (b == null) return a;
  if (clock(a) != clock(b)) return clock(a) > clock(b) ? a : b;
  return fingerprint(a).compareTo(fingerprint(b)) <= 0 ? a : b;
}

/// `reviewCount` first: it increments exactly once per review, so more reviews
/// is unambiguously later without consulting a clock.
CardRecord? _pickSchedule(CardRecord? a, CardRecord? b) {
  if (a == null) return b;
  if (b == null) return a;
  if (a.reviewCount != b.reviewCount) return a.reviewCount > b.reviewCount ? a : b;
  return _pick(a, b, (c) => c.scheduleUpdatedAtMs, _cardFingerprint);
}

/// Earlier of the two, never the winner's — new-card ordering is by creation,
/// and letting it move would reshuffle the queue differently on each device.
int _earliest(int? a, int? b) {
  if (a == null) return b!;
  if (b == null) return a;
  return a < b ? a : b;
}

Iterable<String> _allIds(Iterable<String> a, Iterable<String> b) => {...a, ...b}.toList()..sort();

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

String _deckFingerprint(DeckRecord deck) => _stableHash('${deck.id} ${deck.name}');

String _cardFingerprint(CardRecord card) => _stableHash(
  '${card.id} ${card.deckId} ${card.front} ${card.back}'
  ' ${card.state.name} ${card.dueDateMs} ${card.intervalDays}'
  ' ${card.easeFactor} ${card.reviewCount}',
);

/// FNV-1a. Dart's `hashCode` isn't stable across VM versions, and a tiebreak
/// that differs between devices is worse than none.
String _stableHash(String input) {
  var hash = 0xcbf29ce484222325;
  const mask = 0xFFFFFFFFFFFFFFFF;
  for (final unit in input.codeUnits) {
    hash = (hash ^ unit) & mask;
    hash = (hash * 0x100000001b3) & mask;
  }
  return hash.toRadixString(16).padLeft(16, '0');
}

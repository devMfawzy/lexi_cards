import 'package:hive_ce_flutter/hive_ce_flutter.dart';
import '../models/deck_model.dart';
import '../models/flashcard_model.dart';
import '../models/review_log_model.dart';
import '../models/tombstone_model.dart';

/// Which modification clock a write advances. Required at every call site so a
/// new write path can't silently pick the wrong one.
enum WriteKind {
  /// The user changed what the record says.
  content,

  /// The scheduler changed when a card is next due.
  schedule,

  /// Write the clocks exactly as supplied. Merge-apply only: re-stamping them
  /// would mark every synced record freshly modified and prevent convergence.
  verbatim,
}

abstract class LocalDataSource {
  Future<List<DeckModel>> getDecks();
  Future<DeckModel?> getDeck(String id);
  Future<DeckModel> saveDeck(DeckModel model, {required WriteKind kind});
  Future<void> deleteDeck(String id);

  Future<List<FlashcardModel>> getCards(String deckId);
  Future<FlashcardModel?> getCard(String id);
  Future<FlashcardModel> saveCard(FlashcardModel model, {required WriteKind kind});
  Future<void> deleteCard(String id);
  Future<List<FlashcardModel>> getAllCards();

  Future<void> saveReviewLog(ReviewLogModel model);
  Future<List<ReviewLogModel>> getReviewLogs(String cardId);
  Future<List<ReviewLogModel>> getAllReviewLogs();

  Future<List<TombstoneModel>> getTombstones();

  /// Writes the result of a merge, in an order that survives interruption.
  Future<void> applyMerge({
    required List<TombstoneModel> tombstones,
    required List<DeckModel> decks,
    required List<FlashcardModel> cards,
    required List<ReviewLogModel> logs,
    required List<String> deletedCardIds,
    required List<String> deletedDeckIds,
  });
}

class LocalDataSourceImpl implements LocalDataSource {
  static const String _decksBox = 'decks';
  static const String _cardsBox = 'flashcards';
  static const String _reviewLogsBox = 'review_logs';
  static const String _tombstonesBox = 'tombstones';

  /// Injectable so tests can pin the clocks they assert on.
  final DateTime Function() _now;

  LocalDataSourceImpl({DateTime Function()? now}) : _now = now ?? DateTime.now;

  Future<Box<DeckModel>> get _decks => Hive.openBox<DeckModel>(_decksBox);
  Future<Box<FlashcardModel>> get _cards => Hive.openBox<FlashcardModel>(_cardsBox);
  Future<Box<ReviewLogModel>> get _reviewLogs => Hive.openBox<ReviewLogModel>(_reviewLogsBox);
  Future<Box<TombstoneModel>> get _tombstones => Hive.openBox<TombstoneModel>(_tombstonesBox);

  int get _nowMs => _now().millisecondsSinceEpoch;

  @override
  Future<List<DeckModel>> getDecks() async {
    final box = await _decks;
    return box.values.toList();
  }

  @override
  Future<DeckModel?> getDeck(String id) async {
    final box = await _decks;
    return box.get(id);
  }

  @override
  Future<DeckModel> saveDeck(DeckModel model, {required WriteKind kind}) async {
    final box = await _decks;
    if (kind != WriteKind.verbatim) {
      model.contentUpdatedAtMs = _nowMs;
    }
    await box.put(model.id, model);
    return model;
  }

  @override
  Future<void> deleteDeck(String id) async {
    final cardsBox = await _cards;
    final cardIds = cardsBox.values.where((c) => c.deckId == id).map((c) => c.id).toList();

    // Intent first, then children, then parent. Hive has no cross-box
    // transaction, and deleting the deck first would strand its cards with a
    // deckId pointing at nothing — invisible, but still served by "study all".
    // This order leaves every interruption point merely stale.
    await _writeTombstone(id: id, entityType: TombstoneEntity.deck);
    await cardsBox.deleteAll(cardIds);
    final box = await _decks;
    await box.delete(id);
  }

  @override
  Future<List<FlashcardModel>> getCards(String deckId) async {
    final box = await _cards;
    return box.values.where((c) => c.deckId == deckId).toList();
  }

  @override
  Future<FlashcardModel?> getCard(String id) async {
    final box = await _cards;
    return box.get(id);
  }

  @override
  Future<FlashcardModel> saveCard(FlashcardModel model, {required WriteKind kind}) async {
    final box = await _cards;
    if (kind != WriteKind.verbatim) {
      // Models are rebuilt from entities on every write and so arrive with no
      // clocks; the one this write isn't advancing must be carried over, or a
      // content edit would erase when the card was last reviewed.
      final stored = box.get(model.id);
      final nowMs = _nowMs;
      model
        ..contentUpdatedAtMs = kind == WriteKind.content
            ? nowMs
            : stored?.contentUpdatedAtMs ?? nowMs
        ..scheduleUpdatedAtMs = kind == WriteKind.schedule
            ? nowMs
            : stored?.scheduleUpdatedAtMs ?? nowMs;
    }
    await box.put(model.id, model);
    return model;
  }

  @override
  Future<void> deleteCard(String id) async {
    await _writeTombstone(id: id, entityType: TombstoneEntity.card);
    final box = await _cards;
    await box.delete(id);
  }

  @override
  Future<List<FlashcardModel>> getAllCards() async {
    final box = await _cards;
    return box.values.toList();
  }

  @override
  Future<void> saveReviewLog(ReviewLogModel model) async {
    final box = await _reviewLogs;
    await box.put(model.id, model);
  }

  @override
  Future<List<ReviewLogModel>> getReviewLogs(String cardId) async {
    final box = await _reviewLogs;
    return box.values.where((l) => l.cardId == cardId).toList();
  }

  @override
  Future<List<ReviewLogModel>> getAllReviewLogs() async {
    final box = await _reviewLogs;
    return box.values.toList();
  }

  @override
  Future<List<TombstoneModel>> getTombstones() async {
    final box = await _tombstones;
    return box.values.toList();
  }

  @override
  Future<void> applyMerge({
    required List<TombstoneModel> tombstones,
    required List<DeckModel> decks,
    required List<FlashcardModel> cards,
    required List<ReviewLogModel> logs,
    required List<String> deletedCardIds,
    required List<String> deletedDeckIds,
  }) async {
    // Same ordering rule as deleteDeck: intent, then additions, then removals,
    // children before parents. Re-running the sync repairs any interruption.
    //
    // Deletes go straight to the box rather than through deleteCard/deleteDeck,
    // which would stamp a *new* tombstone and overwrite the real deletion time
    // from the other device — letting the record resurrect on the next merge.
    final tombstoneBox = await _tombstones;
    await tombstoneBox.putAll({for (final t in tombstones) t.storageKey: t});

    final deckBox = await _decks;
    await deckBox.putAll({for (final d in decks) d.id: d});

    final cardBox = await _cards;
    await cardBox.putAll({for (final c in cards) c.id: c});

    final logBox = await _reviewLogs;
    await logBox.putAll({for (final l in logs) l.id: l});

    await cardBox.deleteAll(deletedCardIds);
    await deckBox.deleteAll(deletedDeckIds);
  }

  Future<void> _writeTombstone({required String id, required String entityType}) async {
    final box = await _tombstones;
    final tombstone = TombstoneModel.of(id: id, entityType: entityType, deletedAtMs: _nowMs);
    await box.put(tombstone.storageKey, tombstone);
  }
}

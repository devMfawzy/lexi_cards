import 'package:hive_ce_flutter/hive_ce_flutter.dart';
import '../models/deck_model.dart';
import '../models/flashcard_model.dart';
import '../models/review_log_model.dart';
import '../models/tombstone_model.dart';

/// Which of a record's modification clocks a write should advance.
///
/// Required (not defaulted) at every call site on purpose: forgetting to say
/// won't compile, whereas a default would let a new write path silently pick
/// the wrong clock and corrupt merge ordering in a way no test would notice.
enum WriteKind {
  /// The user changed what the record *says* — a card's front/back, a deck's
  /// name. Advances the content clock only.
  content,

  /// The scheduler changed when the card is next due. Advances the schedule
  /// clock only, so a review never looks like a content edit.
  schedule,

  /// Write the clocks exactly as supplied. Used only when applying a merge:
  /// the incoming record's own timestamps have to survive intact, because
  /// re-stamping them to `now` would mark every synced record freshly
  /// modified and stop the two devices from ever converging.
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
}

class LocalDataSourceImpl implements LocalDataSource {
  static const String _decksBox = 'decks';
  static const String _cardsBox = 'flashcards';
  static const String _reviewLogsBox = 'review_logs';
  static const String _tombstonesBox = 'tombstones';

  /// Injectable so tests can pin the modification clocks they assert on,
  /// matching how `GetReviewStats` takes its own `now`.
  final DateTime Function() _now;

  LocalDataSourceImpl({DateTime Function()? now}) : _now = now ?? DateTime.now;

  Future<Box<DeckModel>> get _decks => Hive.openBox<DeckModel>(_decksBox);
  Future<Box<FlashcardModel>> get _cards => Hive.openBox<FlashcardModel>(_cardsBox);
  Future<Box<ReviewLogModel>> get _reviewLogs =>
      Hive.openBox<ReviewLogModel>(_reviewLogsBox);
  Future<Box<TombstoneModel>> get _tombstones =>
      Hive.openBox<TombstoneModel>(_tombstonesBox);

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

    // Order matters, and it isn't the obvious one. Hive has no cross-box
    // transaction, so this can be interrupted partway; deleting the deck first
    // would leave its cards behind with a deckId pointing at nothing — cards
    // that show up in no deck, yet still surface in "study all decks" and in
    // the stats totals, with no way to reach them. Recording the intent first
    // and removing the children before the parent means every interruption
    // point leaves a state that is merely stale, never corrupt.
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
      // The model handed in was rebuilt from a domain entity, which carries
      // neither clock — so the clock this write isn't advancing has to be
      // carried over from what's already stored, or a content edit would
      // silently erase the record of when the card was last reviewed. A
      // record that doesn't exist yet has both established now.
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

  Future<void> _writeTombstone({required String id, required String entityType}) async {
    final box = await _tombstones;
    final tombstone = TombstoneModel.of(
      id: id,
      entityType: entityType,
      deletedAtMs: _nowMs,
    );
    await box.put(tombstone.storageKey, tombstone);
  }
}

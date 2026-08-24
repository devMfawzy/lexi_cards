import 'package:hive_ce_flutter/hive_ce_flutter.dart';
import '../models/deck_model.dart';
import '../models/flashcard_model.dart';
import '../models/review_log_model.dart';

abstract class LocalDataSource {
  Future<List<DeckModel>> getDecks();
  Future<DeckModel> saveDeck(DeckModel model);
  Future<void> deleteDeck(String id);

  Future<List<FlashcardModel>> getCards(String deckId);
  Future<FlashcardModel?> getCard(String id);
  Future<FlashcardModel> saveCard(FlashcardModel model);
  Future<void> deleteCard(String id);

  Future<void> saveReviewLog(ReviewLogModel model);
  Future<List<ReviewLogModel>> getReviewLogs(String cardId);
}

class LocalDataSourceImpl implements LocalDataSource {
  static const String _decksBox = 'decks';
  static const String _cardsBox = 'flashcards';
  static const String _reviewLogsBox = 'review_logs';

  Future<Box<DeckModel>> get _decks => Hive.openBox<DeckModel>(_decksBox);
  Future<Box<FlashcardModel>> get _cards => Hive.openBox<FlashcardModel>(_cardsBox);
  Future<Box<ReviewLogModel>> get _reviewLogs =>
      Hive.openBox<ReviewLogModel>(_reviewLogsBox);

  @override
  Future<List<DeckModel>> getDecks() async {
    final box = await _decks;
    return box.values.toList();
  }

  @override
  Future<DeckModel> saveDeck(DeckModel model) async {
    final box = await _decks;
    await box.put(model.id, model);
    return model;
  }

  @override
  Future<void> deleteDeck(String id) async {
    final box = await _decks;
    await box.delete(id);
    final cardsBox = await _cards;
    final toDelete =
        cardsBox.values.where((c) => c.deckId == id).map((c) => c.id).toList();
    await cardsBox.deleteAll(toDelete);
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
  Future<FlashcardModel> saveCard(FlashcardModel model) async {
    final box = await _cards;
    await box.put(model.id, model);
    return model;
  }

  @override
  Future<void> deleteCard(String id) async {
    final box = await _cards;
    await box.delete(id);
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
}

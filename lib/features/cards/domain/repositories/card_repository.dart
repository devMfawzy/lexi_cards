import '../entities/deck.dart';
import '../entities/flashcard.dart';
import '../entities/review_log.dart';

abstract class CardRepository {
  // Decks
  Future<List<Deck>> getDecks();
  Future<Deck> createDeck(String name);
  Future<void> deleteDeck(String id);

  // Cards
  Future<List<Flashcard>> getCards(String deckId);
  Future<Flashcard> getCard(String id);
  Future<Flashcard> addCard(String deckId, String front, String back);
  Future<void> deleteCard(String id);
  Future<void> updateCard(Flashcard card);
  Future<List<Flashcard>> getAllCards();

  // Review support
  Future<List<Flashcard>> getDueCards(String deckId);
  Future<List<Flashcard>> getAllDueCards();
  Future<void> addReviewLog(ReviewLog log);
  Future<List<ReviewLog>> getReviewLogs(String cardId);
  Future<List<ReviewLog>> getAllReviewLogs();
}

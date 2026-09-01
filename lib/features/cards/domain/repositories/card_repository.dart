import '../entities/deck.dart';
import '../entities/flashcard.dart';
import '../entities/review_log.dart';

abstract class CardRepository {
  // Decks
  Future<List<Deck>> getDecks();
  Future<Deck> createDeck(String name);
  Future<Deck> renameDeck(String id, String name);
  Future<void> deleteDeck(String id);

  // Cards
  Future<List<Flashcard>> getCards(String deckId);
  Future<Flashcard> getCard(String id);
  Future<Flashcard> addCard(String deckId, String front, String back);
  Future<void> deleteCard(String id);

  /// Persists a change to what the card *says* — its front, back, or deck.
  Future<void> updateCard(Flashcard card);

  /// Persists a change to *when the card is next due*, made by the scheduler
  /// after a review. Separate from [updateCard] because the two are tracked
  /// independently: a device that reviewed a card and one that edited its text
  /// have both made real changes, and merging them shouldn't force a choice
  /// between the review and the edit.
  Future<void> updateCardSchedule(Flashcard card);
  Future<List<Flashcard>> getAllCards();

  // Review support
  Future<List<Flashcard>> getDueCards(String deckId);
  Future<List<Flashcard>> getAllDueCards();
  Future<void> addReviewLog(ReviewLog log);
  Future<List<ReviewLog>> getReviewLogs(String cardId);
  Future<List<ReviewLog>> getAllReviewLogs();
}

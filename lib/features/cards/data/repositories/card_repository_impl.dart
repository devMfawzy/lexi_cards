import 'package:uuid/uuid.dart';
import '../../domain/entities/deck.dart';
import '../../domain/entities/flashcard.dart';
import '../../domain/entities/review_log.dart';
import '../../domain/repositories/card_repository.dart';
import '../datasources/local_datasource.dart';
import '../models/deck_model.dart';
import '../models/flashcard_model.dart';
import '../models/review_log_model.dart';

class CardRepositoryImpl implements CardRepository {
  final LocalDataSource localDataSource;
  final Uuid _uuid;

  CardRepositoryImpl({
    required this.localDataSource,
    Uuid? uuid,
  }) : _uuid = uuid ?? const Uuid();

  @override
  Future<List<Deck>> getDecks() async {
    final models = await localDataSource.getDecks();
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<Deck> createDeck(String name) async {
    final model = DeckModel()
      ..id = _uuid.v4()
      ..name = name
      ..createdAt = DateTime.now();
    final saved = await localDataSource.saveDeck(model);
    return saved.toEntity();
  }

  @override
  Future<void> deleteDeck(String id) => localDataSource.deleteDeck(id);

  @override
  Future<List<Flashcard>> getCards(String deckId) async {
    final models = await localDataSource.getCards(deckId);
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<Flashcard> getCard(String id) async {
    final model = await localDataSource.getCard(id);
    if (model == null) throw Exception('Card not found: $id');
    return model.toEntity();
  }

  @override
  Future<Flashcard> addCard(String deckId, String front, String back) async {
    final now = DateTime.now();
    final card = Flashcard.newCard(
      id: _uuid.v4(),
      deckId: deckId,
      front: front,
      back: back,
      createdAt: now,
    );
    final saved = await localDataSource.saveCard(FlashcardModel.fromEntity(card));
    return saved.toEntity();
  }

  @override
  Future<void> deleteCard(String id) => localDataSource.deleteCard(id);

  @override
  Future<void> updateCard(Flashcard card) async {
    await localDataSource.saveCard(FlashcardModel.fromEntity(card));
  }

  @override
  Future<List<Flashcard>> getDueCards(String deckId) async {
    final now = DateTime.now();
    final endOfToday = DateTime(now.year, now.month, now.day + 1);
    final cards = await getCards(deckId);

    final learningDue = cards
        .where((c) =>
            (c.state == CardState.learning || c.state == CardState.relearning) &&
            !c.dueDate.isAfter(now))
        .toList()
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));

    final reviewDue = cards
        .where((c) => c.state == CardState.review && c.dueDate.isBefore(endOfToday))
        .toList()
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));

    final newCards = cards.where((c) => c.state == CardState.newCard).toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    return [...learningDue, ...reviewDue, ...newCards];
  }

  @override
  Future<void> addReviewLog(ReviewLog log) async {
    await localDataSource.saveReviewLog(ReviewLogModel.fromEntity(log));
  }

  @override
  Future<List<ReviewLog>> getReviewLogs(String cardId) async {
    final models = await localDataSource.getReviewLogs(cardId);
    return models.map((m) => m.toEntity()).toList();
  }
}

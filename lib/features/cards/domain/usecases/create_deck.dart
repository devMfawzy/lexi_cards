import '../entities/deck.dart';
import '../repositories/card_repository.dart';

class CreateDeck {
  final CardRepository repository;
  CreateDeck(this.repository);

  Future<Deck> call(String name) => repository.createDeck(name);
}

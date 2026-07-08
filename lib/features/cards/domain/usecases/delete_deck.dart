import '../repositories/card_repository.dart';

class DeleteDeck {
  final CardRepository repository;
  DeleteDeck(this.repository);

  Future<void> call(String id) => repository.deleteDeck(id);
}

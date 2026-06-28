import '../repositories/term_repository.dart';

class DeleteSet {
  final TermRepository repository;
  DeleteSet(this.repository);

  Future<void> call(String id) => repository.deleteSet(id);
}

import '../repositories/term_repository.dart';

class DeleteTerm {
  final TermRepository repository;
  DeleteTerm(this.repository);

  Future<void> call(String id) => repository.deleteTerm(id);
}

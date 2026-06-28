import '../entities/term_set.dart';
import '../repositories/term_repository.dart';

class CreateSet {
  final TermRepository repository;
  CreateSet(this.repository);

  Future<TermSet> call(String name, String targetLanguage) =>
      repository.createSet(name, targetLanguage);
}

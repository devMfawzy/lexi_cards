import '../entities/term.dart';
import '../entities/term_set.dart';

abstract class TermRepository {
  // Sets
  Future<List<TermSet>> getSets();
  Future<TermSet> createSet(String name, String targetLanguage);
  Future<void> deleteSet(String id);

  // Terms
  Future<List<Term>> getTerms(String setId);
  Future<Term> addTerm(String text, String setId);
  Future<void> deleteTerm(String id);
  Future<void> updateReviewStatus(String id, ReviewStatus status);
}

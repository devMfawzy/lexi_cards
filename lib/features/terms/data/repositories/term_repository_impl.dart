import 'package:uuid/uuid.dart';
import '../../domain/entities/term.dart';
import '../../domain/entities/term_set.dart';
import '../../domain/repositories/term_repository.dart';
import '../datasources/ai_datasource.dart';
import '../datasources/local_datasource.dart';
import '../models/term_model.dart';
import '../models/term_set_model.dart';

class TermRepositoryImpl implements TermRepository {
  final LocalDataSource localDataSource;
  final AIDataSource aiDataSource;
  final Uuid _uuid;

  TermRepositoryImpl({
    required this.localDataSource,
    required this.aiDataSource,
    Uuid? uuid,
  }) : _uuid = uuid ?? const Uuid();

  @override
  Future<List<TermSet>> getSets() async {
    final models = await localDataSource.getSets();
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<TermSet> createSet(String name, String targetLanguage) async {
    final model = TermSetModel()
      ..id = _uuid.v4()
      ..name = name
      ..targetLanguage = targetLanguage
      ..createdAt = DateTime.now();
    final saved = await localDataSource.saveSet(model);
    return saved.toEntity();
  }

  @override
  Future<void> deleteSet(String id) => localDataSource.deleteSet(id);

  @override
  Future<List<Term>> getTerms(String setId) async {
    final models = await localDataSource.getTerms(setId);
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<Term> addTerm(String text, String setId) async {
    // Get the set to know what language to pass to the AI
    final sets = await localDataSource.getSets();
    final termSet = sets.firstWhere((s) => s.id == setId);

    final phrases = await aiDataSource.generatePhrases(
      text,
      termSet.targetLanguage,
    );

    final model = TermModel()
      ..id = _uuid.v4()
      ..setId = setId
      ..text = text
      ..phrases = phrases
      ..reviewStatus = ReviewStatus.fresh.index
      ..createdAt = DateTime.now();

    final saved = await localDataSource.saveTerm(model);
    return saved.toEntity();
  }

  @override
  Future<void> deleteTerm(String id) => localDataSource.deleteTerm(id);

  @override
  Future<void> updateReviewStatus(String id, ReviewStatus status) =>
      localDataSource.updateTermReviewStatus(id, status.index);
}

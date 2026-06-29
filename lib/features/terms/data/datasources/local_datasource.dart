import 'package:hive_flutter/hive_flutter.dart';
import '../models/term_model.dart';
import '../models/term_set_model.dart';

abstract class LocalDataSource {
  Future<List<TermSetModel>> getSets();
  Future<TermSetModel> saveSet(TermSetModel model);
  Future<void> deleteSet(String id);

  Future<List<TermModel>> getTerms(String setId);
  Future<TermModel> saveTerm(TermModel model);
  Future<void> deleteTerm(String id);
  Future<void> updateTermReviewStatus(String id, int status);
}

class LocalDataSourceImpl implements LocalDataSource {
  static const String _setsBox = 'sets';
  static const String _termsBox = 'terms';

  Future<Box<TermSetModel>> get _sets => Hive.openBox<TermSetModel>(_setsBox);
  Future<Box<TermModel>> get _terms => Hive.openBox<TermModel>(_termsBox);

  @override
  Future<List<TermSetModel>> getSets() async {
    final box = await _sets;
    return box.values.toList();
  }

  @override
  Future<TermSetModel> saveSet(TermSetModel model) async {
    final box = await _sets;
    await box.put(model.id, model);
    return model;
  }

  @override
  Future<void> deleteSet(String id) async {
    final box = await _sets;
    await box.delete(id);
    // Also delete all terms belonging to this set
    final termsBox = await _terms;
    final toDelete = termsBox.values
        .where((t) => t.setId == id)
        .map((t) => t.id)
        .toList();
    await termsBox.deleteAll(toDelete);
  }

  @override
  Future<List<TermModel>> getTerms(String setId) async {
    final box = await _terms;
    return box.values.where((t) => t.setId == setId).toList();
  }

  @override
  Future<TermModel> saveTerm(TermModel model) async {
    final box = await _terms;
    await box.put(model.id, model);
    return model;
  }

  @override
  Future<void> deleteTerm(String id) async {
    final box = await _terms;
    await box.delete(id);
  }

  @override
  Future<void> updateTermReviewStatus(String id, int status) async {
    final box = await _terms;
    final term = box.get(id);
    if (term != null) {
      term.reviewStatus = status;
      await term.save();
    }
  }
}

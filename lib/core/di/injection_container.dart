import 'package:get_it/get_it.dart';

import '../../features/cards/data/datasources/local_datasource.dart';
import '../../features/cards/data/repositories/card_repository_impl.dart';
import '../../features/cards/domain/repositories/card_repository.dart';
import '../../features/cards/domain/usecases/add_card.dart';
import '../../features/cards/domain/usecases/create_deck.dart';
import '../../features/cards/domain/usecases/delete_card.dart';
import '../../features/cards/domain/usecases/delete_deck.dart';
import '../../features/cards/domain/usecases/get_cards.dart';
import '../../features/cards/domain/usecases/get_decks.dart';
import '../../features/review/domain/usecases/get_due_cards.dart';
import '../../features/review/domain/usecases/submit_review.dart';

final getIt = GetIt.instance;

Future<void> initDependencies() async {
  // Cards feature - data
  getIt.registerLazySingleton<LocalDataSource>(() => LocalDataSourceImpl());
  getIt.registerLazySingleton<CardRepository>(
    () => CardRepositoryImpl(localDataSource: getIt()),
  );

  // Cards feature - usecases
  getIt.registerFactory(() => GetDecks(getIt()));
  getIt.registerFactory(() => CreateDeck(getIt()));
  getIt.registerFactory(() => DeleteDeck(getIt()));
  getIt.registerFactory(() => GetCards(getIt()));
  getIt.registerFactory(() => AddCard(getIt()));
  getIt.registerFactory(() => DeleteCard(getIt()));

  // Review feature - usecases
  getIt.registerFactory(() => GetDueCards(getIt()));
  getIt.registerFactory(() => SubmitReview(getIt()));
}

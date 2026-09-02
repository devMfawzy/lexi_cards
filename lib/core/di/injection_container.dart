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
import '../../features/cards/domain/usecases/rename_deck.dart';
import '../../features/cards/domain/usecases/update_card.dart';
import '../../features/review/domain/usecases/get_all_cards.dart';
import '../../features/review/domain/usecases/get_due_cards.dart';
import '../../features/review/domain/usecases/submit_review.dart';
import '../../features/settings/data/datasources/settings_local_datasource.dart';
import '../../features/settings/data/repositories/settings_repository_impl.dart';
import '../../features/settings/domain/repositories/settings_repository.dart';
import '../../features/settings/domain/usecases/get_reminder_settings.dart';
import '../../features/settings/domain/usecases/save_reminder_settings.dart';
import '../../features/settings/presentation/bloc/locale_cubit.dart';
import '../../features/stats/domain/usecases/get_review_stats.dart';
import '../../features/sync/data/repositories/sync_repository_impl.dart';
import '../../features/sync/domain/repositories/sync_repository.dart';
import '../../features/sync/presentation/bloc/sync_cubit.dart';
import '../notifications/notification_service.dart';
import '../sync/cloud_storage.dart';
import '../sync/google_drive_storage.dart';

final getIt = GetIt.instance;

Future<void> initDependencies() async {
  // Cards feature - data
  getIt.registerLazySingleton<LocalDataSource>(() => LocalDataSourceImpl());
  getIt.registerLazySingleton<CardRepository>(() => CardRepositoryImpl(localDataSource: getIt()));

  // Cards feature - usecases
  getIt.registerFactory(() => GetDecks(getIt()));
  getIt.registerFactory(() => CreateDeck(getIt()));
  getIt.registerFactory(() => RenameDeck(getIt()));
  getIt.registerFactory(() => DeleteDeck(getIt()));
  getIt.registerFactory(() => GetCards(getIt()));
  getIt.registerFactory(() => AddCard(getIt()));
  getIt.registerFactory(() => DeleteCard(getIt()));
  getIt.registerFactory(() => UpdateCard(getIt()));

  // Review feature - usecases
  getIt.registerFactory(() => GetDueCards(getIt()));
  getIt.registerFactory(() => SubmitReview(getIt()));
  getIt.registerFactory(() => GetAllCards(getIt()));

  // Stats feature - usecases
  getIt.registerFactory(() => GetReviewStats(getIt()));

  // Notifications
  getIt.registerLazySingleton<NotificationService>(() => NotificationService());

  // Settings feature - data
  getIt.registerLazySingleton<SettingsLocalDataSource>(() => SettingsLocalDataSourceImpl());
  getIt.registerLazySingleton<SettingsRepository>(
    () => SettingsRepositoryImpl(localDataSource: getIt()),
  );

  // Settings feature - usecases
  getIt.registerFactory(() => GetReminderSettings(getIt()));
  getIt.registerFactory(() => SaveReminderSettings(getIt()));

  // Cloud sync
  getIt.registerLazySingleton<GoogleDriveStorage>(() => GoogleDriveStorage());
  // Registered under the interface too: everything above the transport talks
  // to CloudStorage, and only startup needs the concrete type to call init().
  getIt.registerLazySingleton<CloudStorage>(() => getIt<GoogleDriveStorage>());
  getIt.registerLazySingleton<SyncRepository>(
    () => SyncRepositoryImpl(localDataSource: getIt(), cloudStorage: getIt()),
  );
  // Singleton for the same reason as LocaleCubit: the linked account is
  // app-wide, shown in Settings and acted on from the sync screen, and a run
  // started on one shouldn't be thrown away by navigating to the other.
  getIt.registerLazySingleton<SyncCubit>(
    () => SyncCubit(cloudStorage: getIt(), syncRepository: getIt()),
  );

  // Locale - app-wide singleton (see LocaleCubit doc comment)
  getIt.registerLazySingleton<LocaleCubit>(() => LocaleCubit(repository: getIt()));
}

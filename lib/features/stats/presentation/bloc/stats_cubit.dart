import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_review_stats.dart';
import 'stats_state.dart';

class StatsCubit extends Cubit<StatsState> {
  final GetReviewStats getReviewStats;

  StatsCubit({required this.getReviewStats}) : super(const StatsState());

  Future<void> load() async {
    emit(state.copyWith(isLoading: true, errorMessage: null));
    try {
      final stats = await getReviewStats();
      emit(state.copyWith(stats: stats, isLoading: false));
    } catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: e.toString()));
    }
  }
}

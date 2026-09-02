import 'package:equatable/equatable.dart';
import '../../domain/entities/review_stats.dart';

class StatsState extends Equatable {
  final bool isLoading;
  final ReviewStats? stats;
  final String? errorMessage;

  const StatsState({this.isLoading = false, this.stats, this.errorMessage});

  StatsState copyWith({bool? isLoading, ReviewStats? stats, String? errorMessage}) {
    return StatsState(
      isLoading: isLoading ?? this.isLoading,
      stats: stats ?? this.stats,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [isLoading, stats, errorMessage];
}

import '../../../../generated/api/models/dance_response.dart';

enum DancesStatus { initial, loading, loaded, error }

/// Immutable state for the Dances feature.
class DancesState {
  const DancesState({
    required this.status,
    this.dances = const [],
    this.errorMessage,
  });

  factory DancesState.initial() => const DancesState(status: DancesStatus.initial);

  final DancesStatus status;
  final List<DanceResponse> dances;
  final String? errorMessage;

  DancesState copyWith({
    DancesStatus? status,
    List<DanceResponse>? dances,
    String? errorMessage,
    bool clearError = false,
  }) {
    return DancesState(
      status: status ?? this.status,
      dances: dances ?? this.dances,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

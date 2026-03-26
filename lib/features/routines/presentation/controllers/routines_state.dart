import '../../../../generated/api/models/routine_response.dart';

enum RoutinesStatus { initial, loading, loaded, error }

/// Immutable state for the Routines feature.
class RoutinesState {
  const RoutinesState({
    required this.status,
    this.routines = const [],
    this.selectedRoutine,
    this.errorMessage,
  });

  factory RoutinesState.initial() =>
      const RoutinesState(status: RoutinesStatus.initial);

  final RoutinesStatus status;
  final List<RoutineResponse> routines;
  final RoutineResponse? selectedRoutine;
  final String? errorMessage;

  RoutinesState copyWith({
    RoutinesStatus? status,
    List<RoutineResponse>? routines,
    RoutineResponse? selectedRoutine,
    bool clearSelectedRoutine = false,
    String? errorMessage,
    bool clearError = false,
  }) {
    return RoutinesState(
      status: status ?? this.status,
      routines: routines ?? this.routines,
      selectedRoutine: clearSelectedRoutine
          ? null
          : (selectedRoutine ?? this.selectedRoutine),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

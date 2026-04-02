import '../../../../generated/api/models/routine_session_response.dart';

enum RoutineInstancesStatus { initial, loading, loaded, error }

/// Immutable state for the RoutineInstances feature.
class RoutineInstancesState {
  const RoutineInstancesState({
    required this.status,
    this.instances = const [],
    this.selectedInstance,
    this.errorMessage,
  });

  factory RoutineInstancesState.initial() =>
      const RoutineInstancesState(status: RoutineInstancesStatus.initial);

  final RoutineInstancesStatus status;
  final List<RoutineSessionResponse> instances;
  final RoutineSessionResponse? selectedInstance;
  final String? errorMessage;

  RoutineInstancesState copyWith({
    RoutineInstancesStatus? status,
    List<RoutineSessionResponse>? instances,
    RoutineSessionResponse? selectedInstance,
    bool clearSelectedInstance = false,
    String? errorMessage,
    bool clearError = false,
  }) {
    return RoutineInstancesState(
      status: status ?? this.status,
      instances: instances ?? this.instances,
      selectedInstance: clearSelectedInstance
          ? null
          : (selectedInstance ?? this.selectedInstance),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

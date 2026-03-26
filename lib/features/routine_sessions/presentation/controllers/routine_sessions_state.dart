import '../../../../generated/api/models/routine_session_response.dart';

enum RoutineSessionsStatus { initial, loading, loaded, error }

/// Immutable state for the RoutineSessions feature.
class RoutineSessionsState {
  const RoutineSessionsState({
    required this.status,
    this.sessions = const [],
    this.selectedSession,
    this.errorMessage,
  });

  factory RoutineSessionsState.initial() =>
      const RoutineSessionsState(status: RoutineSessionsStatus.initial);

  final RoutineSessionsStatus status;
  final List<RoutineSessionResponse> sessions;
  final RoutineSessionResponse? selectedSession;
  final String? errorMessage;

  RoutineSessionsState copyWith({
    RoutineSessionsStatus? status,
    List<RoutineSessionResponse>? sessions,
    RoutineSessionResponse? selectedSession,
    bool clearSelectedSession = false,
    String? errorMessage,
    bool clearError = false,
  }) {
    return RoutineSessionsState(
      status: status ?? this.status,
      sessions: sessions ?? this.sessions,
      selectedSession: clearSelectedSession
          ? null
          : (selectedSession ?? this.selectedSession),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

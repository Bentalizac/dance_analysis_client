import '../../../../generated/api/models/slot_assignment_response.dart';

enum SlotAssignmentsStatus { initial, loading, loaded, error }

/// Immutable state for the SlotAssignments feature.
class SlotAssignmentsState {
  const SlotAssignmentsState({
    required this.status,
    this.assignments = const [],
    this.errorMessage,
  });

  factory SlotAssignmentsState.initial() =>
      const SlotAssignmentsState(status: SlotAssignmentsStatus.initial);

  final SlotAssignmentsStatus status;
  final List<SlotAssignmentResponse> assignments;
  final String? errorMessage;

  SlotAssignmentsState copyWith({
    SlotAssignmentsStatus? status,
    List<SlotAssignmentResponse>? assignments,
    String? errorMessage,
    bool clearError = false,
  }) {
    return SlotAssignmentsState(
      status: status ?? this.status,
      assignments: assignments ?? this.assignments,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

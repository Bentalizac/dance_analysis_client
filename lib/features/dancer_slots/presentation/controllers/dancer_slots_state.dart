import '../../../../generated/api/models/routine_dancer_slot_response.dart';

enum DancerSlotsStatus { initial, loading, loaded, error }

/// Immutable state for the DancerSlots feature.
class DancerSlotsState {
  const DancerSlotsState({
    required this.status,
    this.slots = const [],
    this.errorMessage,
  });

  factory DancerSlotsState.initial() =>
      const DancerSlotsState(status: DancerSlotsStatus.initial);

  final DancerSlotsStatus status;
  final List<RoutineDancerSlotResponse> slots;
  final String? errorMessage;

  DancerSlotsState copyWith({
    DancerSlotsStatus? status,
    List<RoutineDancerSlotResponse>? slots,
    String? errorMessage,
    bool clearError = false,
  }) {
    return DancerSlotsState(
      status: status ?? this.status,
      slots: slots ?? this.slots,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

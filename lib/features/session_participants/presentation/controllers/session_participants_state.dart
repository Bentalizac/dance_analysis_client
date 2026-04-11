import '../../../../generated/api/models/session_access_response.dart';
import '../../../../generated/api/models/session_participant_with_user_response.dart';

enum SessionParticipantsStatus { initial, loading, loaded, error }

class SessionParticipantsState {
  const SessionParticipantsState({
    required this.status,
    this.participants = const [],
    this.accessList = const [],
    this.availableUserIds = const [],
    this.linkedGroupIds = const [],
    this.errorMessage,
  });

  factory SessionParticipantsState.initial() => const SessionParticipantsState(
        status: SessionParticipantsStatus.initial,
      );

  final SessionParticipantsStatus status;

  /// Participants currently cast into a slot, with user details embedded.
  final List<SessionParticipantWithUserResponse> participants;

  /// All users who have session access (for the access section).
  final List<SessionAccessResponse> accessList;

  /// User IDs with access but no participant record yet.
  final List<String> availableUserIds;

  /// IDs of groups linked to this session (used for the invite flow).
  final List<String> linkedGroupIds;

  final String? errorMessage;

  /// Returns the participant assigned to [slotId], or null if the slot is empty.
  SessionParticipantWithUserResponse? participantForSlot(String slotId) =>
      participants.where((p) => p.dancerSlotId == slotId).firstOrNull;

  SessionParticipantsState copyWith({
    SessionParticipantsStatus? status,
    List<SessionParticipantWithUserResponse>? participants,
    List<SessionAccessResponse>? accessList,
    List<String>? availableUserIds,
    List<String>? linkedGroupIds,
    String? errorMessage,
    bool clearError = false,
  }) {
    return SessionParticipantsState(
      status: status ?? this.status,
      participants: participants ?? this.participants,
      accessList: accessList ?? this.accessList,
      availableUserIds: availableUserIds ?? this.availableUserIds,
      linkedGroupIds: linkedGroupIds ?? this.linkedGroupIds,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

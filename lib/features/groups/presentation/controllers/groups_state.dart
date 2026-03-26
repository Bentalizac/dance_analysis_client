import '../../../../generated/api/models/group_membership_response.dart';
import '../../../../generated/api/models/group_response.dart';

enum GroupsStatus { initial, loading, loaded, error }

/// Immutable state snapshot for the Groups feature.
class GroupsState {
  const GroupsState({
    required this.status,
    this.groups = const [],
    this.selectedGroup,
    this.members = const [],
    this.errorMessage,
  });

  factory GroupsState.initial() =>
      const GroupsState(status: GroupsStatus.initial);

  final GroupsStatus status;
  final List<GroupResponse> groups;
  final GroupResponse? selectedGroup;
  final List<GroupMembershipResponse> members;
  final String? errorMessage;

  GroupsState copyWith({
    GroupsStatus? status,
    List<GroupResponse>? groups,
    GroupResponse? selectedGroup,
    bool clearSelectedGroup = false,
    List<GroupMembershipResponse>? members,
    String? errorMessage,
    bool clearError = false,
  }) {
    return GroupsState(
      status: status ?? this.status,
      groups: groups ?? this.groups,
      selectedGroup:
          clearSelectedGroup ? null : (selectedGroup ?? this.selectedGroup),
      members: members ?? this.members,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

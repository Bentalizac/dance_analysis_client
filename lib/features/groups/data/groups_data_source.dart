import 'package:dio/dio.dart';

import '../../../core/exceptions/app_exceptions.dart';
import '../../../generated/api/export.dart';

/// Data source that wraps [GroupsClient] and maps network errors
/// to domain exceptions.
class GroupsDataSource {
  GroupsDataSource(this._client);

  final RestClient _client;

  Future<List<GroupResponse>> listGroups() async {
    try {
      return await _client.groups.listGroupsApiV1GroupsGet();
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  Future<GroupResponse> getGroup(String groupId) async {
    try {
      return await _client.groups
          .getGroupApiV1GroupsGroupIdGet(groupId: groupId);
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  Future<GroupResponse> createGroup({
    required String name,
    String? description,
  }) async {
    try {
      return await _client.groups.createGroupApiV1GroupsPost(
        body: GroupCreate(name: name, description: description),
      );
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  Future<List<GroupMembershipResponse>> listMembers(String groupId) async {
    try {
      return await _client.groups
          .listMembersApiV1GroupsGroupIdMembersGet(groupId: groupId);
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  Future<GroupMembershipResponse> addMember(
    String groupId,
    String userId, {
    GroupRole role = GroupRole.member,
  }) async {
    try {
      return await _client.groups.addMemberApiV1GroupsGroupIdMembersPost(
        groupId: groupId,
        body: AddAdminRequest(userId: userId, role: role),
      );
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  Future<void> removeMember(String groupId, String userId) async {
    try {
      await _client.groups.removeMemberApiV1GroupsGroupIdMembersUserIdDelete(
        groupId: groupId,
        userId: userId,
      );
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }
}

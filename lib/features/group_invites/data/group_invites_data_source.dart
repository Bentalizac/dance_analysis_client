import 'package:dio/dio.dart';

import '../../../core/exceptions/app_exceptions.dart';
import '../../../generated/api/export.dart';

/// Data source wrapping [GroupInvitesClient].
class GroupInvitesDataSource {
  GroupInvitesDataSource(this._client);

  final RestClient _client;

  Future<GroupInviteResponse> createInvite(
    String groupId, {
    required String email,
    GroupRole? role,
  }) async {
    try {
      return await _client.groupInvites
          .createInviteApiV1GroupsGroupIdInvitesPost(
        groupId: groupId,
        body: GroupInviteCreate(email: email.toLowerCase().trim(), role: role),
      );
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  Future<GroupMembershipResponse> acceptInvite(String token) async {
    try {
      return await _client.groupInvites
          .acceptInviteApiV1GroupInvitesAcceptPost(
        body: AcceptInviteRequest(token: token),
      );
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }
}

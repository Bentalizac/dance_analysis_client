import 'package:dio/dio.dart';

import '../../../core/exceptions/app_exceptions.dart';
import '../../../generated/api/export.dart';

/// Data source wrapping [SessionAccessClient].
class SessionAccessDataSource {
  SessionAccessDataSource(this._client);

  final RestClient _client;

  Future<List<SessionAccessResponse>> listAccess(String sessionId) async {
    try {
      return await _client.sessionAccess
          .listSessionAccessApiV1SessionsSessionIdAccessGet(
        sessionId: sessionId,
      );
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  Future<List<SessionAccessOriginResponse>> listOrigins(
      String sessionId) async {
    try {
      return await _client.sessionAccess
          .listAccessOriginsApiV1SessionsSessionIdAccessOriginsGet(
        sessionId: sessionId,
      );
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  Future<SessionAccessResponse> grantAccess(
    String sessionId, {
    required String userId,
    String role = 'viewer',
  }) async {
    try {
      return await _client.sessionAccess
          .grantDirectAccessApiV1SessionsSessionIdAccessUsersPost(
        sessionId: sessionId,
        body: SessionAccessCreate(userId: userId, role: role),
      );
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  Future<void> revokeAccess(String sessionId, String userId) async {
    try {
      await _client.sessionAccess
          .revokeDirectAccessApiV1SessionsSessionIdAccessUsersUserIdDelete(
        sessionId: sessionId,
        userId: userId,
      );
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  Future<List<SessionGroupLinkResponse>> listLinkedGroups(
      String sessionId) async {
    try {
      return await _client.sessionAccess
          .listSessionGroupsApiV1SessionsSessionIdGroupsGet(
        sessionId: sessionId,
      );
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  Future<SessionGroupLinkResponse> linkGroup(
    String sessionId, {
    required String groupId,
    String role = 'viewer',
  }) async {
    try {
      return await _client.sessionAccess
          .linkGroupToSessionApiV1SessionsSessionIdGroupsPost(
        sessionId: sessionId,
        body: SessionGroupLinkCreate(groupId: groupId, role: role),
      );
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  Future<void> unlinkGroup(String sessionId, String groupId) async {
    try {
      await _client.sessionAccess
          .unlinkGroupFromSessionApiV1SessionsSessionIdGroupsGroupIdDelete(
        sessionId: sessionId,
        groupId: groupId,
      );
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }
}

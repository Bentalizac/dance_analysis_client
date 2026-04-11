import 'package:dio/dio.dart';

import '../../../core/exceptions/app_exceptions.dart';
import '../../../generated/api/export.dart';

/// Data source wrapping [SessionInvitesClient].
class SessionInvitesDataSource {
  SessionInvitesDataSource(this._client);

  final RestClient _client;

  Future<SessionInviteResponse> createInvite(
    String sessionId, {
    required String email,
    String role = 'viewer',
  }) async {
    try {
      return await _client.sessionInvites
          .createInviteApiV1SessionsSessionIdInvitesPost(
        sessionId: sessionId,
        body: SessionInviteCreate(email: email.toLowerCase().trim(), role: role),
      );
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  Future<SessionInviteLookupResponse> lookupInvite(String token) async {
    try {
      return await _client.sessionInvites
          .lookupInviteApiV1SessionInvitesLookupGet(token: token);
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  Future<List<SessionInvitePendingResponse>> listPending() async {
    try {
      return await _client.sessionInvites
          .listPendingInvitesApiV1SessionInvitesPendingGet();
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  Future<SessionAccessResponse> acceptInvite(String token) async {
    try {
      return await _client.sessionInvites
          .acceptInviteApiV1SessionInvitesAcceptPost(
        body: AcceptSessionInviteRequest(token: token),
      );
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }
}

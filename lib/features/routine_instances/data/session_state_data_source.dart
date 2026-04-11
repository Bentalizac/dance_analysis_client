import 'package:dio/dio.dart';

import '../../../core/exceptions/app_exceptions.dart';
import '../../../generated/api/export.dart';

/// Data source wrapping [SessionStateClient] for per-user session state.
class SessionStateDataSource {
  SessionStateDataSource(this._client);

  final RestClient _client;

  Future<List<SessionUserStateResponse>> listMySessionStates() async {
    try {
      return await _client.sessionState
          .listMySessionStatesApiV1MeSessionsStateGet();
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  Future<SessionUserStateResponse> archive(String sessionId) async {
    try {
      return await _client.sessionState
          .archiveSessionApiV1SessionsSessionIdArchivePost(
        sessionId: sessionId,
      );
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  Future<SessionUserStateResponse> unarchive(String sessionId) async {
    try {
      return await _client.sessionState
          .unarchiveSessionApiV1SessionsSessionIdUnarchivePost(
        sessionId: sessionId,
      );
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  /// Soft-deletes the session for the current user only.
  Future<SessionUserStateResponse> softDelete(String sessionId) async {
    try {
      return await _client.sessionState
          .deleteSessionApiV1SessionsSessionIdDeletePost(
        sessionId: sessionId,
      );
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }
}

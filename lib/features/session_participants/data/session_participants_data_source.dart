import 'package:dio/dio.dart';

import '../../../core/exceptions/app_exceptions.dart';
import '../../../generated/api/export.dart';

/// Data source wrapping [SessionParticipantsClient].
class SessionParticipantsDataSource {
  SessionParticipantsDataSource(this._client);

  final RestClient _client;

  /// Returns participants with embedded user details (name, email).
  Future<List<SessionParticipantWithUserResponse>> listWithUsers(
      String sessionId) async {
    try {
      return await _client.sessionParticipants
          .listParticipantsWithUsersApiV1SessionsSessionIdParticipantsWithUsersGet(
        sessionId: sessionId,
      );
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  /// Returns participant list including available user IDs.
  Future<ParticipantListResponse> list(String sessionId) async {
    try {
      return await _client.sessionParticipants
          .listParticipantsApiV1SessionsSessionIdParticipantsGet(
        sessionId: sessionId,
      );
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  /// Creates a participant and atomically binds them to [slotId].
  Future<SessionParticipantResponse> create(
    String sessionId, {
    required String userId,
    String role = 'dancer',
    String? slotId,
  }) async {
    try {
      return await _client.sessionParticipants
          .createParticipantApiV1SessionsSessionIdParticipantsPost(
        sessionId: sessionId,
        body: SessionParticipantCreate(
          userId: userId,
          role: role,
          dancerSlotId: slotId,
        ),
      );
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  Future<void> delete(String sessionId, String participantId) async {
    try {
      await _client.sessionParticipants
          .deleteParticipantApiV1SessionsSessionIdParticipantsParticipantIdDelete(
        sessionId: sessionId,
        participantId: participantId,
      );
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }
}

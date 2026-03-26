import 'package:dio/dio.dart';

import '../../../core/exceptions/app_exceptions.dart';
import '../../../generated/api/export.dart';

/// Data source wrapping [RoutineSessionsClient].
class RoutineSessionsDataSource {
  RoutineSessionsDataSource(this._client);

  final RestClient _client;

  Future<RoutineSessionResponse> createSession(
    String routineId, {
    String? groupId,
    String? label,
  }) async {
    try {
      return await _client.routineSessions
          .createSessionApiV1RoutinesRoutineIdSessionsPost(
        routineId: routineId,
        body: RoutineSessionCreate(groupId: groupId, label: label),
      );
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  Future<List<RoutineSessionResponse>> listRoutineSessions(
      String routineId) async {
    try {
      return await _client.routineSessions
          .listRoutineSessionsApiV1RoutinesRoutineIdSessionsGet(
        routineId: routineId,
      );
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  Future<List<RoutineSessionResponse>> listGroupSessions(
      String groupId) async {
    try {
      return await _client.routineSessions
          .listGroupSessionsApiV1GroupsGroupIdSessionsGet(
        groupId: groupId,
      );
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  Future<RoutineSessionResponse> getSession(String sessionId) async {
    try {
      return await _client.routineSessions
          .getSessionApiV1SessionsSessionIdGet(
        sessionId: sessionId,
      );
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  Future<void> deleteSession(String sessionId) async {
    try {
      await _client.routineSessions
          .deleteSessionApiV1SessionsSessionIdDelete(
        sessionId: sessionId,
      );
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }
}

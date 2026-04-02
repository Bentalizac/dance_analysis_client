import 'package:dio/dio.dart';

import '../../../core/exceptions/app_exceptions.dart';
import '../../../generated/api/export.dart';

/// Data source wrapping [RoutineSessionsClient].
class RoutineInstancesDataSource {
  RoutineInstancesDataSource(this._client);

  final RestClient _client;

  Future<RoutineSessionResponse> createInstance(
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

  Future<List<RoutineSessionResponse>> listRoutineInstances(
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

  Future<List<RoutineSessionResponse>> listGroupInstances(
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

  Future<RoutineSessionResponse> getInstance(String instanceId) async {
    try {
      return await _client.routineSessions
          .getSessionApiV1SessionsSessionIdGet(
        sessionId: instanceId,
      );
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  Future<void> deleteInstance(String instanceId) async {
    try {
      await _client.routineSessions
          .deleteSessionApiV1SessionsSessionIdDelete(
        sessionId: instanceId,
      );
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }
}

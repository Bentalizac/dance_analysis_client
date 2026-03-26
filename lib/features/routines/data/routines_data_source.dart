import 'package:dio/dio.dart';

import '../../../core/exceptions/app_exceptions.dart';
import '../../../generated/api/export.dart';

/// Data source wrapping [RoutinesClient].
class RoutinesDataSource {
  RoutinesDataSource(this._client);

  final RestClient _client;

  Future<List<RoutineResponse>> listRoutines() async {
    try {
      return await _client.routines.listRoutinesApiV1RoutinesGet();
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  Future<RoutineResponse> getRoutine(String routineId) async {
    try {
      return await _client.routines.getRoutineApiV1RoutinesRoutineIdGet(
        routineId: routineId,
      );
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  Future<RoutineResponse> createRoutine({
    required String title,
    required String danceId,
  }) async {
    try {
      return await _client.routines.createRoutineApiV1RoutinesPost(
        body: RoutineCreate(title: title, danceId: danceId),
      );
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  Future<RoutineResponse> updateRoutine(
    String routineId, {
    String? title,
    String? danceId,
  }) async {
    try {
      return await _client.routines.updateRoutineApiV1RoutinesRoutineIdPatch(
        routineId: routineId,
        body: RoutineUpdate(title: title, danceId: danceId),
      );
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  Future<void> deleteRoutine(String routineId) async {
    try {
      await _client.routines.deleteRoutineApiV1RoutinesRoutineIdDelete(
        routineId: routineId,
      );
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }
}

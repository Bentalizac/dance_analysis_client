import 'package:dio/dio.dart';

import '../../../core/exceptions/app_exceptions.dart';
import '../../../generated/api/export.dart';

/// Data source wrapping [DancerSlotsClient].
class DancerSlotsDataSource {
  DancerSlotsDataSource(this._client);

  final RestClient _client;

  Future<RoutineDancerSlotResponse> createSlot(
    String routineId, {
    required String label,
    int? orderIndex,
  }) async {
    try {
      return await _client.dancerSlots
          .createSlotApiV1RoutinesRoutineIdSlotsPost(
        routineId: routineId,
        body: RoutineDancerSlotCreate(label: label, orderIndex: orderIndex),
      );
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  Future<List<RoutineDancerSlotResponse>> listSlots(String routineId) async {
    try {
      return await _client.dancerSlots
          .listSlotsApiV1RoutinesRoutineIdSlotsGet(
        routineId: routineId,
      );
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  Future<void> deleteSlot(String routineId, String slotId) async {
    try {
      await _client.dancerSlots
          .deleteSlotApiV1RoutinesRoutineIdSlotsSlotIdDelete(
        routineId: routineId,
        slotId: slotId,
      );
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }
}

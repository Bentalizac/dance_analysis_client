import 'package:dio/dio.dart';

import '../../../core/exceptions/app_exceptions.dart';
import '../../../generated/api/export.dart';

/// Data source wrapping [SlotAssignmentsClient].
class SlotAssignmentsDataSource {
  SlotAssignmentsDataSource(this._client);

  final RestClient _client;

  Future<SlotAssignmentResponse> createAssignment(
    String sessionId, {
    required String dancerSlotId,
    required String userId,
  }) async {
    try {
      return await _client.slotAssignments
          .createAssignmentApiV1SessionsSessionIdAssignmentsPost(
        sessionId: sessionId,
        body: SlotAssignmentCreate(dancerSlotId: dancerSlotId, userId: userId),
      );
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  Future<List<SlotAssignmentResponse>> listAssignments(
      String sessionId) async {
    try {
      return await _client.slotAssignments
          .listAssignmentsApiV1SessionsSessionIdAssignmentsGet(
        sessionId: sessionId,
      );
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  Future<void> deleteAssignment(
      String sessionId, String assignmentId) async {
    try {
      await _client.slotAssignments
          .deleteAssignmentApiV1SessionsSessionIdAssignmentsAssignmentIdDelete(
        sessionId: sessionId,
        assignmentId: assignmentId,
      );
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }
}

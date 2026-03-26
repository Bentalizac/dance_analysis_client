import 'package:flutter/foundation.dart';

import '../../../../core/exceptions/app_exceptions.dart';
import '../../data/slot_assignments_data_source.dart';
import 'slot_assignments_state.dart';

/// Manages slot assignments for a session.
class SlotAssignmentsController extends ChangeNotifier {
  SlotAssignmentsController({required SlotAssignmentsDataSource dataSource})
      : _dataSource = dataSource;

  final SlotAssignmentsDataSource _dataSource;

  SlotAssignmentsState _state = SlotAssignmentsState.initial();
  SlotAssignmentsState get state => _state;

  Future<void> loadAssignments(String sessionId) async {
    _state = _state.copyWith(
        status: SlotAssignmentsStatus.loading, clearError: true);
    notifyListeners();

    try {
      final assignments = await _dataSource.listAssignments(sessionId);
      _state = _state.copyWith(
          status: SlotAssignmentsStatus.loaded, assignments: assignments);
    } on AppException catch (e) {
      _state = _state.copyWith(
          status: SlotAssignmentsStatus.error, errorMessage: e.message);
    }
    notifyListeners();
  }

  Future<bool> assignSlot(
    String sessionId, {
    required String dancerSlotId,
    required String userId,
  }) async {
    try {
      await _dataSource.createAssignment(sessionId,
          dancerSlotId: dancerSlotId, userId: userId);
      await loadAssignments(sessionId);
      return true;
    } on AppException catch (e) {
      _state = _state.copyWith(errorMessage: e.message);
      notifyListeners();
      return false;
    }
  }

  Future<bool> removeAssignment(String sessionId, String assignmentId) async {
    try {
      await _dataSource.deleteAssignment(sessionId, assignmentId);
      await loadAssignments(sessionId);
      return true;
    } on AppException catch (e) {
      _state = _state.copyWith(errorMessage: e.message);
      notifyListeners();
      return false;
    }
  }
}

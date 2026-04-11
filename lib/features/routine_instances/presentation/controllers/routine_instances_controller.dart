import 'package:flutter/foundation.dart';

import '../../../../core/exceptions/app_exceptions.dart';
import '../../../../generated/api/models/routine_session_response.dart';
import '../../data/routine_instances_data_source.dart';
import 'routine_instances_state.dart';

/// Coordinates routine instance CRUD for the UI.
class RoutineInstancesController extends ChangeNotifier {
  RoutineInstancesController({required RoutineInstancesDataSource dataSource})
      : _dataSource = dataSource;

  final RoutineInstancesDataSource _dataSource;

  RoutineInstancesState _state = RoutineInstancesState.initial();
  RoutineInstancesState get state => _state;

  // Sessions are no longer scoped to groups in the backend model.
  // Group-linked sessions will be surfaced via session access in a future update.
  Future<void> loadGroupInstances(String groupId) async {
    _state = _state.copyWith(
      status: RoutineInstancesStatus.loaded,
      instances: [],
    );
    notifyListeners();
  }

  Future<void> loadRoutineInstances(String routineId) async {
    _state = _state.copyWith(
        status: RoutineInstancesStatus.loading, clearError: true);
    notifyListeners();

    try {
      final instances = await _dataSource.listRoutineInstances(routineId);
      _state = _state.copyWith(
          status: RoutineInstancesStatus.loaded, instances: instances);
    } on AppException catch (e) {
      _state = _state.copyWith(
          status: RoutineInstancesStatus.error, errorMessage: e.message);
    }
    notifyListeners();
  }

  Future<void> loadInstanceDetail(String instanceId) async {
    _state = _state.copyWith(
        status: RoutineInstancesStatus.loading, clearError: true);
    notifyListeners();

    try {
      final instance = await _dataSource.getInstance(instanceId);
      _state = _state.copyWith(
          status: RoutineInstancesStatus.loaded, selectedInstance: instance);
    } on AppException catch (e) {
      _state = _state.copyWith(
          status: RoutineInstancesStatus.error, errorMessage: e.message);
    }
    notifyListeners();
  }

  /// Creates a session for a routine and returns it so callers can navigate to it.
  Future<RoutineSessionResponse?> createInstance(
    String routineId, {
    String? label,
  }) async {
    try {
      final instance =
          await _dataSource.createInstance(routineId, label: label);
      return instance;
    } on AppException catch (e) {
      _state = _state.copyWith(errorMessage: e.message);
      notifyListeners();
      return null;
    }
  }

  /// Returns an existing session for [routineId], creating one if none exist.
  ///
  /// Used by [RoutineDetailPage] to transparently provide a session context
  /// for videos and notes without exposing the session concept to the user.
  Future<RoutineSessionResponse?> ensureDefaultSession(String routineId) async {
    try {
      final sessions = await _dataSource.listRoutineInstances(routineId);
      if (sessions.isNotEmpty) return sessions.first;
      return await _dataSource.createInstance(routineId);
    } on AppException catch (e) {
      _state = _state.copyWith(errorMessage: e.message);
      notifyListeners();
      return null;
    }
  }

  Future<bool> deleteInstance(String instanceId) async {
    try {
      await _dataSource.deleteInstance(instanceId);
      return true;
    } on AppException catch (e) {
      _state = _state.copyWith(errorMessage: e.message);
      notifyListeners();
      return false;
    }
  }
}

import 'package:flutter/foundation.dart';

import '../../../../core/exceptions/app_exceptions.dart';
import '../../../../generated/api/models/routine_session_response.dart';
import '../../data/routine_sessions_data_source.dart';
import 'routine_sessions_state.dart';

/// Coordinates routine session CRUD for the UI.
class RoutineSessionsController extends ChangeNotifier {
  RoutineSessionsController({required RoutineSessionsDataSource dataSource})
      : _dataSource = dataSource;

  final RoutineSessionsDataSource _dataSource;

  RoutineSessionsState _state = RoutineSessionsState.initial();
  RoutineSessionsState get state => _state;

  Future<void> loadGroupSessions(String groupId) async {
    _state = _state.copyWith(
        status: RoutineSessionsStatus.loading, clearError: true);
    notifyListeners();

    try {
      final sessions = await _dataSource.listGroupSessions(groupId);
      _state = _state.copyWith(
          status: RoutineSessionsStatus.loaded, sessions: sessions);
    } on AppException catch (e) {
      _state = _state.copyWith(
          status: RoutineSessionsStatus.error, errorMessage: e.message);
    }
    notifyListeners();
  }

  Future<void> loadRoutineSessions(String routineId) async {
    _state = _state.copyWith(
        status: RoutineSessionsStatus.loading, clearError: true);
    notifyListeners();

    try {
      final sessions = await _dataSource.listRoutineSessions(routineId);
      _state = _state.copyWith(
          status: RoutineSessionsStatus.loaded, sessions: sessions);
    } on AppException catch (e) {
      _state = _state.copyWith(
          status: RoutineSessionsStatus.error, errorMessage: e.message);
    }
    notifyListeners();
  }

  Future<void> loadSessionDetail(String sessionId) async {
    _state = _state.copyWith(
        status: RoutineSessionsStatus.loading, clearError: true);
    notifyListeners();

    try {
      final session = await _dataSource.getSession(sessionId);
      _state = _state.copyWith(
          status: RoutineSessionsStatus.loaded, selectedSession: session);
    } on AppException catch (e) {
      _state = _state.copyWith(
          status: RoutineSessionsStatus.error, errorMessage: e.message);
    }
    notifyListeners();
  }

  /// Creates a session for a routine, optionally scoped to a group.
  /// Returns the created session so callers can navigate to it.
  Future<RoutineSessionResponse?> createSession(
    String routineId, {
    String? groupId,
    String? label,
  }) async {
    try {
      final session = await _dataSource.createSession(routineId,
          groupId: groupId, label: label);
      return session;
    } on AppException catch (e) {
      _state = _state.copyWith(errorMessage: e.message);
      notifyListeners();
      return null;
    }
  }

  Future<bool> deleteSession(String sessionId, {String? refreshGroupId}) async {
    try {
      await _dataSource.deleteSession(sessionId);
      if (refreshGroupId != null) {
        await loadGroupSessions(refreshGroupId);
      }
      return true;
    } on AppException catch (e) {
      _state = _state.copyWith(errorMessage: e.message);
      notifyListeners();
      return false;
    }
  }
}

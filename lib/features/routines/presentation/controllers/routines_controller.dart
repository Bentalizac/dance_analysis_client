import 'package:flutter/foundation.dart';

import '../../../../core/exceptions/app_exceptions.dart';
import '../../../../generated/api/models/routine_response.dart';
import '../../data/routines_data_source.dart';
import 'routines_state.dart';

/// Coordinates routine CRUD for the UI.
class RoutinesController extends ChangeNotifier {
  RoutinesController({required RoutinesDataSource dataSource})
      : _dataSource = dataSource;

  final RoutinesDataSource _dataSource;

  RoutinesState _state = RoutinesState.initial();
  RoutinesState get state => _state;

  Future<void> loadRoutines() async {
    _state = _state.copyWith(status: RoutinesStatus.loading, clearError: true);
    notifyListeners();

    try {
      final routines = await _dataSource.listRoutines();
      _state = _state.copyWith(status: RoutinesStatus.loaded, routines: routines);
    } on AppException catch (e) {
      _state = _state.copyWith(status: RoutinesStatus.error, errorMessage: e.message);
    }
    notifyListeners();
  }

  Future<void> loadRoutineDetail(String routineId) async {
    _state = _state.copyWith(status: RoutinesStatus.loading, clearError: true);
    notifyListeners();

    try {
      final routine = await _dataSource.getRoutine(routineId);
      _state = _state.copyWith(status: RoutinesStatus.loaded, selectedRoutine: routine);
    } on AppException catch (e) {
      _state = _state.copyWith(status: RoutinesStatus.error, errorMessage: e.message);
    }
    notifyListeners();
  }

  /// Creates a routine and returns it so callers can chain further operations
  /// (e.g. creating a session tied to a group).
  Future<RoutineResponse?> createRoutine({
    required String title,
    required String danceId,
  }) async {
    try {
      final routine = await _dataSource.createRoutine(title: title, danceId: danceId);
      await loadRoutines();
      return routine;
    } on AppException catch (e) {
      _state = _state.copyWith(errorMessage: e.message);
      notifyListeners();
      return null;
    }
  }

  Future<bool> deleteRoutine(String routineId) async {
    try {
      await _dataSource.deleteRoutine(routineId);
      await loadRoutines();
      return true;
    } on AppException catch (e) {
      _state = _state.copyWith(errorMessage: e.message);
      notifyListeners();
      return false;
    }
  }
}

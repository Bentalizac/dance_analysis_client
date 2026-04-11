import 'package:flutter/foundation.dart';

import '../../../../core/exceptions/app_exceptions.dart';
import '../../../../generated/api/models/routine_response.dart';
import '../../../../generated/api/models/routine_session_response.dart';
import '../../../../generated/api/models/session_user_state_response.dart';
import '../../../../shared/services/auth_service.dart';
import '../../../dancer_slots/data/dancer_slots_data_source.dart';
import '../../../routine_instances/data/routine_instances_data_source.dart';
import '../../../routine_instances/data/session_state_data_source.dart';
import '../../data/routines_data_source.dart';
import 'routines_feed_state.dart';

/// Aggregates owned routines and accessible shared sessions into a unified feed.
class RoutinesFeedController extends ChangeNotifier {
  RoutinesFeedController({
    required RoutinesDataSource routinesDataSource,
    required RoutineInstancesDataSource instancesDataSource,
    required SessionStateDataSource sessionStateDataSource,
    required DancerSlotsDataSource dancerSlotsDataSource,
    required AuthService authService,
  })  : _routinesDataSource = routinesDataSource,
        _instancesDataSource = instancesDataSource,
        _sessionStateDataSource = sessionStateDataSource,
        _dancerSlotsDataSource = dancerSlotsDataSource,
        _authService = authService;

  final RoutinesDataSource _routinesDataSource;
  final RoutineInstancesDataSource _instancesDataSource;
  final SessionStateDataSource _sessionStateDataSource;
  final DancerSlotsDataSource _dancerSlotsDataSource;
  final AuthService _authService;

  static const _defaultSlotLabels = ['Lead', 'Follow'];

  RoutinesFeedState _state = RoutinesFeedState.initial();
  RoutinesFeedState get state => _state;

  /// Loads owned routines, accessible sessions, and session states in parallel,
  /// then merges them into the feed.
  Future<void> load() async {
    _state = _state.copyWith(
      status: RoutinesFeedStatus.loading,
      clearError: true,
    );
    notifyListeners();

    final currentUserId = _authService.currentUser?.id;

    try {
      final results = await Future.wait([
        _routinesDataSource.listRoutines(),
        _instancesDataSource.listMySessions(),
        _sessionStateDataSource.listMySessionStates(),
      ]);

      final routines = results[0] as List<RoutineResponse>;
      final sessions = results[1] as List<RoutineSessionResponse>;
      final states = results[2] as List<SessionUserStateResponse>;

      final stateBySessionId = <String, SessionUserStateResponse>{
        for (final s in states) s.sessionId: s,
      };

      final ownedItems =
          routines.map((r) => OwnedRoutineItem(routine: r)).toList();

      final sharedItems = sessions
          .where((s) => s.ownerId != currentUserId)
          .where((s) => stateBySessionId[s.id]?.isDeleted != true)
          .map((s) => SharedSessionItem(
                session: s,
                isArchived: stateBySessionId[s.id]?.isArchived ?? false,
              ))
          .toList();

      _state = _state.copyWith(
        status: RoutinesFeedStatus.loaded,
        ownedItems: ownedItems,
        sharedItems: sharedItems,
      );
    } on AppException catch (e) {
      _state = _state.copyWith(
        status: RoutinesFeedStatus.error,
        errorMessage: e.message,
      );
    }

    notifyListeners();
  }

  void setFilter(RoutinesFeedFilter filter) {
    if (_state.filter == filter) return;
    _state = _state.copyWith(filter: filter);
    notifyListeners();
  }

  Future<void> archiveSession(String sessionId) async {
    try {
      await _sessionStateDataSource.archive(sessionId);
      await load();
    } on AppException catch (e) {
      _state = _state.copyWith(errorMessage: e.message);
      notifyListeners();
    }
  }

  Future<void> unarchiveSession(String sessionId) async {
    try {
      await _sessionStateDataSource.unarchive(sessionId);
      await load();
    } on AppException catch (e) {
      _state = _state.copyWith(errorMessage: e.message);
      notifyListeners();
    }
  }

  /// Soft-deletes the session for the current user and reloads the feed.
  Future<void> hideSession(String sessionId) async {
    try {
      await _sessionStateDataSource.softDelete(sessionId);
      await load();
    } on AppException catch (e) {
      _state = _state.copyWith(errorMessage: e.message);
      notifyListeners();
    }
  }

  /// Creates a routine with default Lead/Follow slots, reloads the feed,
  /// and returns the new routine (or null on failure).
  Future<RoutineResponse?> createRoutine({
    required String title,
    required String danceId,
  }) async {
    try {
      final routine = await _routinesDataSource.createRoutine(
        title: title,
        danceId: danceId,
      );
      await Future.wait([
        for (var i = 0; i < _defaultSlotLabels.length; i++)
          _dancerSlotsDataSource.createSlot(
            routine.id,
            label: _defaultSlotLabels[i],
            orderIndex: i,
          ),
      ]);
      await load();
      return routine;
    } on AppException catch (e) {
      _state = _state.copyWith(errorMessage: e.message);
      notifyListeners();
      return null;
    }
  }
}

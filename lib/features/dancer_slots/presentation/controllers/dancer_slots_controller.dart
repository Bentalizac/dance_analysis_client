import 'package:flutter/foundation.dart';

import '../../../../core/exceptions/app_exceptions.dart';
import '../../data/dancer_slots_data_source.dart';
import 'dancer_slots_state.dart';

/// Manages dancer slots for a routine.
class DancerSlotsController extends ChangeNotifier {
  DancerSlotsController({required DancerSlotsDataSource dataSource})
      : _dataSource = dataSource;

  final DancerSlotsDataSource _dataSource;

  DancerSlotsState _state = DancerSlotsState.initial();
  DancerSlotsState get state => _state;

  Future<void> loadSlots(String routineId) async {
    _state = _state.copyWith(status: DancerSlotsStatus.loading, clearError: true);
    notifyListeners();

    try {
      final slots = await _dataSource.listSlots(routineId);
      _state = _state.copyWith(status: DancerSlotsStatus.loaded, slots: slots);
    } on AppException catch (e) {
      _state = _state.copyWith(
          status: DancerSlotsStatus.error, errorMessage: e.message);
    }
    notifyListeners();
  }

  Future<bool> addSlot(
    String routineId, {
    required String label,
    int? orderIndex,
  }) async {
    try {
      await _dataSource.createSlot(routineId,
          label: label, orderIndex: orderIndex);
      await loadSlots(routineId);
      return true;
    } on AppException catch (e) {
      _state = _state.copyWith(errorMessage: e.message);
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteSlot(String routineId, String slotId) async {
    try {
      await _dataSource.deleteSlot(routineId, slotId);
      await loadSlots(routineId);
      return true;
    } on AppException catch (e) {
      _state = _state.copyWith(errorMessage: e.message);
      notifyListeners();
      return false;
    }
  }
}

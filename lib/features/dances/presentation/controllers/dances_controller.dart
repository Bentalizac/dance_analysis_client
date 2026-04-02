import 'package:flutter/foundation.dart';

import '../../../../core/exceptions/app_exceptions.dart';
import '../../data/dances_data_source.dart';
import 'dances_state.dart';

/// Loads and caches the list of available dance definitions.
class DancesController extends ChangeNotifier {
  DancesController({required DancesDataSource dataSource})
      : _dataSource = dataSource;

  final DancesDataSource _dataSource;

  DancesState _state = DancesState.initial();
  DancesState get state => _state;

  /// Fetches dances from the API. No-ops if already loaded.
  Future<void> loadDances() async {
    if (_state.status == DancesStatus.loaded) return;
    _state = _state.copyWith(status: DancesStatus.loading, clearError: true);
    notifyListeners();

    try {
      final dances = await _dataSource.listDances();
      _state = _state.copyWith(status: DancesStatus.loaded, dances: dances);
    } on AppException catch (e) {
      _state = _state.copyWith(status: DancesStatus.error, errorMessage: e.message);
    }
    notifyListeners();
  }
}

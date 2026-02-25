import 'package:flutter/foundation.dart';

import '../../data/history_repository.dart';
import 'history_state.dart';

/// Coordinates loading and refreshing history data for the UI.
///
/// Uses [HistoryRepository] to merge local submissions with remote job data.
class HistoryController extends ChangeNotifier {
  HistoryController({required HistoryRepository repository})
      : _repository = repository;

  final HistoryRepository _repository;

  HistoryState _state = HistoryState.initial();
  HistoryState get state => _state;

  /// Full load of history data (local + remote merge).
  ///
  /// On remote failure with local data, sets error with a warning message.
  /// On total failure, sets error state.
  Future<void> loadHistory() async {
    _state = _state.copyWith(
      status: HistoryStatus.loading,
      clearErrorMessage: true,
      clearWarningMessage: true,
    );
    notifyListeners();

    try {
      final result = await _repository.loadHistory();
      _state = _state.copyWith(
        status: HistoryStatus.loaded,
        items: result.items,
        warningMessage: result.warning,
        isRefreshing: false,
      );
    } on HistoryLoadException catch (e) {
      _state = _state.copyWith(
        status: HistoryStatus.error,
        errorMessage: e.message,
        isRefreshing: false,
      );
    } catch (e) {
      _state = _state.copyWith(
        status: HistoryStatus.error,
        errorMessage: 'Unexpected error loading history: $e',
        isRefreshing: false,
      );
    }
    notifyListeners();
  }

  /// Pull-to-refresh: retains existing items while refreshing.
  Future<void> refresh() async {
    _state = _state.copyWith(isRefreshing: true, clearWarningMessage: true);
    notifyListeners();

    try {
      final result = await _repository.loadHistory();
      _state = _state.copyWith(
        status: HistoryStatus.loaded,
        items: result.items,
        warningMessage: result.warning,
        isRefreshing: false,
      );
    } on HistoryLoadException catch (e) {
      // Keep existing items visible, just show a warning
      _state = _state.copyWith(
        warningMessage: e.message,
        isRefreshing: false,
      );
    } catch (e) {
      _state = _state.copyWith(
        warningMessage: 'Could not refresh: $e',
        isRefreshing: false,
      );
    }
    notifyListeners();
  }
}

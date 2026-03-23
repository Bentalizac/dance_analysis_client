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

  /// Soft-delete a job by hiding it from the list.
  ///
  /// Optimistically removes the item from the UI, then calls the
  /// (currently stubbed) repository method.
  Future<void> hideJob(String jobId) async {
    // Optimistic removal from the list
    final updatedItems =
        _state.items.where((item) => item.job.jobId != jobId).toList();
    _state = _state.copyWith(items: updatedItems);
    notifyListeners();

    try {
      await _repository.hideJob(jobId);
    } catch (e) {
      // On failure, reload to restore the item
      _state = _state.copyWith(
        warningMessage: 'Could not delete job. Please try again.',
      );
      notifyListeners();
      await loadHistory();
    }
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

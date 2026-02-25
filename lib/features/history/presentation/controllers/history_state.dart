import '../../../../models/history_item.dart';

/// High-level status for the History page.
enum HistoryStatus { initial, loading, loaded, error }

/// Immutable state snapshot for the History feature.
class HistoryState {
  const HistoryState({
    required this.status,
    this.items = const [],
    this.errorMessage,
    this.warningMessage,
    this.isRefreshing = false,
  });

  factory HistoryState.initial() =>
      const HistoryState(status: HistoryStatus.initial);

  final HistoryStatus status;
  final List<HistoryItem> items;
  final String? errorMessage;

  /// Non-fatal warning (e.g. "Statuses may be out of date").
  final String? warningMessage;

  /// True during pull-to-refresh while existing items are still shown.
  final bool isRefreshing;

  HistoryState copyWith({
    HistoryStatus? status,
    List<HistoryItem>? items,
    String? errorMessage,
    bool clearErrorMessage = false,
    String? warningMessage,
    bool clearWarningMessage = false,
    bool? isRefreshing,
  }) {
    return HistoryState(
      status: status ?? this.status,
      items: items ?? this.items,
      errorMessage:
          clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
      warningMessage:
          clearWarningMessage ? null : (warningMessage ?? this.warningMessage),
      isRefreshing: isRefreshing ?? this.isRefreshing,
    );
  }
}

import '../../../../generated/api/models/routine_response.dart';
import '../../../../generated/api/models/routine_session_response.dart';

enum RoutinesFeedFilter { all, owned, shared, archived }

enum RoutinesFeedStatus { initial, loading, loaded, error }

sealed class RoutinesFeedItem {
  const RoutinesFeedItem();
}

class OwnedRoutineItem extends RoutinesFeedItem {
  const OwnedRoutineItem({required this.routine});

  final RoutineResponse routine;
}

class SharedSessionItem extends RoutinesFeedItem {
  const SharedSessionItem({required this.session, required this.isArchived});

  final RoutineSessionResponse session;
  final bool isArchived;
}

class RoutinesFeedState {
  const RoutinesFeedState({
    required this.status,
    required this.filter,
    this.ownedItems = const [],
    this.sharedItems = const [],
    this.errorMessage,
  });

  factory RoutinesFeedState.initial() => const RoutinesFeedState(
        status: RoutinesFeedStatus.initial,
        filter: RoutinesFeedFilter.all,
      );

  final RoutinesFeedStatus status;
  final RoutinesFeedFilter filter;
  final List<OwnedRoutineItem> ownedItems;
  final List<SharedSessionItem> sharedItems;
  final String? errorMessage;

  bool get hasArchivedSessions => sharedItems.any((s) => s.isArchived);

  List<RoutinesFeedItem> get visibleItems => switch (filter) {
        RoutinesFeedFilter.all => [
            ...ownedItems,
            ...sharedItems.where((s) => !s.isArchived),
          ],
        RoutinesFeedFilter.owned => List<RoutinesFeedItem>.from(ownedItems),
        RoutinesFeedFilter.shared =>
          sharedItems.where((s) => !s.isArchived).toList(),
        RoutinesFeedFilter.archived =>
          sharedItems.where((s) => s.isArchived).toList(),
      };

  RoutinesFeedState copyWith({
    RoutinesFeedStatus? status,
    RoutinesFeedFilter? filter,
    List<OwnedRoutineItem>? ownedItems,
    List<SharedSessionItem>? sharedItems,
    String? errorMessage,
    bool clearError = false,
  }) {
    return RoutinesFeedState(
      status: status ?? this.status,
      filter: filter ?? this.filter,
      ownedItems: ownedItems ?? this.ownedItems,
      sharedItems: sharedItems ?? this.sharedItems,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

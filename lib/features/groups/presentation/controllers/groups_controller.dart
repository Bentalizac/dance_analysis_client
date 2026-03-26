import 'package:flutter/foundation.dart';

import '../../../../core/exceptions/app_exceptions.dart';
import '../../data/groups_data_source.dart';
import 'groups_state.dart';

/// Coordinates group operations for the UI.
class GroupsController extends ChangeNotifier {
  GroupsController({required GroupsDataSource dataSource})
      : _dataSource = dataSource;

  final GroupsDataSource _dataSource;

  GroupsState _state = GroupsState.initial();
  GroupsState get state => _state;

  Future<void> loadGroups() async {
    _state = _state.copyWith(status: GroupsStatus.loading, clearError: true);
    notifyListeners();

    try {
      final groups = await _dataSource.listGroups();
      _state = _state.copyWith(status: GroupsStatus.loaded, groups: groups);
    } on AppException catch (e) {
      _state = _state.copyWith(
        status: GroupsStatus.error,
        errorMessage: e.message,
      );
    } catch (e) {
      _state = _state.copyWith(
        status: GroupsStatus.error,
        errorMessage: 'Failed to load groups: $e',
      );
    }
    notifyListeners();
  }

  Future<bool> createGroup({
    required String name,
    String? description,
  }) async {
    try {
      await _dataSource.createGroup(name: name, description: description);
      await loadGroups(); // Refresh list
      return true;
    } on AppException catch (e) {
      _state = _state.copyWith(errorMessage: e.message);
      notifyListeners();
      return false;
    }
  }

  Future<void> loadGroupDetail(String groupId) async {
    _state = _state.copyWith(status: GroupsStatus.loading, clearError: true);
    notifyListeners();

    try {
      final group = await _dataSource.getGroup(groupId);
      final members = await _dataSource.listMembers(groupId);
      _state = _state.copyWith(
        status: GroupsStatus.loaded,
        selectedGroup: group,
        members: members,
      );
    } on AppException catch (e) {
      _state = _state.copyWith(
        status: GroupsStatus.error,
        errorMessage: e.message,
      );
    }
    notifyListeners();
  }

  Future<bool> removeMember(String groupId, String userId) async {
    try {
      await _dataSource.removeMember(groupId, userId);
      await loadGroupDetail(groupId); // Refresh members
      return true;
    } on AppException catch (e) {
      _state = _state.copyWith(errorMessage: e.message);
      notifyListeners();
      return false;
    }
  }
}

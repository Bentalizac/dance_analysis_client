import 'package:flutter/foundation.dart';

import '../../../../core/exceptions/app_exceptions.dart';
import '../../../../generated/api/models/session_access_response.dart';
import '../../../../generated/api/models/session_group_link_response.dart';
import '../../../../generated/api/models/session_participant_with_user_response.dart';
import '../../../session_access/data/session_access_data_source.dart';
import '../../data/session_participants_data_source.dart';
import 'session_participants_state.dart';

/// Manages session casting state: access list, participants, and available users.
class SessionParticipantsController extends ChangeNotifier {
  SessionParticipantsController({
    required SessionParticipantsDataSource participantsDataSource,
    required SessionAccessDataSource accessDataSource,
  })  : _participants = participantsDataSource,
        _access = accessDataSource;

  final SessionParticipantsDataSource _participants;
  final SessionAccessDataSource _access;

  SessionParticipantsState _state = SessionParticipantsState.initial();
  SessionParticipantsState get state => _state;

  /// Loads participants (with user details), access list, available user IDs,
  /// and linked group IDs. All fetches run in parallel.
  Future<void> load(String sessionId) async {
    _state = _state.copyWith(
      status: SessionParticipantsStatus.loading,
      clearError: true,
    );
    notifyListeners();

    try {
      final results = await Future.wait([
        _participants.listWithUsers(sessionId),
        _participants.list(sessionId),
        _access.listAccess(sessionId),
        _access.listLinkedGroups(sessionId),
      ]);

      final withUsers = results[0] as List<SessionParticipantWithUserResponse>;
      final listResponse = results[1] as dynamic; // ParticipantListResponse
      final accessList = results[2] as List<SessionAccessResponse>;
      final linkedGroups = results[3] as List<SessionGroupLinkResponse>;

      // availableUsers may be null if no access holders exist without participants.
      final availableIds =
          (listResponse.availableUsers as List<String>?) ?? <String>[];
      final groupIds = linkedGroups.map((g) => g.groupId).toList();

      _state = _state.copyWith(
        status: SessionParticipantsStatus.loaded,
        participants: withUsers,
        accessList: accessList,
        availableUserIds: availableIds,
        linkedGroupIds: groupIds,
      );
    } on AppException catch (e) {
      _state = _state.copyWith(
        status: SessionParticipantsStatus.error,
        errorMessage: e.message,
      );
    }
    notifyListeners();
  }

  /// Assigns [userId] to [slotId] by creating a participant record.
  ///
  /// The operation is atomic on the backend. If it fails, visible state is
  /// unchanged (no optimistic update).
  Future<void> assign(
    String sessionId, {
    required String userId,
    required String slotId,
  }) async {
    try {
      await _participants.create(
        sessionId,
        userId: userId,
        slotId: slotId,
      );
      await load(sessionId);
    } on AppException catch (e) {
      _state = _state.copyWith(errorMessage: e.message);
      notifyListeners();
    }
  }

  /// Removes a participant from their slot by deleting the participant record.
  Future<void> unassign(String sessionId, String participantId) async {
    try {
      await _participants.delete(sessionId, participantId);
      await load(sessionId);
    } on AppException catch (e) {
      _state = _state.copyWith(errorMessage: e.message);
      notifyListeners();
    }
  }
}

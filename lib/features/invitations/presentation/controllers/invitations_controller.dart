import 'package:flutter/foundation.dart';

import '../../../../core/exceptions/app_exceptions.dart';
import '../../../../features/group_invites/data/group_invites_data_source.dart';
import '../../../../features/session_invites/data/session_invites_data_source.dart';

enum PendingInviteType { group, session }

/// Unified view model for a pending invite, built by merging the two
/// pending-invite lists from the API and sorted by [createdAt] descending.
class PendingInvite {
  const PendingInvite({
    required this.token,
    required this.type,
    required this.name,
    required this.role,
    required this.expiresAt,
    required this.createdAt,
    this.groupId,
    this.sessionId,
  });

  final String token;
  final PendingInviteType type;

  /// Group name (group invites) or routine name (session invites).
  final String name;
  final String role;
  final DateTime expiresAt;
  final DateTime createdAt;

  /// Set for [PendingInviteType.group] — used for navigation after accept.
  final String? groupId;

  /// Set for [PendingInviteType.session] — used for navigation after accept.
  final String? sessionId;
}

/// Manages the merged list of pending invitations for the current user.
///
/// Fetches [GroupInvitesDataSource.listPending] and
/// [SessionInvitesDataSource.listPending] in parallel, merges the results
/// into a single chronological list, and exposes [pendingCount] for the
/// Groups page badge.
class InvitationsController extends ChangeNotifier {
  InvitationsController({
    required GroupInvitesDataSource groupInvitesDataSource,
    required SessionInvitesDataSource sessionInvitesDataSource,
  })  : _groupDs = groupInvitesDataSource,
        _sessionDs = sessionInvitesDataSource;

  final GroupInvitesDataSource _groupDs;
  final SessionInvitesDataSource _sessionDs;

  List<PendingInvite> _invites = [];
  bool _isLoading = false;
  String? _error;

  List<PendingInvite> get invites => _invites;
  int get pendingCount => _invites.length;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> load() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final (groupInvites, sessionInvites) = await (
        _groupDs.listPending(),
        _sessionDs.listPending(),
      ).wait;

      final merged = [
        ...groupInvites.map(
          (g) => PendingInvite(
            token: g.token,
            type: PendingInviteType.group,
            name: g.groupName,
            role: g.role?.json ?? 'member',
            expiresAt: g.expiresAt,
            createdAt: g.createdAt,
            groupId: g.groupId,
          ),
        ),
        ...sessionInvites.map(
          (s) => PendingInvite(
            token: s.token,
            type: PendingInviteType.session,
            name: s.routineName,
            role: s.role,
            expiresAt: s.expiresAt,
            createdAt: s.createdAt,
            sessionId: s.sessionId,
          ),
        ),
      ];

      merged.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      _invites = merged;
    } on AppException catch (e) {
      _error = e.message;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Accepts [invite] via the appropriate data source and removes it from
  /// the list. Throws [AppException] on failure so the UI can surface errors.
  Future<void> accept(PendingInvite invite) async {
    if (invite.type == PendingInviteType.group) {
      await _groupDs.acceptInvite(invite.token);
    } else {
      await _sessionDs.acceptInvite(invite.token);
    }
    _invites = List.of(_invites)..remove(invite);
    notifyListeners();
  }
}

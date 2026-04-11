import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../generated/api/models/group_response.dart';
import '../../../../generated/api/models/session_access_origin_response.dart';
import '../../../../generated/api/models/session_access_response.dart';
import '../../../../generated/api/models/session_group_link_response.dart';
import '../../../../shared/design_system/theme.dart';
import '../../../groups/presentation/controllers/groups_controller.dart';
import '../../../session_access/data/session_access_data_source.dart';
import '../../../session_invites/data/session_invites_data_source.dart';

/// Bottom sheet for viewing and managing session access.
///
/// Shows who has access (with origin context — invite or group) and which
/// groups are linked to the session. The owner can unlink groups or link
/// new ones. Access itself is granted automatically via invitations or group
/// membership — there is no manual grant form here.
class ManageGroupSheet extends StatefulWidget {
  const ManageGroupSheet({
    super.key,
    required this.sessionId,
    required this.accessList,
    required this.onAccessChanged,
  });

  final String sessionId;
  final List<SessionAccessResponse> accessList;

  /// Called after any mutation so the parent can reload casting state.
  final VoidCallback onAccessChanged;

  static Future<void> show(
    BuildContext context, {
    required String sessionId,
    required List<SessionAccessResponse> accessList,
    required VoidCallback onAccessChanged,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDesignSystem.radiusMd),
        ),
      ),
      builder: (_) => ManageGroupSheet(
        sessionId: sessionId,
        accessList: accessList,
        onAccessChanged: onAccessChanged,
      ),
    );
  }

  @override
  State<ManageGroupSheet> createState() => _ManageGroupSheetState();
}

class _ManageGroupSheetState extends State<ManageGroupSheet> {
  List<SessionAccessOriginResponse> _origins = [];
  List<SessionGroupLinkResponse> _linkedGroups = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
    // Make sure the groups list is loaded for the link-group picker.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GroupsController>().loadGroups();
    });
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final ds = context.read<SessionAccessDataSource>();
      final results = await Future.wait([
        ds.listOrigins(widget.sessionId),
        ds.listLinkedGroups(widget.sessionId),
      ]);
      if (mounted) {
        setState(() {
          _origins = results[0] as List<SessionAccessOriginResponse>;
          _linkedGroups = results[1] as List<SessionGroupLinkResponse>;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _error = 'Could not load access details.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Map<String, List<SessionAccessOriginResponse>> get _originsByUser {
    final map = <String, List<SessionAccessOriginResponse>>{};
    for (final o in _origins) {
      map.putIfAbsent(o.userId, () => []).add(o);
    }
    return map;
  }

  Future<void> _revokeAccess(String userId) async {
    try {
      await context
          .read<SessionAccessDataSource>()
          .revokeAccess(widget.sessionId, userId);
      widget.onAccessChanged();
      await _load();
    } catch (_) {
      widget.onAccessChanged();
    }
  }

  Future<void> _unlinkGroup(String groupId) async {
    try {
      await context
          .read<SessionAccessDataSource>()
          .unlinkGroup(widget.sessionId, groupId);
      widget.onAccessChanged();
      await _load();
    } catch (_) {
      widget.onAccessChanged();
    }
  }

  Future<void> _linkGroup(String groupId) async {
    try {
      await context.read<SessionAccessDataSource>().linkGroup(
            widget.sessionId,
            groupId: groupId,
          );
      widget.onAccessChanged();
      await _load();
    } catch (_) {}
  }

  void _showAddPersonDialog(BuildContext context) {
    final emailCtrl = TextEditingController();
    String? error;
    bool sending = false;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Add Person'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: emailCtrl,
                autofocus: true,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Email address'),
              ),
              const SizedBox(height: AppDesignSystem.spacingXs),
              Text(
                'Sends an invite link to grant access to this session.',
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              if (error != null) ...[
                const SizedBox(height: AppDesignSystem.spacingSm),
                Text(
                  error!,
                  style:
                      textTheme.bodySmall?.copyWith(color: colorScheme.error),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: sending ? null : () => Navigator.of(ctx).pop(),
              child: Text(
                'Cancel',
                style: textTheme.labelLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: sending
                  ? null
                  : () async {
                      final email = emailCtrl.text.trim();
                      if (email.isEmpty || !email.contains('@')) {
                        setDialogState(
                            () => error = 'Please enter a valid email address.');
                        return;
                      }
                      setDialogState(() => sending = true);
                      try {
                        await context
                            .read<SessionInvitesDataSource>()
                            .createInvite(widget.sessionId, email: email);
                        if (ctx.mounted) Navigator.of(ctx).pop();
                        widget.onAccessChanged();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Invite sent to $email')),
                          );
                        }
                      } catch (_) {
                        setDialogState(() {
                          sending = false;
                          error = 'Failed to send invite. Please try again.';
                        });
                      }
                    },
              child: sending
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Send invite'),
            ),
          ],
        ),
      ),
    );
  }

  void _showLinkGroupDialog(
      BuildContext context, List<GroupResponse> available) {
    if (available.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No groups available to link.')),
      );
      return;
    }

    showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Link a Group'),
        children: available
            .map(
              (g) => SimpleDialogOption(
                onPressed: () => Navigator.pop(ctx, g.id),
                child: Text(g.name),
              ),
            )
            .toList(),
      ),
    ).then((groupId) {
      if (groupId != null) _linkGroup(groupId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final originsByUser = _originsByUser;
    final linkedGroupIds = _linkedGroups.map((l) => l.groupId).toSet();

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      builder: (context, scrollCtrl) => Column(
        children: [
          // Handle
          Padding(
            padding: const EdgeInsets.symmetric(
                vertical: AppDesignSystem.spacingSm),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color:
                    colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Title row
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDesignSystem.spacingMd,
              vertical: AppDesignSystem.spacingXs,
            ),
            child: Row(
              children: [
                Text('Manage Access', style: textTheme.titleMedium),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Body
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Text(_error!,
                            style: textTheme.bodyMedium
                                ?.copyWith(color: colorScheme.error)))
                    : ListView(
                        controller: scrollCtrl,
                        padding: const EdgeInsets.all(
                            AppDesignSystem.spacingMd),
                        children: [
                          // ── Access list ───────────────────────────────
                          Row(
                            children: [
                              _SectionLabel('Who Has Access'),
                              const Spacer(),
                              TextButton.icon(
                                onPressed: () =>
                                    _showAddPersonDialog(context),
                                icon: const Icon(Icons.add, size: 16),
                                label: const Text('Add Person'),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppDesignSystem.spacingSm),
                          if (widget.accessList.isEmpty)
                            Text(
                              'No one has access yet.',
                              style: textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant),
                            )
                          else
                            ...widget.accessList.map((access) {
                              final userOrigins =
                                  originsByUser[access.userId] ?? [];
                              final hasDirect = userOrigins
                                  .any((o) => o.sourceType == 'direct');
                              final groupOrigins = userOrigins
                                  .where((o) => o.sourceType == 'group')
                                  .toList();
                              return _AccessRow(
                                access: access,
                                hasDirect: hasDirect,
                                groupOrigins: groupOrigins,
                                onRevoke:
                                    hasDirect ? () => _revokeAccess(access.userId) : null,
                              );
                            }),

                          const SizedBox(height: AppDesignSystem.spacingLg),

                          // ── Linked groups ─────────────────────────────
                          Consumer<GroupsController>(
                            builder: (context, groupsCtrl, _) {
                              final allGroups = groupsCtrl.state.groups;
                              final available = allGroups
                                  .where((g) =>
                                      !linkedGroupIds.contains(g.id))
                                  .toList();

                              return Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      _SectionLabel('Linked Groups'),
                                      const Spacer(),
                                      TextButton.icon(
                                        onPressed: () =>
                                            _showLinkGroupDialog(
                                                context, available),
                                        icon: const Icon(Icons.add,
                                            size: 16),
                                        label: const Text('Add Group'),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(
                                      height: AppDesignSystem.spacingSm),
                                  if (_linkedGroups.isEmpty)
                                    Text(
                                      'No groups linked. Adding a group grants access to all its members.',
                                      style: textTheme.bodySmall?.copyWith(
                                          color:
                                              colorScheme.onSurfaceVariant),
                                    )
                                  else
                                    ..._linkedGroups.map((link) {
                                      final group = allGroups
                                          .where(
                                              (g) => g.id == link.groupId)
                                          .firstOrNull;
                                      return _GroupLinkRow(
                                        groupName: group?.name ??
                                            _shortId(link.groupId),
                                        onUnlink: () =>
                                            _unlinkGroup(link.groupId),
                                      );
                                    }),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
          ),
        ],
      ),
    );
  }
}

class _AccessRow extends StatelessWidget {
  const _AccessRow({
    required this.access,
    required this.hasDirect,
    required this.groupOrigins,
    required this.onRevoke,
  });

  final SessionAccessResponse access;
  final bool hasDirect;
  final List<SessionAccessOriginResponse> groupOrigins;

  /// Non-null only when the user has a direct (invite-derived) origin.
  final VoidCallback? onRevoke;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    // TODO: replace with display name once access endpoint includes user details
    final label = _shortId(access.userId);

    return Padding(
      padding: const EdgeInsets.symmetric(
          vertical: AppDesignSystem.spacingXs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(Icons.person_outline,
              size: 16, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(label, style: textTheme.bodySmall),
                    const SizedBox(width: AppDesignSystem.spacingXs),
                    _RoleBadge(role: access.role),
                  ],
                ),
                if (hasDirect || groupOrigins.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Wrap(
                      spacing: 4,
                      children: [
                        if (hasDirect)
                          _OriginChip(label: 'invite'),
                        for (final _ in groupOrigins)
                          _OriginChip(label: 'group'),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          if (onRevoke != null)
            TextButton(
              onPressed: onRevoke,
              style: TextButton.styleFrom(
                foregroundColor: colorScheme.error,
                padding:
                    const EdgeInsets.symmetric(horizontal: 8),
              ),
              child: const Text('Revoke'),
            ),
        ],
      ),
    );
  }
}

class _GroupLinkRow extends StatelessWidget {
  const _GroupLinkRow({required this.groupName, required this.onUnlink});

  final String groupName;
  final VoidCallback onUnlink;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(
          vertical: AppDesignSystem.spacingXs),
      child: Row(
        children: [
          Icon(Icons.group_outlined,
              size: 16, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: 6),
          Expanded(
              child: Text(groupName, style: textTheme.bodySmall)),
          TextButton(
            onPressed: onUnlink,
            style: TextButton.styleFrom(
              foregroundColor: colorScheme.error,
              padding:
                  const EdgeInsets.symmetric(horizontal: 8),
            ),
            child: const Text('Unlink'),
          ),
        ],
      ),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  const _RoleBadge({required this.role});

  final String role;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isAdmin = role == 'admin';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: isAdmin
            ? colorScheme.primaryContainer
            : colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        _roleLabel(role),
        style: textTheme.labelSmall?.copyWith(
          color: isAdmin
              ? colorScheme.onPrimaryContainer
              : colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _OriginChip extends StatelessWidget {
  const _OriginChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: colorScheme.outline, width: 0.5),
      ),
      child: Text(
        label,
        style: textTheme.labelSmall?.copyWith(
          color: colorScheme.onSurfaceVariant,
          fontSize: 10,
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Text(
      title,
      style: textTheme.labelMedium?.copyWith(
        color: colorScheme.primary,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.5,
      ),
    );
  }
}

String _shortId(String id) => id.length > 12 ? '${id.substring(0, 12)}…' : id;

String _roleLabel(String role) => switch (role) {
      'admin' => 'Admin',
      'editor' => 'Editor',
      'viewer' => 'Viewer',
      _ => role,
    };

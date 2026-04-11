import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/exceptions/app_exceptions.dart';
import '../../../../shared/design_system/theme.dart';
import '../controllers/invitations_controller.dart';

/// Full-screen page listing all pending invitations for the current user.
///
/// Aggregates group invites and session invites into a single chronological
/// list. Each item shows a "Group" or "Routine" type label so the user
/// understands what they're accepting and what access it grants.
///
/// Accessed via `/invitations`, linked from the Groups page badge.
class PendingInvitationsPage extends StatefulWidget {
  const PendingInvitationsPage({super.key});

  @override
  State<PendingInvitationsPage> createState() => _PendingInvitationsPageState();
}

class _PendingInvitationsPageState extends State<PendingInvitationsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<InvitationsController>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Invitations'), centerTitle: true),
      body: Consumer<InvitationsController>(
        builder: (context, controller, _) {
          if (controller.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (controller.error != null) {
            return _buildError(controller);
          }

          if (controller.invites.isEmpty) {
            return _buildEmptyState();
          }

          return _buildList(controller);
        },
      ),
    );
  }

  Widget _buildList(InvitationsController controller) {
    return ListView.separated(
      padding: const EdgeInsets.all(AppDesignSystem.spacingMd),
      itemCount: controller.invites.length,
      separatorBuilder: (_, _) =>
          const SizedBox(height: AppDesignSystem.spacingSm),
      itemBuilder: (context, index) => _InviteCard(
        invite: controller.invites[index],
        onAccepted: (invite) => _onAccepted(invite),
      ),
    );
  }

  Widget _buildEmptyState() {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDesignSystem.spacingXl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.mail_outline,
              size: 64,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: AppDesignSystem.spacingMd),
            Text('No pending invitations', style: textTheme.titleLarge),
            const SizedBox(height: AppDesignSystem.spacingSm),
            Text(
              'Invitations to groups and routines will appear here.',
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError(InvitationsController controller) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDesignSystem.spacingXl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: colorScheme.error),
            const SizedBox(height: AppDesignSystem.spacingMd),
            Text(
              controller.error ?? 'Failed to load invitations.',
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDesignSystem.spacingLg),
            ElevatedButton(
              onPressed: controller.load,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  void _onAccepted(PendingInvite invite) {
    if (invite.type == PendingInviteType.group && invite.groupId != null) {
      context.go('/groups/${invite.groupId}');
    } else if (invite.sessionId != null) {
      context.go('/instances/${invite.sessionId}');
    }
  }
}

// ---------------------------------------------------------------------------

class _InviteCard extends StatefulWidget {
  const _InviteCard({required this.invite, required this.onAccepted});

  final PendingInvite invite;
  final void Function(PendingInvite) onAccepted;

  @override
  State<_InviteCard> createState() => _InviteCardState();
}

class _InviteCardState extends State<_InviteCard> {
  bool _isAccepting = false;
  String? _error;

  Future<void> _accept() async {
    setState(() {
      _isAccepting = true;
      _error = null;
    });
    try {
      await context.read<InvitationsController>().accept(widget.invite);
      if (!mounted) return;
      widget.onAccepted(widget.invite);
    } on AppException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _isAccepting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final invite = widget.invite;

    final isGroup = invite.type == PendingInviteType.group;
    final typeLabel = isGroup ? 'Group' : 'Routine';
    final typeIcon =
        isGroup ? Icons.group_outlined : Icons.library_music_outlined;
    final roleLabel =
        invite.role[0].toUpperCase() + invite.role.substring(1);

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(AppDesignSystem.spacingMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: colorScheme.secondaryContainer,
                    borderRadius:
                        BorderRadius.circular(AppDesignSystem.radiusSm),
                  ),
                  child: Icon(
                    typeIcon,
                    size: 20,
                    color: colorScheme.onSecondaryContainer,
                  ),
                ),
                const SizedBox(width: AppDesignSystem.spacingMd),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _TypeChip(label: typeLabel),
                          const SizedBox(width: AppDesignSystem.spacingXs),
                          Flexible(
                            child: Text(
                              invite.name,
                              style: textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'as $roleLabel',
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppDesignSystem.spacingSm),
                _isAccepting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : FilledButton.tonal(
                        onPressed: _accept,
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppDesignSystem.spacingMd,
                            vertical: AppDesignSystem.spacingXs,
                          ),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text('Accept'),
                      ),
              ],
            ),
            if (_error != null) ...[
              const SizedBox(height: AppDesignSystem.spacingXs),
              Text(
                _error!,
                style: textTheme.bodySmall
                    ?.copyWith(color: colorScheme.error),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _TypeChip extends StatelessWidget {
  const _TypeChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: textTheme.labelSmall?.copyWith(
          color: colorScheme.onPrimaryContainer,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

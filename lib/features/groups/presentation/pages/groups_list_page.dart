import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../shared/design_system/theme.dart';
import '../../../../shared/widgets/web_constrained_body.dart';
import '../../../invitations/presentation/controllers/invitations_controller.dart';
import '../controllers/groups_controller.dart';
import '../controllers/groups_state.dart';
import '../widgets/create_group_dialog.dart';
import '../widgets/group_card.dart';

/// Displays the list of groups the current user belongs to.
class GroupsListPage extends StatefulWidget {
  const GroupsListPage({super.key});

  @override
  State<GroupsListPage> createState() => _GroupsListPageState();
}

class _GroupsListPageState extends State<GroupsListPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GroupsController>().loadGroups();
      context.read<InvitationsController>().load();
    });
  }

  int get _pendingInviteCount =>
      context.watch<InvitationsController>().pendingCount;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: kIsWeb
          ? null
          : AppBar(
              title: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Groups'),
                  if (_pendingInviteCount > 0) ...[
                    const SizedBox(width: AppDesignSystem.spacingXs),
                    GestureDetector(
                      onTap: () => context.push('/invitations'),
                      child: Badge.count(count: _pendingInviteCount),
                    ),
                  ],
                ],
              ),
              centerTitle: true,
            ),
      body: Consumer<GroupsController>(
        builder: (context, controller, _) {
          final state = controller.state;

          Widget bodyContent;
          if (state.status == GroupsStatus.loading && state.groups.isEmpty) {
            bodyContent = const Center(child: CircularProgressIndicator());
          } else if (state.status == GroupsStatus.error &&
              state.groups.isEmpty) {
            bodyContent = _buildErrorState(state.errorMessage, controller);
          } else if (state.groups.isEmpty) {
            bodyContent = _buildEmptyState();
          } else {
            bodyContent = _buildList(context, controller);
          }

          return WebConstrainedBody(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (kIsWeb) _buildWebHeader(context),
                Expanded(child: bodyContent),
              ],
            ),
          );
        },
      ),
      floatingActionButton: kIsWeb
          ? null
          : FloatingActionButton(
              onPressed: () => _showCreateGroupDialog(context),
              child: const Icon(Icons.add),
            ),
    );
  }

  /// Page heading + add button shown on web in place of the suppressed AppBar.
  Widget _buildWebHeader(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppDesignSystem.spacingMd,
        AppDesignSystem.spacingLg,
        AppDesignSystem.spacingMd,
        AppDesignSystem.spacingSm,
      ),
      child: Row(
        children: [
          Text('Groups', style: textTheme.headlineSmall),
          if (_pendingInviteCount > 0) ...[
            const SizedBox(width: AppDesignSystem.spacingXs),
            GestureDetector(
              onTap: () => context.push('/invitations'),
              child: Badge.count(count: _pendingInviteCount),
            ),
          ],
          const Spacer(),
          TextButton.icon(
            onPressed: () => _showCreateGroupDialog(context),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('New Group'),
          ),
        ],
      ),
    );
  }

  Widget _buildList(BuildContext context, GroupsController controller) {
    final groups = controller.state.groups;

    // Web: responsive grid (2 cols at ≥600px) with scrollbar, no pull-to-refresh.
    if (kIsWeb) {
      return LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth >= 600) {
            return Scrollbar(
              child: GridView.builder(
                padding: const EdgeInsets.all(AppDesignSystem.spacingMd),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: AppDesignSystem.spacingSm,
                  mainAxisSpacing: AppDesignSystem.spacingSm,
                  mainAxisExtent: 88,
                ),
                itemCount: groups.length,
                itemBuilder: (context, index) {
                  final group = groups[index];
                  return GroupCard(
                    group: group,
                    onTap: () => context.push('/groups/${group.id}'),
                  );
                },
              ),
            );
          }
          return Scrollbar(
            child: ListView.separated(
              padding: const EdgeInsets.all(AppDesignSystem.spacingMd),
              itemCount: groups.length,
              separatorBuilder: (_, _) =>
                  const SizedBox(height: AppDesignSystem.spacingSm),
              itemBuilder: (context, index) {
                final group = groups[index];
                return GroupCard(
                  group: group,
                  onTap: () => context.push('/groups/${group.id}'),
                );
              },
            ),
          );
        },
      );
    }

    // Native: pull-to-refresh + single-column list.
    return RefreshIndicator(
      onRefresh: controller.loadGroups,
      child: ListView.separated(
        padding: const EdgeInsets.all(AppDesignSystem.spacingMd),
        itemCount: groups.length,
        separatorBuilder: (_, _) =>
            const SizedBox(height: AppDesignSystem.spacingSm),
        itemBuilder: (context, index) {
          final group = groups[index];
          return GroupCard(
            group: group,
            onTap: () => context.push('/groups/${group.id}'),
          );
        },
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
              Icons.group_outlined,
              size: 64,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: AppDesignSystem.spacingMd),
            Text('No groups yet', style: textTheme.titleLarge),
            const SizedBox(height: AppDesignSystem.spacingSm),
            Text(
              'Create a group to start collaborating.',
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDesignSystem.spacingLg),
            ElevatedButton.icon(
              onPressed: () => _showCreateGroupDialog(context),
              icon: const Icon(Icons.add),
              label: const Text('Create Group'),
            ),
            const SizedBox(height: AppDesignSystem.spacingSm),
            TextButton(
              onPressed: () => context.push('/invitations'),
              child: const Text('View pending invitations'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String? message, GroupsController controller) {
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
              message ?? 'Failed to load groups.',
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDesignSystem.spacingLg),
            ElevatedButton(
              onPressed: controller.loadGroups,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateGroupDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => CreateGroupDialog(
        onSubmit: (name, description) async {
          final controller = context.read<GroupsController>();
          return controller.createGroup(name: name, description: description);
        },
      ),
    );
  }
}

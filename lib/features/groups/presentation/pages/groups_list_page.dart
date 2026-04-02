import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../shared/design_system/theme.dart';
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
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Groups'), centerTitle: true),
      body: Consumer<GroupsController>(
        builder: (context, controller, _) {
          final state = controller.state;

          if (state.status == GroupsStatus.loading && state.groups.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.status == GroupsStatus.error && state.groups.isEmpty) {
            return _buildErrorState(state.errorMessage, controller);
          }

          if (state.groups.isEmpty) {
            return _buildEmptyState();
          }

          return RefreshIndicator(
            onRefresh: controller.loadGroups,
            child: ListView.separated(
              padding: const EdgeInsets.all(AppDesignSystem.spacingMd),
              itemCount: state.groups.length,
              separatorBuilder: (_, _) =>
                  const SizedBox(height: AppDesignSystem.spacingSm),
              itemBuilder: (context, index) {
                final group = state.groups[index];
                return GroupCard(
                  group: group,
                  onTap: () => context.push('/groups/${group.id}'),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateGroupDialog(context),
        child: const Icon(Icons.add),
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
            Text(
              'No groups yet',
              style: textTheme.titleLarge,
            ),
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
            Icon(
              Icons.error_outline,
              size: 64,
              color: colorScheme.error,
            ),
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

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../shared/design_system/theme.dart';
import '../../../../shared/widgets/web_constrained_body.dart';
import '../controllers/routines_feed_controller.dart';
import '../controllers/routines_feed_state.dart';
import '../widgets/create_routine_dialog.dart';
import '../widgets/routine_card.dart';
import '../widgets/session_card.dart';

/// Unified feed of owned routines and shared sessions.
class RoutinesListPage extends StatefulWidget {
  const RoutinesListPage({super.key});

  @override
  State<RoutinesListPage> createState() => _RoutinesListPageState();
}

class _RoutinesListPageState extends State<RoutinesListPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RoutinesFeedController>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: kIsWeb
          ? null
          : AppBar(title: const Text('Routines'), centerTitle: true),
      body: Consumer<RoutinesFeedController>(
        builder: (context, ctrl, _) {
          final state = ctrl.state;

          if (state.status == RoutinesFeedStatus.loading &&
              state.ownedItems.isEmpty &&
              state.sharedItems.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.status == RoutinesFeedStatus.error &&
              state.ownedItems.isEmpty &&
              state.sharedItems.isEmpty) {
            return Center(
              child: Text(
                state.errorMessage ?? 'Failed to load routines.',
                style:
                    textTheme.bodyMedium?.copyWith(color: colorScheme.error),
              ),
            );
          }

          return WebConstrainedBody(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (kIsWeb) _buildWebHeader(context, ctrl),
                _buildFilterChips(context, ctrl),
                Expanded(child: _buildFeed(context, ctrl)),
              ],
            ),
          );
        },
      ),
      floatingActionButton: kIsWeb
          ? null
          : FloatingActionButton(
              onPressed: () => _showCreateRoutineDialog(context),
              child: const Icon(Icons.add),
            ),
    );
  }

  Widget _buildWebHeader(BuildContext context, RoutinesFeedController ctrl) {
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
          Text('Routines', style: textTheme.headlineSmall),
          const Spacer(),
          TextButton.icon(
            onPressed: () => _showCreateRoutineDialog(context),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('New Routine'),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips(
      BuildContext context, RoutinesFeedController ctrl) {
    final state = ctrl.state;
    final filters = [
      RoutinesFeedFilter.all,
      RoutinesFeedFilter.owned,
      RoutinesFeedFilter.shared,
      if (state.hasArchivedSessions) RoutinesFeedFilter.archived,
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(
        horizontal: AppDesignSystem.spacingMd,
        vertical: AppDesignSystem.spacingSm,
      ),
      child: Row(
        children: [
          for (final filter in filters)
            Padding(
              padding: const EdgeInsets.only(right: AppDesignSystem.spacingXs),
              child: FilterChip(
                label: Text(_filterLabel(filter)),
                selected: state.filter == filter,
                onSelected: (_) => ctrl.setFilter(filter),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFeed(BuildContext context, RoutinesFeedController ctrl) {
    final state = ctrl.state;
    final items = state.visibleItems;

    if (items.isEmpty) {
      return _buildEmptyState(context, state.filter);
    }

    if (kIsWeb) {
      return LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth >= 600) {
            return Scrollbar(
              child: GridView.builder(
                padding: const EdgeInsets.all(AppDesignSystem.spacingMd),
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: AppDesignSystem.spacingSm,
                  mainAxisSpacing: AppDesignSystem.spacingSm,
                  mainAxisExtent: 72,
                ),
                itemCount: items.length,
                itemBuilder: (context, index) =>
                    _buildItem(context, items[index]),
              ),
            );
          }
          return Scrollbar(
            child: _buildListView(context, items),
          );
        },
      );
    }

    return RefreshIndicator(
      onRefresh: () => ctrl.load(),
      child: _buildListView(context, items),
    );
  }

  Widget _buildListView(
      BuildContext context, List<RoutinesFeedItem> items) {
    return ListView.separated(
      padding: const EdgeInsets.all(AppDesignSystem.spacingMd),
      itemCount: items.length,
      separatorBuilder: (_, _) =>
          const SizedBox(height: AppDesignSystem.spacingSm),
      itemBuilder: (context, index) => _buildItem(context, items[index]),
    );
  }

  Widget _buildItem(BuildContext context, RoutinesFeedItem item) {
    final ctrl = context.read<RoutinesFeedController>();
    return switch (item) {
      OwnedRoutineItem(:final routine) => RoutineCard(
          routine: routine,
          onTap: () => context.push('/routines/${routine.id}'),
        ),
      SharedSessionItem(:final session, :final isArchived) => SessionCard(
          session: session,
          isArchived: isArchived,
          onTap: () => context.push('/instances/${session.id}'),
          onArchive: isArchived ? null : () => ctrl.archiveSession(session.id),
          onUnarchive:
              isArchived ? () => ctrl.unarchiveSession(session.id) : null,
          onHide: () => _confirmHide(context, session.id),
        ),
    };
  }

  Future<void> _confirmHide(BuildContext context, String sessionId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove from your list?'),
        content: const Text(
          'This routine will be hidden from your list. '
          'Your access is not affected — you can still be added back.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      context.read<RoutinesFeedController>().hideSession(sessionId);
    }
  }

  Widget _buildEmptyState(
      BuildContext context, RoutinesFeedFilter filter) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final (icon, title, subtitle) = switch (filter) {
      RoutinesFeedFilter.all => (
          Icons.library_music_outlined,
          'No routines yet',
          kIsWeb
              ? 'Click + New Routine to get started.'
              : 'Tap + to create your first routine.',
        ),
      RoutinesFeedFilter.owned => (
          Icons.library_music_outlined,
          'No owned routines',
          kIsWeb
              ? 'Click + New Routine to create one.'
              : 'Tap + to create a routine.',
        ),
      RoutinesFeedFilter.shared => (
          Icons.group_outlined,
          'No shared routines',
          'Routines shared with you will appear here.',
        ),
      RoutinesFeedFilter.archived => (
          Icons.archive_outlined,
          'No archived routines',
          'Archived shared routines will appear here.',
        ),
    };

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64,
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
          ),
          const SizedBox(height: AppDesignSystem.spacingMd),
          Text(
            title,
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppDesignSystem.spacingSm),
          Text(subtitle, style: textTheme.bodySmall),
        ],
      ),
    );
  }

  String _filterLabel(RoutinesFeedFilter filter) => switch (filter) {
        RoutinesFeedFilter.all => 'All',
        RoutinesFeedFilter.owned => 'Owned',
        RoutinesFeedFilter.shared => 'Shared',
        RoutinesFeedFilter.archived => 'Archived',
      };

  void _showCreateRoutineDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => CreateRoutineDialog(
        onSubmit: (title, danceId) async {
          final ctrl = context.read<RoutinesFeedController>();
          final routine = await ctrl.createRoutine(
            title: title,
            danceId: danceId,
          );
          return routine != null;
        },
      ),
    );
  }
}

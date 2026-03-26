import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../features/groups/presentation/controllers/groups_controller.dart';
import '../../../../features/routines/presentation/controllers/routines_controller.dart';
import '../../../../features/routines/presentation/controllers/routines_state.dart';
import '../widgets/group_filter_chips.dart';
import '../widgets/routine_list_item.dart';

class RoutinesScreen extends StatefulWidget {
  const RoutinesScreen({super.key});

  @override
  State<RoutinesScreen> createState() => _RoutinesScreenState();
}

class _RoutinesScreenState extends State<RoutinesScreen> {
  int _selectedGroupIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RoutinesController>().loadRoutines();
      context.read<GroupsController>().loadGroups();
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Routines',
              style: textTheme.titleLarge?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Browse and open routines',
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        centerTitle: false,
        elevation: 0,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
      ),
      body: SafeArea(
        child: Consumer2<GroupsController, RoutinesController>(
          builder: (context, groupsCtrl, routinesCtrl, _) {
            final groups = groupsCtrl.state.groups;
            final groupNames = ['All', ...groups.map((g) => g.name)];

            final routines = routinesCtrl.state.routines;
            final isLoading =
                routinesCtrl.state.status == RoutinesStatus.loading;
            final hasError =
                routinesCtrl.state.status == RoutinesStatus.error;

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: GroupFilterChips(
                    groups: groupNames,
                    selectedIndex: _selectedGroupIndex,
                    onSelected: (i) =>
                        setState(() => _selectedGroupIndex = i),
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: _buildBody(
                    context,
                    routines: routines,
                    isLoading: isLoading,
                    hasError: hasError,
                    errorMessage: routinesCtrl.state.errorMessage,
                    onRefresh: () => routinesCtrl.loadRoutines(),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context, {
    required List routines,
    required bool isLoading,
    required bool hasError,
    String? errorMessage,
    required Future<void> Function() onRefresh,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (isLoading && routines.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (hasError) {
      return Center(
        child: Text(
          errorMessage ?? 'Failed to load routines.',
          style: textTheme.bodyMedium?.copyWith(color: colorScheme.error),
        ),
      );
    }

    if (routines.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.library_music_outlined,
              size: 64,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 16),
            Text(
              'No routines yet',
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return Consumer<RoutinesController>(
      builder: (context, ctrl, _) => RefreshIndicator(
        onRefresh: () => ctrl.loadRoutines(),
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          itemCount: ctrl.state.routines.length + 1,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            if (index == 0) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  'Routines',
                  style: textTheme.titleLarge?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              );
            }
            final routine = ctrl.state.routines[index - 1];
            return RoutineListItem(
              title: routine.title,
              subtitle: routine.danceId,
              onTap: () => context.push('/routines/${routine.id}'),
            );
          },
        ),
      ),
    );
  }
}

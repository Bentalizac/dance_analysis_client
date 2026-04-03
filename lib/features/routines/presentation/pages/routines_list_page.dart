import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../shared/design_system/theme.dart';
import '../../../../shared/widgets/web_constrained_body.dart';
import '../controllers/routines_controller.dart';
import '../controllers/routines_state.dart';
import '../widgets/create_routine_dialog.dart';
import '../widgets/routine_card.dart';

/// Top-level list of the current user's routines.
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
      context.read<RoutinesController>().loadRoutines();
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: kIsWeb
          ? null
          : AppBar(title: const Text('My Routines'), centerTitle: true),
      body: Consumer<RoutinesController>(
        builder: (context, ctrl, _) {
          final state = ctrl.state;

          if (state.status == RoutinesStatus.loading &&
              state.routines.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.status == RoutinesStatus.error) {
            return Center(
              child: Text(
                state.errorMessage ?? 'Failed to load routines.',
                style:
                    textTheme.bodyMedium?.copyWith(color: colorScheme.error),
              ),
            );
          }

          if (state.routines.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.library_music_outlined,
                    size: 64,
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: AppDesignSystem.spacingMd),
                  Text(
                    'No routines yet',
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppDesignSystem.spacingSm),
                  Text(
                    kIsWeb
                        ? 'Click + New Routine to get started.'
                        : 'Tap + to create your first routine.',
                    style: textTheme.bodySmall,
                  ),
                ],
              ),
            );
          }

          return WebConstrainedBody(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (kIsWeb) _buildWebHeader(context, ctrl),
                Expanded(child: _buildList(context, ctrl)),
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

  Widget _buildWebHeader(BuildContext context, RoutinesController ctrl) {
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
          Text('My Routines', style: textTheme.headlineSmall),
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

  Widget _buildList(BuildContext context, RoutinesController ctrl) {
    final routines = ctrl.state.routines;

    // Web: responsive grid + scrollbar, no pull-to-refresh.
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
                  mainAxisExtent: 72,
                ),
                itemCount: routines.length,
                itemBuilder: (context, index) {
                  final routine = routines[index];
                  return RoutineCard(
                    routine: routine,
                    onTap: () => context.push('/routines/${routine.id}'),
                  );
                },
              ),
            );
          }
          return Scrollbar(
            child: ListView.separated(
              padding: const EdgeInsets.all(AppDesignSystem.spacingMd),
              itemCount: routines.length,
              separatorBuilder: (_, _) =>
                  const SizedBox(height: AppDesignSystem.spacingSm),
              itemBuilder: (context, index) {
                final routine = routines[index];
                return RoutineCard(
                  routine: routine,
                  onTap: () => context.push('/routines/${routine.id}'),
                );
              },
            ),
          );
        },
      );
    }

    // Native: pull-to-refresh + single-column list.
    return RefreshIndicator(
      onRefresh: () => ctrl.loadRoutines(),
      child: ListView.separated(
        padding: const EdgeInsets.all(AppDesignSystem.spacingMd),
        itemCount: routines.length,
        separatorBuilder: (_, _) =>
            const SizedBox(height: AppDesignSystem.spacingSm),
        itemBuilder: (context, index) {
          final routine = routines[index];
          return RoutineCard(
            routine: routine,
            onTap: () => context.push('/routines/${routine.id}'),
          );
        },
      ),
    );
  }

  void _showCreateRoutineDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => CreateRoutineDialog(
        onSubmit: (title, danceId) async {
          final ctrl = context.read<RoutinesController>();
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

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../shared/design_system/theme.dart';
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
    return Scaffold(
      backgroundColor: AppDesignSystem.backgroundLight,
      appBar: AppBar(title: const Text('My Routines'), centerTitle: true),
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
                style: TextStyle(color: AppDesignSystem.errorRed),
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
                    color: AppDesignSystem.textSecondary.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: AppDesignSystem.spacingMd),
                  Text(
                    'No routines yet',
                    style: TextStyle(color: AppDesignSystem.textSecondary),
                  ),
                  const SizedBox(height: AppDesignSystem.spacingSm),
                  Text(
                    'Tap + to create your first routine.',
                    style: AppDesignSystem.smallTextStyle.copyWith(
                      color: AppDesignSystem.textSecondary,
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => ctrl.loadRoutines(),
            child: ListView.separated(
              padding: const EdgeInsets.all(AppDesignSystem.spacingMd),
              itemCount: state.routines.length,
              separatorBuilder: (_, _) =>
                  const SizedBox(height: AppDesignSystem.spacingSm),
              itemBuilder: (context, index) {
                final routine = state.routines[index];
                return RoutineCard(
                  routine: routine,
                  onTap: () => context.push('/routines/${routine.id}'),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateRoutineDialog(context),
        backgroundColor: AppDesignSystem.mainAccent,
        child: const Icon(Icons.add),
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

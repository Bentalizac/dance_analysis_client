import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../generated/api/models/routine_dancer_slot_response.dart';
import '../../../../shared/design_system/theme.dart';
import '../../../dancer_slots/presentation/controllers/dancer_slots_controller.dart';
import '../../../dancer_slots/presentation/controllers/dancer_slots_state.dart';
import '../../../routine_sessions/presentation/controllers/routine_sessions_controller.dart';
import '../../../routine_sessions/presentation/controllers/routine_sessions_state.dart';
import '../../../routine_sessions/presentation/widgets/session_card.dart';
import '../controllers/routines_controller.dart';

/// Shows routine detail: dancer slots and sessions list.
class RoutineDetailPage extends StatefulWidget {
  const RoutineDetailPage({super.key, required this.routineId});

  final String routineId;

  @override
  State<RoutineDetailPage> createState() => _RoutineDetailPageState();
}

class _RoutineDetailPageState extends State<RoutineDetailPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RoutinesController>().loadRoutineDetail(widget.routineId);
      context.read<DancerSlotsController>().loadSlots(widget.routineId);
      context.read<RoutineSessionsController>().loadRoutineSessions(
        widget.routineId,
      );
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<RoutinesController>(
      builder: (context, routinesCtrl, _) {
        final routine = routinesCtrl.state.selectedRoutine;

        return Scaffold(
          backgroundColor: AppDesignSystem.backgroundLight,
          appBar: AppBar(
            title: Text(routine?.title ?? 'Routine'),
            centerTitle: true,
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: AppDesignSystem.mainAccent,
              labelColor: AppDesignSystem.mainAccent,
              unselectedLabelColor: AppDesignSystem.textSecondary,
              tabs: const [
                Tab(text: 'Dancer Slots'),
                Tab(text: 'Sessions'),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _SlotsTab(routineId: widget.routineId),
              _SessionsTab(routineId: widget.routineId),
            ],
          ),
          floatingActionButton: AnimatedBuilder(
            animation: _tabController,
            builder: (context, _) {
              if (_tabController.index == 0) {
                return FloatingActionButton(
                  onPressed: () => _showAddSlotDialog(context),
                  backgroundColor: AppDesignSystem.mainAccent,
                  child: const Icon(Icons.person_add),
                );
              }
              return FloatingActionButton(
                onPressed: () => _showCreateSessionDialog(context),
                backgroundColor: AppDesignSystem.mainAccent,
                child: const Icon(Icons.add),
              );
            },
          ),
        );
      },
    );
  }

  void _showAddSlotDialog(BuildContext context) {
    final labelCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppDesignSystem.backgroundMedium,
        title: Text(
          'Add Dancer Slot',
          style: TextStyle(color: AppDesignSystem.textPrimary),
        ),
        content: TextField(
          controller: labelCtrl,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Slot Label',
            hintText: 'e.g. Lead, Follow, A, B',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppDesignSystem.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              final label = labelCtrl.text.trim();
              if (label.isEmpty) return;
              Navigator.of(ctx).pop();
              await context.read<DancerSlotsController>().addSlot(
                widget.routineId,
                label: label,
              );
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showCreateSessionDialog(BuildContext context) {
    final labelCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppDesignSystem.backgroundMedium,
        title: Text(
          'New Session',
          style: TextStyle(color: AppDesignSystem.textPrimary),
        ),
        content: TextField(
          controller: labelCtrl,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Session Label (optional)',
            hintText: 'e.g. Practice with Alex',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppDesignSystem.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              final label = labelCtrl.text.trim();
              Navigator.of(ctx).pop();
              final session = await context
                  .read<RoutineSessionsController>()
                  .createSession(
                    widget.routineId,
                    label: label.isEmpty ? null : label,
                  );
              if (session != null && context.mounted) {
                context.push('/sessions/${session.id}');
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}

class _SlotsTab extends StatelessWidget {
  const _SlotsTab({required this.routineId});

  final String routineId;

  @override
  Widget build(BuildContext context) {
    return Consumer<DancerSlotsController>(
      builder: (context, ctrl, _) {
        if (ctrl.state.status == DancerSlotsStatus.loading &&
            ctrl.state.slots.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        final slots = ctrl.state.slots;
        if (slots.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.person_outline,
                  size: 64,
                  color: AppDesignSystem.textSecondary.withValues(alpha: 0.5),
                ),
                const SizedBox(height: AppDesignSystem.spacingMd),
                Text(
                  'No dancer slots yet',
                  style: TextStyle(color: AppDesignSystem.textSecondary),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => ctrl.loadSlots(routineId),
          child: ListView.separated(
            padding: const EdgeInsets.all(AppDesignSystem.spacingMd),
            itemCount: slots.length,
            separatorBuilder: (_, _) =>
                const SizedBox(height: AppDesignSystem.spacingSm),
            itemBuilder: (context, index) =>
                _SlotTile(slot: slots[index], routineId: routineId),
          ),
        );
      },
    );
  }
}

class _SlotTile extends StatelessWidget {
  const _SlotTile({required this.slot, required this.routineId});

  final RoutineDancerSlotResponse slot;
  final String routineId;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDesignSystem.spacingMd,
        vertical: AppDesignSystem.spacingSm,
      ),
      decoration: BoxDecoration(
        color: AppDesignSystem.backgroundMedium,
        borderRadius: BorderRadius.circular(AppDesignSystem.radiusSm),
        border: Border.all(color: AppDesignSystem.dividerLight, width: 1),
      ),
      child: Row(
        children: [
          Icon(Icons.person, color: AppDesignSystem.mainAccent, size: 20),
          const SizedBox(width: AppDesignSystem.spacingMd),
          Expanded(
            child: Text(
              slot.label,
              style: AppDesignSystem.feedbackStyle.copyWith(
                color: AppDesignSystem.textPrimary,
              ),
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.delete_outline,
              color: AppDesignSystem.errorRed,
              size: 20,
            ),
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: AppDesignSystem.backgroundMedium,
                  title: Text(
                    'Remove slot?',
                    style: TextStyle(color: AppDesignSystem.textPrimary),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: Text(
                        'Remove',
                        style: TextStyle(color: AppDesignSystem.errorRed),
                      ),
                    ),
                  ],
                ),
              );
              if (confirmed == true && context.mounted) {
                context.read<DancerSlotsController>().deleteSlot(
                  routineId,
                  slot.id,
                );
              }
            },
          ),
        ],
      ),
    );
  }
}

class _SessionsTab extends StatelessWidget {
  const _SessionsTab({required this.routineId});

  final String routineId;

  @override
  Widget build(BuildContext context) {
    return Consumer<RoutineSessionsController>(
      builder: (context, ctrl, _) {
        if (ctrl.state.status == RoutineSessionsStatus.loading &&
            ctrl.state.sessions.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        final sessions = ctrl.state.sessions;
        if (sessions.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.video_library_outlined,
                  size: 64,
                  color: AppDesignSystem.textSecondary.withValues(alpha: 0.5),
                ),
                const SizedBox(height: AppDesignSystem.spacingMd),
                Text(
                  'No sessions yet',
                  style: TextStyle(color: AppDesignSystem.textSecondary),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => ctrl.loadRoutineSessions(routineId),
          child: ListView.separated(
            padding: const EdgeInsets.all(AppDesignSystem.spacingMd),
            itemCount: sessions.length,
            separatorBuilder: (_, _) =>
                const SizedBox(height: AppDesignSystem.spacingSm),
            itemBuilder: (context, index) {
              final session = sessions[index];
              return SessionCard(
                session: session,
                onTap: () => context.push('/sessions/${session.id}'),
              );
            },
          ),
        );
      },
    );
  }
}

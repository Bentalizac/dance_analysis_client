import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../generated/api/models/group_membership_response.dart';
import '../../../../shared/design_system/theme.dart';
import '../../../../shared/widgets/web_constrained_body.dart';
import '../../../group_invites/presentation/widgets/create_invite_dialog.dart';
import '../../../group_invites/presentation/widgets/invites_tab.dart';
import '../../../routine_instances/presentation/controllers/routine_instances_controller.dart';
import '../../../routine_instances/presentation/controllers/routine_instances_state.dart';
import '../../../routine_instances/presentation/widgets/create_instance_in_group_dialog.dart';
import '../../../routine_instances/presentation/widgets/instance_card.dart';
import '../../../routines/presentation/controllers/routines_controller.dart';
import '../controllers/groups_controller.dart';
import '../controllers/groups_state.dart';
import '../../../../shared/services/auth_service.dart';

/// Shows group details with tabs: Routines, Members, Invites.
class GroupDetailPage extends StatefulWidget {
  const GroupDetailPage({super.key, required this.groupId});

  final String groupId;

  @override
  State<GroupDetailPage> createState() => _GroupDetailPageState();
}

class _GroupDetailPageState extends State<GroupDetailPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GroupsController>().loadGroupDetail(widget.groupId);
      context.read<RoutineInstancesController>().loadGroupInstances(
        widget.groupId,
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
    return Consumer<GroupsController>(
      builder: (context, groupsCtrl, _) {
        final state = groupsCtrl.state;
        final group = state.selectedGroup;

        return Scaffold(
          appBar: AppBar(
            title: Text(group?.name ?? 'Group'),
            centerTitle: true,
            // On web the FAB is replaced by a tab-aware action in the AppBar.
            actions: kIsWeb
                ? [
                    AnimatedBuilder(
                      animation: _tabController,
                      builder: (context, _) {
                        switch (_tabController.index) {
                          case 0:
                            return IconButton(
                              icon: const Icon(Icons.add),
                              tooltip: 'Add Routine',
                              onPressed: () =>
                                  _showCreateInstanceDialog(context),
                            );
                          case 2:
                            return IconButton(
                              icon: const Icon(Icons.person_add),
                              tooltip: 'Invite Member',
                              onPressed: () =>
                                  _showCreateInviteDialog(context),
                            );
                          default:
                            return const SizedBox.shrink();
                        }
                      },
                    ),
                  ]
                : null,
            bottom: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Routines'),
                Tab(text: 'Members'),
                Tab(text: 'Invites'),
              ],
            ),
          ),
          body: state.status == GroupsStatus.loading && group == null
              ? const Center(child: CircularProgressIndicator())
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _RoutinesTab(groupId: widget.groupId),
                    _MembersTab(
                      members: state.members,
                      groupId: widget.groupId,
                      groupsController: groupsCtrl,
                    ),
                    InvitesTab(groupId: widget.groupId),
                  ],
                ),
          floatingActionButton: kIsWeb ? null : _buildFab(),
        );
      },
    );
  }

  Widget _buildFab() {
    return AnimatedBuilder(
      animation: _tabController,
      builder: (context, _) {
        switch (_tabController.index) {
          case 0:
            return FloatingActionButton(
              onPressed: () => _showCreateInstanceDialog(context),
              child: const Icon(Icons.add),
            );
          case 2:
            return FloatingActionButton(
              onPressed: () => _showCreateInviteDialog(context),
              child: const Icon(Icons.person_add),
            );
          default:
            return const SizedBox.shrink();
        }
      },
    );
  }

  void _showCreateInstanceDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => CreateInstanceInGroupDialog(
        onSubmit: (title, danceId) async {
          final routinesCtrl = context.read<RoutinesController>();
          final instancesCtrl = context.read<RoutineInstancesController>();

          final routine = await routinesCtrl.createRoutine(
            title: title,
            danceId: danceId,
          );
          if (routine == null) return false;

          final instance = await instancesCtrl.createInstance(routine.id);
          if (instance == null) return false;

          await instancesCtrl.loadGroupInstances(widget.groupId);
          if (context.mounted) {
            context.push('/instances/${instance.id}');
          }
          return true;
        },
      ),
    );
  }

  void _showCreateInviteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => CreateInviteDialog(groupId: widget.groupId),
    );
  }
}

/// Routines tab within GroupDetailPage.
class _RoutinesTab extends StatelessWidget {
  const _RoutinesTab({required this.groupId});

  final String groupId;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return WebConstrainedBody(
      child: Consumer<RoutineInstancesController>(
        builder: (context, ctrl, _) {
          if (ctrl.state.status == RoutineInstancesStatus.loading &&
              ctrl.state.instances.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          final instances = ctrl.state.instances;
          if (instances.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.video_library_outlined,
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
                ],
              ),
            );
          }

          final list = ListView.separated(
            padding: const EdgeInsets.all(AppDesignSystem.spacingMd),
            itemCount: instances.length,
            separatorBuilder: (_, _) =>
                const SizedBox(height: AppDesignSystem.spacingSm),
            itemBuilder: (context, index) {
              final instance = instances[index];
              return InstanceCard(
                instance: instance,
                onTap: () => context.push('/instances/${instance.id}'),
              );
            },
          );

          if (kIsWeb) return Scrollbar(child: list);

          return RefreshIndicator(
            onRefresh: () => ctrl.loadGroupInstances(groupId),
            child: list,
          );
        },
      ),
    );
  }
}

/// Members tab within GroupDetailPage.
class _MembersTab extends StatelessWidget {
  const _MembersTab({
    required this.members,
    required this.groupId,
    required this.groupsController,
  });

  final List<GroupMembershipResponse> members;
  final String groupId;
  final GroupsController groupsController;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final currentUserId = context.read<AuthService>().currentUser?.id;

    if (members.isEmpty) {
      return const Center(child: Text('No members.'));
    }

    return WebConstrainedBody(
      child: Scrollbar(
        child: ListView.builder(
          padding: const EdgeInsets.all(AppDesignSystem.spacingMd),
          itemCount: members.length,
          itemBuilder: (context, index) {
            final member = members[index];
            final isCurrentUser = member.userId == currentUserId;
            return ListTile(
              mouseCursor: SystemMouseCursors.basic,
              leading: CircleAvatar(
                backgroundColor: colorScheme.primaryContainer,
                child: Icon(Icons.person, color: colorScheme.primary),
              ),
              title: Text(
                isCurrentUser ? 'You' : member.username,
                style: textTheme.bodyMedium,
              ),
              subtitle:
                  Text(member.role.toString(), style: textTheme.bodySmall),
              trailing: member.role.toString() != 'owner'
                  ? IconButton(
                      icon: Icon(
                        Icons.remove_circle_outline,
                        color: colorScheme.error,
                      ),
                      onPressed: () async {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            constraints: kIsWeb
                                ? const BoxConstraints(maxWidth: 360)
                                : null,
                            title: const Text('Remove member?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                child: Text(
                                  'Remove',
                                  style: TextStyle(color: colorScheme.error),
                                ),
                              ),
                            ],
                          ),
                        );
                        if (confirmed == true) {
                          groupsController.removeMember(
                              groupId, member.userId);
                        }
                      },
                    )
                  : null,
            );
          },
        ),
      ),
    );
  }
}

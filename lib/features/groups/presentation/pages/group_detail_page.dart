import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../generated/api/models/group_membership_response.dart';
import '../../../../shared/design_system/theme.dart';
import '../../../group_invites/presentation/widgets/create_invite_dialog.dart';
import '../../../group_invites/presentation/widgets/invites_tab.dart';
import '../../../routine_sessions/presentation/controllers/routine_sessions_controller.dart';
import '../../../routine_sessions/presentation/controllers/routine_sessions_state.dart';
import '../../../routine_sessions/presentation/widgets/create_session_in_group_dialog.dart';
import '../../../routine_sessions/presentation/widgets/session_card.dart';
import '../../../routines/presentation/controllers/routines_controller.dart';
import '../controllers/groups_controller.dart';
import '../controllers/groups_state.dart';

/// Shows group details with tabs: Sessions, Members, Invites.
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
      context.read<RoutineSessionsController>().loadGroupSessions(
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
          backgroundColor: AppDesignSystem.backgroundLight,
          appBar: AppBar(
            title: Text(group?.name ?? 'Group'),
            centerTitle: true,
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: AppDesignSystem.mainAccent,
              labelColor: AppDesignSystem.mainAccent,
              unselectedLabelColor: AppDesignSystem.textSecondary,
              tabs: const [
                Tab(text: 'Sessions'),
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
                    _SessionsTab(groupId: widget.groupId),
                    _MembersTab(
                      members: state.members,
                      groupId: widget.groupId,
                      groupsController: groupsCtrl,
                    ),
                    InvitesTab(groupId: widget.groupId),
                  ],
                ),
          floatingActionButton: _buildFab(),
        );
      },
    );
  }

  Widget _buildFab() {
    return AnimatedBuilder(
      animation: _tabController,
      builder: (context, _) {
        switch (_tabController.index) {
          case 0: // Sessions
            return FloatingActionButton(
              onPressed: () => _showCreateSessionDialog(context),
              backgroundColor: AppDesignSystem.mainAccent,
              child: const Icon(Icons.add),
            );
          case 2: // Invites
            return FloatingActionButton(
              onPressed: () => _showCreateInviteDialog(context),
              backgroundColor: AppDesignSystem.mainAccent,
              child: const Icon(Icons.person_add),
            );
          default:
            return const SizedBox.shrink();
        }
      },
    );
  }

  void _showCreateSessionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => CreateSessionInGroupDialog(
        onSubmit: (title, danceId) async {
          // Capture controllers before any awaits
          final routinesCtrl = context.read<RoutinesController>();
          final sessionsCtrl = context.read<RoutineSessionsController>();

          // Step 1: Create the routine
          final routine = await routinesCtrl.createRoutine(
            title: title,
            danceId: danceId,
          );
          if (routine == null) return false;

          // Step 2: Create a session tied to this group
          final session = await sessionsCtrl.createSession(
            routine.id,
            groupId: widget.groupId,
          );
          if (session == null) return false;

          // Refresh the sessions list and navigate to the new session
          await sessionsCtrl.loadGroupSessions(widget.groupId);
          if (context.mounted) {
            context.push('/sessions/${session.id}');
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

/// Sessions tab within GroupDetailPage.
class _SessionsTab extends StatelessWidget {
  const _SessionsTab({required this.groupId});

  final String groupId;

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
          onRefresh: () => ctrl.loadGroupSessions(groupId),
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
    if (members.isEmpty) {
      return const Center(child: Text('No members.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppDesignSystem.spacingMd),
      itemCount: members.length,
      itemBuilder: (context, index) {
        final member = members[index];
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: AppDesignSystem.mainAccent.withValues(alpha: 0.2),

            child: Icon(Icons.person, color: AppDesignSystem.mainAccent),
          ),
          title: Text(
            'User ${member.userId}',
            style: TextStyle(color: AppDesignSystem.textPrimary),
          ),
          subtitle: Text(
            member.role.toString(),
            style: TextStyle(color: AppDesignSystem.textSecondary),
          ),
          trailing: member.role.toString() != 'owner'
              ? IconButton(
                  icon: Icon(
                    Icons.remove_circle_outline,
                    color: AppDesignSystem.errorRed,
                  ),
                  onPressed: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        backgroundColor: AppDesignSystem.backgroundMedium,
                        title: Text(
                          'Remove member?',
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
                    if (confirmed == true) {
                      groupsController.removeMember(groupId, member.userId);
                    }
                  },
                )
              : null,
        );
      },
    );
  }
}

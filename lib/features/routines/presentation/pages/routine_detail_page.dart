import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/exceptions/app_exceptions.dart';
import '../../../../generated/api/models/note_response.dart';
import '../../../../generated/api/models/note_source.dart';
import '../../../../generated/api/models/note_type.dart';
import '../../../../generated/api/models/routine_dancer_slot_response.dart';
import '../../../../generated/api/models/routine_response.dart';
import '../../../../generated/api/models/session_access_response.dart';
import '../../../../generated/api/models/session_participant_with_user_response.dart';
import '../../../../generated/api/models/video_response.dart';
import '../../../../shared/design_system/theme.dart';
import '../../../../shared/extensions/dance_style_extensions.dart';
import '../../../dancer_slots/presentation/controllers/dancer_slots_controller.dart';
import '../../../dances/presentation/controllers/dances_controller.dart';
import '../../../routine_instances/presentation/controllers/routine_instances_controller.dart';
import '../../../routine_notes/data/notes_data_source.dart';
import '../../../routine_notes/presentation/controllers/notes_controller.dart';
import '../../../routine_videos/data/videos_data_source.dart';
import '../../../routine_videos/presentation/controllers/videos_controller.dart';
import '../../../groups/presentation/controllers/groups_controller.dart';
import '../../../groups/presentation/widgets/manage_group_sheet.dart';
import '../../../session_access/data/session_access_data_source.dart';
import '../../../session_invites/data/session_invites_data_source.dart';
import '../../../session_participants/data/session_participants_data_source.dart';
import '../../../session_participants/presentation/controllers/session_participants_controller.dart';
import '../../../session_participants/presentation/controllers/session_participants_state.dart';
import '../../../../shared/services/auth_service.dart';
import '../controllers/routines_controller.dart';
import '../controllers/routines_feed_controller.dart';

/// Entry point — provides scoped controllers then delegates to content widget.
class RoutineDetailPage extends StatelessWidget {
  const RoutineDetailPage({super.key, required this.routineId});

  final String routineId;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (context) =>
              VideosController(dataSource: context.read<VideosDataSource>()),
        ),
        ChangeNotifierProvider(
          create: (context) =>
              NotesController(dataSource: context.read<NotesDataSource>()),
        ),
        ChangeNotifierProvider(
          create: (context) => SessionParticipantsController(
            participantsDataSource: context
                .read<SessionParticipantsDataSource>(),
            accessDataSource: context.read<SessionAccessDataSource>(),
          ),
        ),
      ],
      child: _RoutineDetailContent(routineId: routineId),
    );
  }
}

class _RoutineDetailContent extends StatefulWidget {
  const _RoutineDetailContent({required this.routineId});

  final String routineId;

  @override
  State<_RoutineDetailContent> createState() => _RoutineDetailContentState();
}

class _RoutineDetailContentState extends State<_RoutineDetailContent>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _sessionId;
  bool _sessionLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      context.read<RoutinesController>().loadRoutineDetail(widget.routineId);
      context.read<DancerSlotsController>().loadSlots(widget.routineId);
      context.read<DancesController>().loadDances();

      final session = await context
          .read<RoutineInstancesController>()
          .ensureDefaultSession(widget.routineId);
      if (!mounted) return;

      setState(() {
        _sessionId = session?.id;
        _sessionLoading = false;
      });

      if (session != null) {
        context.read<VideosController>().loadVideos(session.id);
        context.read<NotesController>().loadSessionNotes(session.id);
        context.read<SessionParticipantsController>().load(session.id);
      }
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
          appBar: AppBar(
            title: Text(routine?.title ?? 'Routine'),
            centerTitle: true,
            actions: [
              if (_sessionId != null)
                IconButton(
                  icon: const Icon(Icons.people_outline),
                  tooltip: 'Manage Access',
                  onPressed: () => _showManageAccessSheet(context),
                ),
              _RoutineOverflowMenu(
                routine: routine,
                onDelete: () => _deleteRoutine(context, routine),
              ),
            ],
            bottom: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Videos'),
                Tab(text: 'Notes'),
                Tab(text: 'Choreo'),
                Tab(text: 'Details'),
              ],
            ),
          ),
          body: _sessionLoading
              ? const Center(child: CircularProgressIndicator())
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _VideosTab(sessionId: _sessionId),
                    _NotesTab(sessionId: _sessionId),
                    const _ChoreoTab(),
                    _DetailsTab(
                      routineId: widget.routineId,
                      routine: routine,
                      sessionId: _sessionId,
                    ),
                  ],
                ),
          floatingActionButton: _sessionId == null
              ? null
              : AnimatedBuilder(
                  animation: _tabController,
                  builder: (context, _) => switch (_tabController.index) {
                    0 => FloatingActionButton(
                      onPressed: () =>
                          context.push('/instances/$_sessionId/upload'),
                      child: const Icon(Icons.upload),
                    ),
                    1 => FloatingActionButton(
                      onPressed: () => _showAddNoteDialog(context),
                      child: const Icon(Icons.note_add),
                    ),
                    _ => const SizedBox.shrink(),
                  },
                ),
        );
      },
    );
  }

  Future<void> _deleteRoutine(
    BuildContext context,
    RoutineResponse? routine,
  ) async {
    if (routine == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete routine?'),
        content: Text(
          'This will permanently delete "${routine.title}" and all its '
          'sessions, videos, and notes. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Delete',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      final deleted = await context.read<RoutinesController>().deleteRoutine(
        routine.id,
      );
      if (deleted && context.mounted) {
        // Reload the feed so the deleted routine disappears from the list.
        context.read<RoutinesFeedController>().load();
        context.pop();
      }
    }
  }

  void _showManageAccessSheet(BuildContext context) {
    final sessionId = _sessionId;
    if (sessionId == null) return;
    final castingCtrl = context.read<SessionParticipantsController>();
    ManageGroupSheet.show(
      context,
      sessionId: sessionId,
      accessList: castingCtrl.state.accessList,
      onAccessChanged: () => castingCtrl.load(sessionId),
    );
  }

  void _showAddNoteDialog(BuildContext context) {
    final sessionId = _sessionId;
    if (sessionId == null) return;

    final contentCtrl = TextEditingController();
    NoteType selectedType = NoteType.feedback;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Add Note'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<NoteType>(
                initialValue: selectedType,
                decoration: const InputDecoration(labelText: 'Note Type'),
                dropdownColor: colorScheme.surface,
                items: NoteType.$valuesDefined
                    .map(
                      (t) => DropdownMenuItem(
                        value: t,
                        child: Text(_noteTypeLabel(t)),
                      ),
                    )
                    .toList(),
                onChanged: (v) =>
                    setDialogState(() => selectedType = v ?? selectedType),
              ),
              const SizedBox(height: AppDesignSystem.spacingMd),
              TextField(
                controller: contentCtrl,
                autofocus: true,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Note'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(
                'Cancel',
                style: textTheme.labelLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                final contents = contentCtrl.text.trim();
                if (contents.isEmpty) return;
                Navigator.of(ctx).pop();
                await context.read<NotesController>().addSessionNote(
                  sessionId: sessionId,
                  noteType: selectedType,
                  contents: contents,
                );
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Videos tab
// ---------------------------------------------------------------------------

class _VideosTab extends StatelessWidget {
  const _VideosTab({required this.sessionId});

  final String? sessionId;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (sessionId == null) {
      return Center(
        child: Text(
          'Could not load videos.',
          style: textTheme.bodyMedium?.copyWith(color: colorScheme.error),
        ),
      );
    }

    return Consumer<VideosController>(
      builder: (context, ctrl, _) {
        if (ctrl.state.isLoading && ctrl.state.videos.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (ctrl.state.videos.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.videocam_off_outlined,
                  size: 64,
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                ),
                const SizedBox(height: AppDesignSystem.spacingMd),
                Text(
                  'No videos yet',
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppDesignSystem.spacingSm),
                Text(
                  'Tap the upload button to add one.',
                  style: textTheme.bodySmall,
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => ctrl.loadVideos(sessionId!),
          child: ListView.separated(
            padding: const EdgeInsets.all(AppDesignSystem.spacingMd),
            itemCount: ctrl.state.videos.length,
            separatorBuilder: (_, _) =>
                const SizedBox(height: AppDesignSystem.spacingSm),
            itemBuilder: (context, index) => _VideoTile(
              video: ctrl.state.videos[index],
              sessionId: sessionId!,
            ),
          ),
        );
      },
    );
  }
}

class _VideoTile extends StatelessWidget {
  const _VideoTile({required this.video, required this.sessionId});

  final VideoResponse video;
  final String sessionId;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return InkWell(
      onTap: () => context.push('/instances/$sessionId/videos/${video.id}'),
      borderRadius: BorderRadius.circular(AppDesignSystem.radiusSm),
      child: Container(
        padding: const EdgeInsets.all(AppDesignSystem.spacingMd),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(AppDesignSystem.radiusSm),
          border: Border.all(color: colorScheme.outline, width: 1),
        ),
        child: Row(
          children: [
            Icon(
              Icons.play_circle_outline,
              color: colorScheme.primary,
              size: 32,
            ),
            const SizedBox(width: AppDesignSystem.spacingMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    video.originalFilename ??
                        'Video ${video.id.substring(0, 8)}',
                    style: textTheme.bodyMedium,
                  ),
                  Text(
                    _formatDate(video.createdAt),
                    style: textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(
                Icons.delete_outline,
                color: colorScheme.error,
                size: 20,
              ),
              onPressed: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Delete video?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: Text(
                          'Delete',
                          style: TextStyle(color: colorScheme.error),
                        ),
                      ),
                    ],
                  ),
                );
                if (confirmed == true && context.mounted) {
                  context.read<VideosController>().deleteVideo(
                    sessionId,
                    video.id,
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) => '${dt.month}/${dt.day}/${dt.year}';
}

// ---------------------------------------------------------------------------
// Notes tab
// ---------------------------------------------------------------------------

class _NotesTab extends StatelessWidget {
  const _NotesTab({required this.sessionId});

  final String? sessionId;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (sessionId == null) {
      return Center(
        child: Text(
          'Could not load notes.',
          style: textTheme.bodyMedium?.copyWith(color: colorScheme.error),
        ),
      );
    }

    return Consumer<NotesController>(
      builder: (context, ctrl, _) {
        if (ctrl.state.isLoading && ctrl.state.notes.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (ctrl.state.notes.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.sticky_note_2_outlined,
                  size: 64,
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                ),
                const SizedBox(height: AppDesignSystem.spacingMd),
                Text(
                  'No notes yet',
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(AppDesignSystem.spacingMd),
          itemCount: ctrl.state.notes.length,
          separatorBuilder: (_, _) =>
              const SizedBox(height: AppDesignSystem.spacingSm),
          itemBuilder: (context, index) =>
              _NoteTile(note: ctrl.state.notes[index], sessionId: sessionId!),
        );
      },
    );
  }
}

class _NoteTile extends StatelessWidget {
  const _NoteTile({required this.note, required this.sessionId});

  final NoteResponse note;
  final String sessionId;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(AppDesignSystem.spacingMd),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppDesignSystem.radiusSm),
        border: Border.all(color: colorScheme.outline, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _NoteTypeBadge(note.noteType),
              if (note.source == NoteSource.ai) ...[
                const SizedBox(width: AppDesignSystem.spacingXs),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDesignSystem.spacingXs,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(
                      AppDesignSystem.radiusXs,
                    ),
                  ),
                  child: Text(
                    'AI',
                    style: textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSecondaryContainer,
                    ),
                  ),
                ),
              ],
              const Spacer(),
              IconButton(
                icon: Icon(
                  Icons.delete_outline,
                  color: colorScheme.error,
                  size: 16,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () => context.read<NotesController>().deleteNote(
                  sessionId,
                  note.id,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDesignSystem.spacingXs),
          Text(note.contents, style: textTheme.bodyMedium),
          if (note.videoId != null) ...[
            const SizedBox(height: AppDesignSystem.spacingSm),
            _VideoReference(note: note, sessionId: sessionId),
          ],
        ],
      ),
    );
  }
}

class _NoteTypeBadge extends StatelessWidget {
  const _NoteTypeBadge(this.type);

  final NoteType type;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final (bg, fg) = switch (type) {
      NoteType.critique => (
        colorScheme.errorContainer,
        colorScheme.onErrorContainer,
      ),
      NoteType.complement => (
        colorScheme.tertiaryContainer,
        colorScheme.onTertiaryContainer,
      ),
      _ => (colorScheme.primaryContainer, colorScheme.onPrimaryContainer),
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDesignSystem.spacingXs,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppDesignSystem.radiusXs),
      ),
      child: Text(
        _noteTypeLabel(type),
        style: textTheme.labelSmall?.copyWith(color: fg),
      ),
    );
  }
}

class _VideoReference extends StatelessWidget {
  const _VideoReference({required this.note, required this.sessionId});

  final NoteResponse note;
  final String sessionId;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (note.videoDeleted) {
      return Row(
        children: [
          Icon(
            Icons.videocam_off_outlined,
            size: 14,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: AppDesignSystem.spacingXs),
          Text(
            'Video deleted',
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      );
    }

    final label = note.videoTimestampMs != null
        ? 'Video at ${_formatTimestamp(note.videoTimestampMs!)}'
        : 'View video';

    return ActionChip(
      avatar: Icon(
        Icons.play_circle_outline,
        size: 16,
        color: colorScheme.primary,
      ),
      label: Text(label),
      onPressed: () =>
          context.push('/instances/$sessionId/videos/${note.videoId}'),
    );
  }

  String _formatTimestamp(int ms) {
    final s = ms ~/ 1000;
    return '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';
  }
}

// ---------------------------------------------------------------------------
// Choreo tab
// ---------------------------------------------------------------------------

class _ChoreoTab extends StatelessWidget {
  const _ChoreoTab();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDesignSystem.spacingXl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.queue_music_outlined,
              size: 64,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: AppDesignSystem.spacingMd),
            Text('Choreography', style: textTheme.titleMedium),
            const SizedBox(height: AppDesignSystem.spacingSm),
            Text(
              'Figure and step sequences are coming soon.',
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
}

// ---------------------------------------------------------------------------
// Details tab
// ---------------------------------------------------------------------------

class _DetailsTab extends StatelessWidget {
  const _DetailsTab({
    required this.routineId,
    required this.routine,
    required this.sessionId,
  });

  final String routineId;
  final RoutineResponse? routine;
  final String? sessionId;

  @override
  Widget build(BuildContext context) {
    return Consumer2<DancesController, DancerSlotsController>(
      builder: (context, dances, slots, _) {
        final dance = routine == null
            ? null
            : dances.state.dances
                  .where((d) => d.id == routine!.danceId)
                  .firstOrNull;

        return ListView(
          padding: const EdgeInsets.all(AppDesignSystem.spacingMd),
          children: [
            _SectionHeader('Routine Info'),
            _InfoRow(label: 'Title', value: routine?.title ?? '—'),
            _InfoRow(label: 'Style', value: dance?.style.displayName ?? '—'),
            _InfoRow(
              label: 'Tempo',
              value: dance != null ? '${dance.tempo} BPM' : '—',
            ),
            _InfoRow(label: 'Meter', value: dance?.meter ?? '—'),
            const SizedBox(height: AppDesignSystem.spacingLg),
            if (sessionId != null)
              _CastingSection(
                routineId: routineId,
                sessionId: sessionId!,
                slots: slots,
              ),
          ],
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Casting section (B2 + B3)
// ---------------------------------------------------------------------------

class _CastingSection extends StatelessWidget {
  const _CastingSection({
    required this.routineId,
    required this.sessionId,
    required this.slots,
  });

  final String routineId;
  final String sessionId;
  final DancerSlotsController slots;

  @override
  Widget build(BuildContext context) {
    return Consumer<SessionParticipantsController>(
      builder: (context, casting, _) {
        final state = casting.state;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Access section ────────────────────────────────────────────
            if (state.accessList.isNotEmpty) ...[
              _SectionHeader('Access'),
              ...state.accessList.map((a) {
                // Look up display name from participants when available.
                final participant = state.participants
                    .where((p) => p.userId == a.userId)
                    .firstOrNull;
                final displayName = participant?.userName ??
                    participant?.userEmail ??
                    _shortId(a.userId);
                return _AccessRow(access: a, displayName: displayName);
              }),
              const SizedBox(height: AppDesignSystem.spacingLg),
            ],

            // ── Roles section ─────────────────────────────────────────────
            Row(
              children: [
                _SectionHeader('Roles'),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => _showAddSlotDialog(context),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add slot'),
                ),
              ],
            ),
            if (state.status == SessionParticipantsStatus.loading &&
                state.participants.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(
                  vertical: AppDesignSystem.spacingMd,
                ),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (slots.state.slots.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: AppDesignSystem.spacingSm,
                ),
                child: Text(
                  'No slots yet — add one above.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              )
            else
              ...slots.state.slots.map(
                (slot) => _SlotRow(
                  slot: slot,
                  sessionId: sessionId,
                  routineId: routineId,
                  participant: state.participantForSlot(slot.id),
                ),
              ),

            // ── Available section ─────────────────────────────────────────
            const SizedBox(height: AppDesignSystem.spacingLg),
            _SectionHeader('Available'),
            const SizedBox(height: AppDesignSystem.spacingXs),
            Wrap(
              spacing: AppDesignSystem.spacingSm,
              runSpacing: AppDesignSystem.spacingXs,
              children: [
                ...state.availableUserIds.map(
                  (uid) =>
                      _AvailableUserChip(userId: uid, sessionId: sessionId),
                ),
                _InviteChip(
                  sessionId: sessionId,
                  linkedGroupIds: state.linkedGroupIds,
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  void _showAddSlotDialog(BuildContext context) {
    final labelCtrl = TextEditingController();
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Slot'),
        content: TextField(
          controller: labelCtrl,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Label',
            hintText: 'e.g. Lead, Follow, Alex',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Cancel',
              style: textTheme.labelLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              final label = labelCtrl.text.trim();
              if (label.isEmpty) return;
              Navigator.of(ctx).pop();
              await context.read<DancerSlotsController>().addSlot(
                routineId,
                label: label,
              );
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}

/// A role slot row with a drag target that accepts available user chips.
class _SlotRow extends StatelessWidget {
  const _SlotRow({
    required this.slot,
    required this.sessionId,
    required this.routineId,
    required this.participant,
  });

  final RoutineDancerSlotResponse slot;
  final String sessionId;
  final String routineId;
  final SessionParticipantWithUserResponse? participant;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          // Slot label
          SizedBox(
            width: 80,
            child: Text(
              slot.label,
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: AppDesignSystem.spacingSm),

          // Drop target / assigned chip
          Expanded(
            child: DragTarget<String>(
              onAcceptWithDetails: (details) {
                context.read<SessionParticipantsController>().assign(
                  sessionId,
                  userId: details.data,
                  slotId: slot.id,
                );
              },
              builder: (context, candidateData, _) {
                final isHovered = candidateData.isNotEmpty;

                if (participant != null) {
                  // Filled slot
                  final displayName =
                      participant!.userName ??
                      participant!.userEmail ??
                      _shortId(participant!.userId);

                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDesignSystem.spacingSm,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(
                        AppDesignSystem.radiusXs,
                      ),
                      border: Border.all(
                        color: isHovered
                            ? colorScheme.primary
                            : Colors.transparent,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Expanded(
                          child: Text(
                            displayName,
                            style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.onPrimaryContainer,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => context
                              .read<SessionParticipantsController>()
                              .unassign(sessionId, participant!.id),
                          child: Icon(
                            Icons.close,
                            size: 14,
                            color: colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // Empty drop target
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDesignSystem.spacingSm,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isHovered
                        ? colorScheme.primaryContainer.withValues(alpha: 0.4)
                        : colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(
                      AppDesignSystem.radiusXs,
                    ),
                    border: Border.all(
                      color: isHovered
                          ? colorScheme.primary
                          : colorScheme.outline,
                      width: isHovered ? 1.5 : 1,
                    ),
                  ),
                  child: Text(
                    'drag here',
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                );
              },
            ),
          ),

          // Remove slot button
          const SizedBox(width: AppDesignSystem.spacingXs),
          GestureDetector(
            onTap: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Remove slot?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: Text(
                        'Remove',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
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
            child: Icon(
              Icons.remove_circle_outline,
              size: 18,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// Draggable chip representing a user who has session access but no slot yet.
class _AvailableUserChip extends StatelessWidget {
  const _AvailableUserChip({required this.userId, required this.sessionId});

  final String userId;
  final String sessionId;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    // TODO: replace with display name once the access endpoint returns user details
    final label = _shortId(userId);

    return Draggable<String>(
      data: userId,
      feedback: Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(AppDesignSystem.radiusSm),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDesignSystem.spacingMd,
            vertical: AppDesignSystem.spacingSm,
          ),
          decoration: BoxDecoration(
            color: colorScheme.secondaryContainer,
            borderRadius: BorderRadius.circular(AppDesignSystem.radiusSm),
          ),
          child: Text(
            label,
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSecondaryContainer,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.4,
        child: _chipBody(context, colorScheme, textTheme, label),
      ),
      child: _chipBody(context, colorScheme, textTheme, label),
    );
  }

  Widget _chipBody(
    BuildContext context,
    ColorScheme colorScheme,
    TextTheme textTheme,
    String label,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDesignSystem.spacingMd,
        vertical: AppDesignSystem.spacingSm,
      ),
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(AppDesignSystem.radiusSm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.drag_indicator,
            size: 14,
            color: colorScheme.onSecondaryContainer,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSecondaryContainer,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Grey chip that opens the invite-by-email dialog.
class _InviteChip extends StatelessWidget {
  const _InviteChip({required this.sessionId, required this.linkedGroupIds});

  final String sessionId;
  final List<String> linkedGroupIds;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return GestureDetector(
      onTap: () => _showInviteDialog(context),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDesignSystem.spacingMd,
          vertical: AppDesignSystem.spacingSm,
        ),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppDesignSystem.radiusSm),
          border: Border.all(color: colorScheme.outline.withValues(alpha: 0.5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.person_add_outlined,
              size: 14,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 4),
            Text(
              'Invite',
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showInviteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) =>
          _InviteDialog(sessionId: sessionId, linkedGroupIds: linkedGroupIds),
    );
  }
}

/// Dialog for sending a group invite from the casting section.
class _InviteDialog extends StatefulWidget {
  const _InviteDialog({required this.sessionId, required this.linkedGroupIds});

  final String sessionId;
  final List<String> linkedGroupIds;

  @override
  State<_InviteDialog> createState() => _InviteDialogState();
}

class _InviteDialogState extends State<_InviteDialog> {
  final _emailCtrl = TextEditingController();
  String? _selectedGroupId;
  bool _sending = false;
  String? _error;
  _InviteMode _mode = _InviteMode.direct;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<GroupsController>().loadGroups();
    });
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    Widget content = Consumer<GroupsController>(
      builder: (context, groupsCtrl, _) {
        final allGroups = groupsCtrl.state.groups;
        // Exclude groups already linked to this session.
        final availableGroups = allGroups
            .where((g) => !widget.linkedGroupIds.contains(g.id))
            .toList();
        final hasUserGroups = allGroups.isNotEmpty;

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (hasUserGroups) ...[
              SegmentedButton<_InviteMode>(
                segments: const [
                  ButtonSegment<_InviteMode>(
                    value: _InviteMode.direct,
                    label: Text('Individual'),
                    icon: Icon(Icons.person_outline),
                  ),
                  ButtonSegment<_InviteMode>(
                    value: _InviteMode.group,
                    label: Text('Via group'),
                    icon: Icon(Icons.groups_outlined),
                  ),
                ],
                selected: {_mode},
                onSelectionChanged: _sending
                    ? null
                    : (selection) {
                        if (selection.isEmpty) return;
                        setState(() {
                          _mode = selection.first;
                          _error = null;
                          _selectedGroupId = null;
                        });
                      },
              ),
              const SizedBox(height: AppDesignSystem.spacingMd),
            ],
            if (_mode == _InviteMode.direct) ...[
              TextField(
                controller: _emailCtrl,
                autofocus: true,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Email address'),
              ),
              const SizedBox(height: AppDesignSystem.spacingXs),
              Text(
                'Sends an invite link to the email address.',
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ] else ...[
              if (availableGroups.isEmpty)
                Text(
                  'All your groups are already linked to this session.',
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                )
              else ...[
                DropdownButtonFormField<String>(
                  initialValue: _selectedGroupId,
                  decoration: const InputDecoration(labelText: 'Select group'),
                  dropdownColor: colorScheme.surface,
                  items: availableGroups
                      .map((g) =>
                          DropdownMenuItem(value: g.id, child: Text(g.name)))
                      .toList(),
                  onChanged: _sending
                      ? null
                      : (v) => setState(() => _selectedGroupId = v),
                ),
                const SizedBox(height: AppDesignSystem.spacingXs),
                Text(
                  'All members of this group will get access to this session.',
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
            if (_error != null) ...[
              const SizedBox(height: AppDesignSystem.spacingSm),
              Text(
                _error!,
                style: textTheme.bodySmall?.copyWith(color: colorScheme.error),
              ),
            ],
          ],
        );
      },
    );

    return AlertDialog(
      title: const Text('Invite dancer'),
      content: content,
      actions: [
        TextButton(
          onPressed: _sending ? null : () => Navigator.of(context).pop(),
          child: Text(
            'Cancel',
            style: textTheme.labelLarge?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: _sending ? null : _submit,
          child: _sending
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Send invite'),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    if (_mode == _InviteMode.direct) {
      final email = _emailCtrl.text.trim();
      if (email.isEmpty || !email.contains('@')) {
        setState(() => _error = 'Please enter a valid email address.');
        return;
      }

      setState(() {
        _sending = true;
        _error = null;
      });

      try {
        await context
            .read<SessionInvitesDataSource>()
            .createInvite(widget.sessionId, email: email);
        if (!mounted) return;
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Invite sent to $email')),
        );
      } on AppException catch (e) {
        if (!mounted) return;
        setState(() {
          _sending = false;
          _error = e.message;
        });
      }
    } else {
      // Group mode — link the selected group to the session.
      if (_selectedGroupId == null) {
        setState(() => _error = 'Please select a group.');
        return;
      }

      setState(() {
        _sending = true;
        _error = null;
      });

      try {
        await context
            .read<SessionAccessDataSource>()
            .linkGroup(widget.sessionId, groupId: _selectedGroupId!);
        if (!mounted) return;
        // Reload casting state so new members appear.
        context
            .read<SessionParticipantsController>()
            .load(widget.sessionId);
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Group linked. All members now have access.'),
          ),
        );
      } on AppException catch (e) {
        if (!mounted) return;
        setState(() {
          _sending = false;
          _error = e.message;
        });
      }
    }
  }
}

enum _InviteMode { group, direct }

/// Row showing a user's access role in the session.
class _AccessRow extends StatelessWidget {
  const _AccessRow({required this.access, required this.displayName});

  final SessionAccessResponse access;
  final String displayName;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final label = displayName;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(
            Icons.person_outline,
            size: 16,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: AppDesignSystem.spacingSm),
          Expanded(child: Text(label, style: textTheme.bodySmall)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: access.role == 'admin'
                  ? colorScheme.primaryContainer
                  : colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              access.role,
              style: textTheme.labelSmall?.copyWith(
                color: access.role == 'admin'
                    ? colorScheme.onPrimaryContainer
                    : colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _shortId(String id) => id.length > 8 ? id.substring(0, 8) : id;

// ---------------------------------------------------------------------------
// AppBar overflow menu
// ---------------------------------------------------------------------------

class _RoutineOverflowMenu extends StatelessWidget {
  const _RoutineOverflowMenu({required this.routine, required this.onDelete});

  final RoutineResponse? routine;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    if (routine == null) return const SizedBox.shrink();
    final currentUserId = context.read<AuthService>().currentUser?.id;
    final isOwner = routine!.createdBy == currentUserId;
    if (!isOwner) return const SizedBox.shrink();

    return PopupMenuButton<_RoutineAction>(
      onSelected: (action) {
        switch (action) {
          case _RoutineAction.delete:
            onDelete();
        }
      },
      itemBuilder: (_) => [
        PopupMenuItem(
          value: _RoutineAction.delete,
          child: Text(
            'Delete Routine',
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ),
      ],
    );
  }
}

enum _RoutineAction { delete }

// ---------------------------------------------------------------------------
// Shared helpers
// ---------------------------------------------------------------------------

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppDesignSystem.spacingSm),
      child: Text(
        title,
        style: textTheme.labelMedium?.copyWith(
          color: colorScheme.primary,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppDesignSystem.spacingXs),
      child: Row(
        children: [
          SizedBox(
            width: 72,
            child: Text(
              label,
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(child: Text(value, style: textTheme.bodyMedium)),
        ],
      ),
    );
  }
}

String _noteTypeLabel(NoteType type) => switch (type) {
  NoteType.critique => 'Critique',
  NoteType.feedback => 'Feedback',
  NoteType.complement => 'Complement',
  _ => type.toString(),
};

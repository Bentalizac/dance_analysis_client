import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../generated/api/models/note_response.dart';
import '../../../../generated/api/models/note_source.dart';
import '../../../../generated/api/models/note_type.dart';
import '../../../../generated/api/models/routine_dancer_slot_response.dart';
import '../../../../generated/api/models/routine_response.dart';
import '../../../../generated/api/models/video_response.dart';
import '../../../../shared/design_system/theme.dart';
import '../../../../shared/extensions/dance_style_extensions.dart';
import '../../../dancer_slots/presentation/controllers/dancer_slots_controller.dart';
import '../../../dancer_slots/presentation/controllers/dancer_slots_state.dart';
import '../../../dances/presentation/controllers/dances_controller.dart';
import '../../../routine_instances/presentation/controllers/routine_instances_controller.dart';
import '../../../routine_notes/data/notes_data_source.dart';
import '../../../routine_notes/presentation/controllers/notes_controller.dart';
import '../../../routine_videos/data/videos_data_source.dart';
import '../../../routine_videos/presentation/controllers/videos_controller.dart';
import '../controllers/routines_controller.dart';

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
                        routineId: widget.routineId, routine: routine),
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
                    .map((t) => DropdownMenuItem(
                          value: t,
                          child: Text(_noteTypeLabel(t)),
                        ))
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
      onTap: () =>
          context.push('/instances/$sessionId/videos/${video.id}'),
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
            Icon(Icons.play_circle_outline,
                color: colorScheme.primary, size: 32),
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
              icon: Icon(Icons.delete_outline,
                  color: colorScheme.error, size: 20),
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
          itemBuilder: (context, index) => _NoteTile(
            note: ctrl.state.notes[index],
            sessionId: sessionId!,
          ),
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
                    borderRadius:
                        BorderRadius.circular(AppDesignSystem.radiusXs),
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
                icon: Icon(Icons.delete_outline,
                    color: colorScheme.error, size: 16),
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
      NoteType.critique => (colorScheme.errorContainer, colorScheme.onErrorContainer),
      NoteType.complement => (colorScheme.tertiaryContainer, colorScheme.onTertiaryContainer),
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
          Icon(Icons.videocam_off_outlined,
              size: 14, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: AppDesignSystem.spacingXs),
          Text(
            'Video deleted',
            style: textTheme.bodySmall
                ?.copyWith(color: colorScheme.onSurfaceVariant),
          ),
        ],
      );
    }

    final label = note.videoTimestampMs != null
        ? 'Video at ${_formatTimestamp(note.videoTimestampMs!)}'
        : 'View video';

    return ActionChip(
      avatar: Icon(Icons.play_circle_outline,
          size: 16, color: colorScheme.primary),
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
  const _DetailsTab({required this.routineId, required this.routine});

  final String routineId;
  final RoutineResponse? routine;

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
            _InfoRow(
                label: 'Style',
                value: dance?.style.displayName ?? '—'),
            _InfoRow(
                label: 'Tempo',
                value: dance != null ? '${dance.tempo} BPM' : '—'),
            _InfoRow(label: 'Meter', value: dance?.meter ?? '—'),
            const SizedBox(height: AppDesignSystem.spacingLg),
            _DancersSection(routineId: routineId, slots: slots),
          ],
        );
      },
    );
  }
}

class _DancersSection extends StatelessWidget {
  const _DancersSection({required this.routineId, required this.slots});

  final String routineId;
  final DancerSlotsController slots;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _SectionHeader('Dancers'),
            const Spacer(),
            TextButton.icon(
              onPressed: () => _showAddDancerDialog(context),
              icon: const Icon(Icons.person_add_outlined, size: 18),
              label: const Text('Add'),
            ),
          ],
        ),
        if (slots.state.status == DancerSlotsStatus.loading &&
            slots.state.slots.isEmpty)
          const Center(child: CircularProgressIndicator())
        else if (slots.state.slots.isEmpty)
          Padding(
            padding:
                const EdgeInsets.symmetric(vertical: AppDesignSystem.spacingSm),
            child: Text(
              'No dancers added yet.',
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          )
        else
          ...slots.state.slots.map(
            (slot) => _DancerRow(slot: slot, routineId: routineId),
          ),
      ],
    );
  }

  void _showAddDancerDialog(BuildContext context) {
    final labelCtrl = TextEditingController();
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Dancer'),
        content: TextField(
          controller: labelCtrl,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Name',
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
              await context
                  .read<DancerSlotsController>()
                  .addSlot(routineId, label: label);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}

class _DancerRow extends StatelessWidget {
  const _DancerRow({required this.slot, required this.routineId});

  final RoutineDancerSlotResponse slot;
  final String routineId;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(Icons.person_outline, color: colorScheme.onSurfaceVariant, size: 20),
          const SizedBox(width: AppDesignSystem.spacingSm),
          Expanded(child: Text(slot.label, style: textTheme.bodyMedium)),
          IconButton(
            icon: Icon(Icons.remove_circle_outline,
                color: colorScheme.error, size: 18),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Remove dancer?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: Text('Remove',
                          style: TextStyle(color: colorScheme.error)),
                    ),
                  ],
                ),
              );
              if (confirmed == true && context.mounted) {
                context
                    .read<DancerSlotsController>()
                    .deleteSlot(routineId, slot.id);
              }
            },
          ),
        ],
      ),
    );
  }
}

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

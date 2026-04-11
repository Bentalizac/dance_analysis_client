import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../generated/api/models/note_response.dart';
import '../../../../generated/api/models/note_type.dart';
import '../../../../generated/api/models/video_response.dart';
import '../../../../shared/design_system/theme.dart';
import '../../../../shared/widgets/web_constrained_body.dart';
import '../../../routine_notes/data/notes_data_source.dart';
import '../../../routine_notes/presentation/controllers/notes_controller.dart';
import '../../../routine_videos/data/videos_data_source.dart';
import '../../../routine_videos/presentation/controllers/videos_controller.dart';
import '../../../session_access/data/session_access_data_source.dart';
import '../controllers/routine_instances_controller.dart';
import '../../../../shared/services/auth_service.dart';

/// Shows routine instance detail with Videos and Notes tabs.
///
/// [VideosController] and [NotesController] are scoped locally to this page
/// to prevent stale state when navigating between instances.
class InstanceDetailPage extends StatelessWidget {
  const InstanceDetailPage({super.key, required this.instanceId});

  final String instanceId;

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
      child: _InstanceDetailContent(instanceId: instanceId),
    );
  }
}

class _InstanceDetailContent extends StatefulWidget {
  const _InstanceDetailContent({required this.instanceId});

  final String instanceId;

  @override
  State<_InstanceDetailContent> createState() => _InstanceDetailContentState();
}

class _InstanceDetailContentState extends State<_InstanceDetailContent>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RoutineInstancesController>().loadInstanceDetail(
        widget.instanceId,
      );
      context.read<VideosController>().loadVideos(widget.instanceId);
      context.read<NotesController>().loadSessionNotes(widget.instanceId);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<RoutineInstancesController>(
      builder: (context, instancesCtrl, _) {
        final instance = instancesCtrl.state.selectedInstance;
        final title = instance?.label ?? 'Routine';

        return Scaffold(
          appBar: AppBar(
            title: Text(title),
            centerTitle: true,
            actions: [
              if (kIsWeb)
                AnimatedBuilder(
                  animation: _tabController,
                  builder: (context, _) => switch (_tabController.index) {
                    0 => IconButton(
                        icon: const Icon(Icons.upload),
                        tooltip: 'Upload Video',
                        onPressed: () => context
                            .push('/instances/${widget.instanceId}/upload'),
                      ),
                    1 => IconButton(
                        icon: const Icon(Icons.note_add),
                        tooltip: 'Add Note',
                        onPressed: () => _showAddNoteDialog(context),
                      ),
                    _ => const SizedBox.shrink(),
                  },
                ),
              _InstanceOverflowMenu(
                instance: instance,
                instanceId: widget.instanceId,
                onLeft: () => context.go('/routines'),
              ),
            ],
            bottom: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Videos'),
                Tab(text: 'Notes'),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _VideosTab(instanceId: widget.instanceId),
              _NotesTab(instanceId: widget.instanceId),
            ],
          ),
          floatingActionButton: kIsWeb
              ? null
              : AnimatedBuilder(
                  animation: _tabController,
                  builder: (context, _) {
                    if (_tabController.index == 0) {
                      return FloatingActionButton(
                        onPressed: () => context
                            .push('/instances/${widget.instanceId}/upload'),
                        child: const Icon(Icons.upload),
                      );
                    }
                    return FloatingActionButton(
                      onPressed: () => _showAddNoteDialog(context),
                      child: const Icon(Icons.note_add),
                    );
                  },
                ),
        );
      },
    );
  }

  void _showAddNoteDialog(BuildContext context) {
    final contentCtrl = TextEditingController();
    NoteType selectedType = NoteType.feedback;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          constraints:
              kIsWeb ? const BoxConstraints(maxWidth: 480) : null,
          title: const Text('Add Note'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<NoteType>(
                initialValue: selectedType,
                decoration: const InputDecoration(labelText: 'Note Type'),
                dropdownColor: colorScheme.surface,
                items: NoteType.values
                    .map((t) => DropdownMenuItem(value: t, child: Text(t.name)))
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
                  sessionId: widget.instanceId,
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

class _VideosTab extends StatelessWidget {
  const _VideosTab({required this.instanceId});

  final String instanceId;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

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
                  kIsWeb
                      ? 'Click the upload button to add one.'
                      : 'Tap the upload button to add one.',
                  style: textTheme.bodySmall,
                ),
              ],
            ),
          );
        }

        final list = ListView.separated(
          padding: const EdgeInsets.all(AppDesignSystem.spacingMd),
          itemCount: ctrl.state.videos.length,
          separatorBuilder: (_, _) =>
              const SizedBox(height: AppDesignSystem.spacingSm),
          itemBuilder: (context, index) {
            final video = ctrl.state.videos[index];
            return _VideoTile(video: video, instanceId: instanceId);
          },
        );

        if (kIsWeb) {
          return WebConstrainedBody(child: Scrollbar(child: list));
        }

        return WebConstrainedBody(
          child: RefreshIndicator(
            onRefresh: () => ctrl.loadVideos(instanceId),
            child: list,
          ),
        );
      },
    );
  }
}

class _VideoTile extends StatelessWidget {
  const _VideoTile({required this.video, required this.instanceId});

  final VideoResponse video;
  final String instanceId;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final currentUserId = context.read<AuthService>().currentUser?.id;

    return Container(
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
                  video.originalFilename ?? 'Video ${video.id.substring(0, 8)}',
                  style: textTheme.bodyMedium,
                ),
                Text(
                  _formatDate(video.createdAt),
                  style: textTheme.bodySmall,
                ),
              ],
            ),
          ),
          if (video.uploadedBy == currentUserId)
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
                    constraints:
                        kIsWeb ? const BoxConstraints(maxWidth: 360) : null,
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
                    instanceId,
                    video.id,
                  );
                }
              },
            ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) => '${dt.month}/${dt.day}/${dt.year}';
}

class _NotesTab extends StatelessWidget {
  const _NotesTab({required this.instanceId});

  final String instanceId;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

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

        final list = ListView.separated(
          padding: const EdgeInsets.all(AppDesignSystem.spacingMd),
          itemCount: ctrl.state.notes.length,
          separatorBuilder: (_, _) =>
              const SizedBox(height: AppDesignSystem.spacingSm),
          itemBuilder: (context, index) =>
              _NoteTile(note: ctrl.state.notes[index], instanceId: instanceId),
        );

        return WebConstrainedBody(
          child: kIsWeb ? Scrollbar(child: list) : list,
        );
      },
    );
  }
}

class _NoteTile extends StatelessWidget {
  const _NoteTile({required this.note, required this.instanceId});

  final NoteResponse note;
  final String instanceId;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final currentUserId = context.read<AuthService>().currentUser?.id;

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
              Icon(Icons.note, color: colorScheme.primary, size: 16),
              const SizedBox(width: AppDesignSystem.spacingXs),
              Text(
                note.noteType.name,
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.primary,
                ),
              ),
              if (note.videoTimestampMs != null) ...[
                const SizedBox(width: AppDesignSystem.spacingSm),
                Text(
                  _formatTimestamp(note.videoTimestampMs!),
                  style: textTheme.bodySmall,
                ),
              ],
              if (note.videoDeleted) ...[
                const SizedBox(width: AppDesignSystem.spacingSm),
                Text(
                  '(video deleted)',
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.error,
                  ),
                ),
              ],
              const Spacer(),
              if (note.authorId == currentUserId)
                IconButton(
                  icon: Icon(
                    Icons.delete_outline,
                    color: colorScheme.error,
                    size: 16,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => context.read<NotesController>().deleteNote(
                    instanceId,
                    note.id,
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppDesignSystem.spacingXs),
          Text(note.contents, style: textTheme.bodyMedium),
        ],
      ),
    );
  }

  String _formatTimestamp(int ms) {
    final seconds = ms ~/ 1000;
    final minutes = seconds ~/ 60;
    final remaining = seconds % 60;
    return '$minutes:${remaining.toString().padLeft(2, '0')}';
  }
}

// ---------------------------------------------------------------------------
// Overflow menu — leave session (non-owners only)
// ---------------------------------------------------------------------------

class _InstanceOverflowMenu extends StatelessWidget {
  const _InstanceOverflowMenu({
    required this.instance,
    required this.instanceId,
    required this.onLeft,
  });

  final dynamic instance; // RoutineSessionResponse?
  final String instanceId;

  /// Called after the user successfully leaves so the caller can navigate away.
  final VoidCallback onLeft;

  @override
  Widget build(BuildContext context) {
    final currentUserId = context.read<AuthService>().currentUser?.id;
    final ownerId = instance?.ownerId as String?;

    // Only show the menu to non-owners who have access.
    if (ownerId == null || ownerId == currentUserId) {
      return const SizedBox.shrink();
    }

    return PopupMenuButton<_InstanceAction>(
      onSelected: (action) {
        if (action == _InstanceAction.leave) {
          _confirmLeave(context, currentUserId!);
        }
      },
      itemBuilder: (_) => const [
        PopupMenuItem(
          value: _InstanceAction.leave,
          child: Text('Leave session'),
        ),
      ],
    );
  }

  Future<void> _confirmLeave(BuildContext context, String userId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Leave session?'),
        content: const Text(
          'You will lose access to this session. '
          'The session owner can add you back.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Leave'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      try {
        await context
            .read<SessionAccessDataSource>()
            .revokeAccess(instanceId, userId);
        if (context.mounted) onLeft();
      } catch (_) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to leave session.')),
          );
        }
      }
    }
  }
}

enum _InstanceAction { leave }

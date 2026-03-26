import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../generated/api/models/note_response.dart';
import '../../../../generated/api/models/note_type.dart';
import '../../../../generated/api/models/video_response.dart';
import '../../../../shared/design_system/theme.dart';
import '../../../routine_notes/data/notes_data_source.dart';
import '../../../routine_notes/presentation/controllers/notes_controller.dart';
import '../../../routine_videos/data/videos_data_source.dart';
import '../../../routine_videos/presentation/controllers/videos_controller.dart';
import '../controllers/routine_sessions_controller.dart';

/// Shows session detail with Videos and Notes tabs.
///
/// [VideosController] and [NotesController] are scoped locally to this page
/// to prevent stale state when navigating between sessions.
class SessionDetailPage extends StatelessWidget {
  const SessionDetailPage({super.key, required this.sessionId});

  final String sessionId;

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
      child: _SessionDetailContent(sessionId: sessionId),
    );
  }
}

class _SessionDetailContent extends StatefulWidget {
  const _SessionDetailContent({required this.sessionId});

  final String sessionId;

  @override
  State<_SessionDetailContent> createState() => _SessionDetailContentState();
}

class _SessionDetailContentState extends State<_SessionDetailContent>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RoutineSessionsController>().loadSessionDetail(
        widget.sessionId,
      );
      context.read<VideosController>().loadVideos(widget.sessionId);
      context.read<NotesController>().loadSessionNotes(widget.sessionId);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<RoutineSessionsController>(
      builder: (context, sessionsCtrl, _) {
        final session = sessionsCtrl.state.selectedSession;
        final title = session?.label ?? 'Session';

        return Scaffold(
          backgroundColor: AppDesignSystem.backgroundLight,
          appBar: AppBar(
            title: Text(title),
            centerTitle: true,
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: AppDesignSystem.mainAccent,
              labelColor: AppDesignSystem.mainAccent,
              unselectedLabelColor: AppDesignSystem.textSecondary,
              tabs: const [
                Tab(text: 'Videos'),
                Tab(text: 'Notes'),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _VideosTab(sessionId: widget.sessionId),
              _NotesTab(sessionId: widget.sessionId),
            ],
          ),
          floatingActionButton: AnimatedBuilder(
            animation: _tabController,
            builder: (context, _) {
              if (_tabController.index == 0) {
                return FloatingActionButton(
                  onPressed: () =>
                      context.push('/sessions/${widget.sessionId}/upload'),
                  backgroundColor: AppDesignSystem.mainAccent,
                  child: const Icon(Icons.upload),
                );
              }
              return FloatingActionButton(
                onPressed: () => _showAddNoteDialog(context),
                backgroundColor: AppDesignSystem.mainAccent,
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

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppDesignSystem.backgroundMedium,
          title: Text(
            'Add Note',
            style: TextStyle(color: AppDesignSystem.textPrimary),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<NoteType>(
                initialValue: selectedType,
                decoration: const InputDecoration(labelText: 'Note Type'),
                dropdownColor: AppDesignSystem.backgroundMedium,
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
                style: TextStyle(color: AppDesignSystem.textSecondary),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                final contents = contentCtrl.text.trim();
                if (contents.isEmpty) return;
                Navigator.of(ctx).pop();
                await context.read<NotesController>().addSessionNote(
                  sessionId: widget.sessionId,
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
  const _VideosTab({required this.sessionId});

  final String sessionId;

  @override
  Widget build(BuildContext context) {
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
                  color: AppDesignSystem.textSecondary.withValues(alpha: 0.5),
                ),
                const SizedBox(height: AppDesignSystem.spacingMd),
                Text(
                  'No videos yet',
                  style: TextStyle(color: AppDesignSystem.textSecondary),
                ),
                const SizedBox(height: AppDesignSystem.spacingSm),
                Text(
                  'Tap the upload button to add one.',
                  style: AppDesignSystem.smallTextStyle.copyWith(
                    color: AppDesignSystem.textSecondary,
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => ctrl.loadVideos(sessionId),
          child: ListView.separated(
            padding: const EdgeInsets.all(AppDesignSystem.spacingMd),
            itemCount: ctrl.state.videos.length,
            separatorBuilder: (_, _) =>
                const SizedBox(height: AppDesignSystem.spacingSm),
            itemBuilder: (context, index) {
              final video = ctrl.state.videos[index];
              return _VideoTile(video: video, sessionId: sessionId);
            },
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
    return Container(
      padding: const EdgeInsets.all(AppDesignSystem.spacingMd),
      decoration: BoxDecoration(
        color: AppDesignSystem.backgroundMedium,
        borderRadius: BorderRadius.circular(AppDesignSystem.radiusSm),
        border: Border.all(color: AppDesignSystem.dividerLight, width: 1),
      ),
      child: Row(
        children: [
          Icon(
            Icons.play_circle_outline,
            color: AppDesignSystem.mainAccent,
            size: 32,
          ),

          const SizedBox(width: AppDesignSystem.spacingMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  video.originalFilename ?? 'Video ${video.id.substring(0, 8)}',
                  style: AppDesignSystem.feedbackStyle.copyWith(
                    color: AppDesignSystem.textPrimary,
                  ),
                ),
                Text(
                  _formatDate(video.createdAt),
                  style: AppDesignSystem.smallTextStyle.copyWith(
                    color: AppDesignSystem.textSecondary,
                  ),
                ),
              ],
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
                    'Delete video?',
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
                        'Delete',
                        style: TextStyle(color: AppDesignSystem.errorRed),
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
    );
  }

  String _formatDate(DateTime dt) => '${dt.month}/${dt.day}/${dt.year}';
}

class _NotesTab extends StatelessWidget {
  const _NotesTab({required this.sessionId});

  final String sessionId;

  @override
  Widget build(BuildContext context) {
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
                  color: AppDesignSystem.textSecondary.withValues(alpha: 0.5),
                ),
                const SizedBox(height: AppDesignSystem.spacingMd),
                Text(
                  'No notes yet',
                  style: TextStyle(color: AppDesignSystem.textSecondary),
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
              _NoteTile(note: ctrl.state.notes[index], sessionId: sessionId),
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
    return Container(
      padding: const EdgeInsets.all(AppDesignSystem.spacingMd),
      decoration: BoxDecoration(
        color: AppDesignSystem.backgroundMedium,
        borderRadius: BorderRadius.circular(AppDesignSystem.radiusSm),
        border: Border.all(color: AppDesignSystem.dividerLight, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.note, color: AppDesignSystem.mainAccent, size: 16),
              const SizedBox(width: AppDesignSystem.spacingXs),
              Text(
                note.noteType.name,
                style: AppDesignSystem.smallTextStyle.copyWith(
                  color: AppDesignSystem.mainAccent,
                ),
              ),

              if (note.videoTimestampMs != null) ...[
                const SizedBox(width: AppDesignSystem.spacingSm),
                Text(
                  _formatTimestamp(note.videoTimestampMs!),
                  style: AppDesignSystem.smallTextStyle.copyWith(
                    color: AppDesignSystem.textSecondary,
                  ),
                ),
              ],
              if (note.videoDeleted) ...[
                const SizedBox(width: AppDesignSystem.spacingSm),
                Text(
                  '(video deleted)',
                  style: AppDesignSystem.smallTextStyle.copyWith(
                    color: AppDesignSystem.errorRed,
                  ),
                ),
              ],
              const Spacer(),
              IconButton(
                icon: Icon(
                  Icons.delete_outline,
                  color: AppDesignSystem.errorRed,
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
          Text(
            note.contents,
            style: AppDesignSystem.feedbackStyle.copyWith(
              color: AppDesignSystem.textPrimary,
            ),
          ),
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

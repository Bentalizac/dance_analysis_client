import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../features/groups/presentation/controllers/groups_controller.dart';
import '../../../../features/groups/presentation/controllers/groups_state.dart';
import '../../../../features/routine_notes/data/notes_data_source.dart';
import '../../../../features/routine_notes/presentation/controllers/notes_controller.dart';
import '../../../../features/routine_notes/presentation/widgets/comment_bubble.dart';
import '../../../../features/routine_notes/presentation/widgets/composer_bar.dart';
import '../../../../features/routine_videos/data/videos_data_source.dart';
import '../../../../features/routine_videos/presentation/controllers/videos_controller.dart';
import '../../../../generated/api/models/note_response.dart';
import '../../../../generated/api/models/note_type.dart';
import '../../../../shared/widgets/group_filter_chips.dart';
import '../../../../shared/widgets/video_player_with_overlay.dart';

/// Full-screen view for a specific video with inline notes.
///
/// Scopes [VideosController] and [NotesController] locally so stale state
/// from other instances does not leak in.
class VideoDetailPage extends StatelessWidget {
  const VideoDetailPage({
    super.key,
    required this.instanceId,
    required this.videoId,
  });

  final String instanceId;
  final String videoId;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (ctx) =>
              VideosController(dataSource: ctx.read<VideosDataSource>()),
        ),
        ChangeNotifierProvider(
          create: (ctx) =>
              NotesController(dataSource: ctx.read<NotesDataSource>()),
        ),
      ],
      child: _VideoDetailContent(instanceId: instanceId, videoId: videoId),
    );
  }
}

class _VideoDetailContent extends StatefulWidget {
  const _VideoDetailContent({
    required this.instanceId,
    required this.videoId,
  });

  final String instanceId;
  final String videoId;

  @override
  State<_VideoDetailContent> createState() => _VideoDetailContentState();
}

class _VideoDetailContentState extends State<_VideoDetailContent> {
  int _selectedGroupIndex = 0;
  String? _downloadUrl;
  bool _isLoadingVideo = true;
  String? _videoError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<VideosController>().loadVideos(widget.instanceId);
      context.read<NotesController>().loadVideoNotes(
            widget.instanceId,
            widget.videoId,
          );
      context.read<GroupsController>().loadGroups();
      _fetchDownloadUrl();
    });
  }

  Future<void> _fetchDownloadUrl() async {
    try {
      final response = await context
          .read<VideosDataSource>()
          .downloadVideo(widget.instanceId, widget.videoId);
      if (mounted) {
        setState(() {
          _downloadUrl = response.downloadUrl;
          _isLoadingVideo = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _videoError = 'Could not load video: $e';
          _isLoadingVideo = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Consumer<VideosController>(
      builder: (context, videosCtrl, _) {
        final video = videosCtrl.state.videos
            .where((v) => v.id == widget.videoId)
            .firstOrNull;

        final videoTitle =
            video?.originalFilename ?? 'Video ${widget.videoId.substring(0, 8)}';

        return Scaffold(
          backgroundColor: colorScheme.surface,
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  videoTitle,
                  style: textTheme.titleLarge?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Routine ${widget.instanceId.substring(0, 8)}',
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
            child: LayoutBuilder(
              builder: (context, constraints) {
                if (kIsWeb && constraints.maxWidth >= 800) {
                  return _buildWideLayout(context, colorScheme);
                }
                return _buildNarrowLayout(context, colorScheme);
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildNarrowLayout(BuildContext context, ColorScheme colorScheme) {
    return Column(
      children: [
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: _buildVideoPlayer(colorScheme),
          ),
        ),
        const SizedBox(height: 16),
        _buildGroupFilter(context),
        const SizedBox(height: 16),
        Expanded(child: _NotesList(instanceId: widget.instanceId)),
        _buildComposer(context),
      ],
    );
  }

  Widget _buildWideLayout(BuildContext context, ColorScheme colorScheme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          flex: 6,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: _buildVideoPlayer(colorScheme),
                ),
                const SizedBox(height: 16),
                _buildGroupFilter(context),
              ],
            ),
          ),
        ),
        VerticalDivider(width: 1),
        Expanded(
          flex: 4,
          child: Column(
            children: [
              Expanded(
                child: Scrollbar(
                  child: _NotesList(instanceId: widget.instanceId),
                ),
              ),
              _buildComposer(context),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGroupFilter(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Consumer<GroupsController>(
        builder: (context, groupsCtrl, _) {
          if (groupsCtrl.state.status == GroupsStatus.loaded &&
              groupsCtrl.state.groups.isNotEmpty) {
            final names = [
              'All',
              ...groupsCtrl.state.groups.map((g) => g.name),
            ];
            return GroupFilterChips(
              groups: names,
              selectedIndex: _selectedGroupIndex,
              onSelected: (i) => setState(() => _selectedGroupIndex = i),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildComposer(BuildContext context) {
    return ComposerBar(
      hintText: 'Add a note...',
      onSubmit: (text) => context.read<NotesController>().addVideoNote(
            sessionId: widget.instanceId,
            videoId: widget.videoId,
            noteType: NoteType.feedback,
            contents: text,
          ),
    );
  }

  Widget _buildVideoPlayer(ColorScheme colorScheme) {
    if (_isLoadingVideo) {
      return AspectRatio(
        aspectRatio: 16 / 9,
        child: Container(
          color: colorScheme.surfaceContainerHighest,
          child: const Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (_videoError != null || _downloadUrl == null) {
      return AspectRatio(
        aspectRatio: 16 / 9,
        child: Container(
          color: colorScheme.surfaceContainerHighest,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, color: colorScheme.error, size: 40),
                const SizedBox(height: 8),
                Text(
                  _videoError ?? 'Video unavailable',
                  style: TextStyle(color: colorScheme.onSurfaceVariant),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return VideoPlayerWithPoseOverlay(
      videoPath: _downloadUrl!,
      poseDataList: const [],
    );
  }
}

class _NotesList extends StatelessWidget {
  const _NotesList({required this.instanceId});

  final String instanceId;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Consumer<NotesController>(
      builder: (context, ctrl, _) {
        if (ctrl.state.isLoading && ctrl.state.notes.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (ctrl.state.notes.isEmpty) {
          return Center(
            child: Text(
              'No notes yet',
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          children: [
            Text(
              'Notes',
              style: textTheme.titleMedium?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            ...ctrl.state.notes.map((note) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _NoteAsBubble(note: note),
                )),
          ],
        );
      },
    );
  }
}

class _NoteAsBubble extends StatelessWidget {
  const _NoteAsBubble({required this.note});

  final NoteResponse note;

  @override
  Widget build(BuildContext context) {
    final spans = <String>[];
    if (note.videoTimestampMs != null) {
      spans.add(_formatTimestamp(note.videoTimestampMs!));
    }

    return CommentBubble(
      text: note.videoTimestampMs != null
          ? '${_formatTimestamp(note.videoTimestampMs!)} ${note.contents}'
          : note.contents,
      alignment: Alignment.centerLeft,
      highlightedSpans: spans,
    );
  }

  String _formatTimestamp(int ms) {
    final seconds = ms ~/ 1000;
    final minutes = seconds ~/ 60;
    final remaining = seconds % 60;
    return '$minutes:${remaining.toString().padLeft(2, '0')}';
  }
}

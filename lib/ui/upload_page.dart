import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';

import '../services/api_client.dart';
import '../services/video_service.dart';
import '../state/upload_controller.dart';
import '../state/upload_state.dart';
import 'design_system.dart';
import 'widgets/inline_timestamp_form.dart';
import 'widgets/recommend_timestamps_dialog.dart';
import 'widgets/timestamp_list_item.dart';
import 'widgets/video_placeholder.dart';

/// Upload page with video preview, timestamp management, and trimming controls.
///
/// Layout is similar to ResultsPage for consistency, with:
/// - Video player at top (with playback controls)
/// - Header section with upload info and actions
/// - Timestamp/step list below (similar to feedback list)
/// - Trimming controls (marked as TODO for complex implementation)
class UploadPage extends StatefulWidget {
  const UploadPage({super.key});

  @override
  State<UploadPage> createState() => _UploadPageState();
}

class _UploadPageState extends State<UploadPage> {
  late final UploadController _controller;
  late final TextEditingController _emailController;
  VideoPlayerController? _videoPlayerController;
  bool _isVideoPlayerInitialized = false;

  @override
  void initState() {
    super.initState();
    _controller = UploadController(
      videoService: VideoService(),
      apiClient: ApiClient(),
    );
    _emailController = TextEditingController();

    // Listen for email changes
    _emailController.addListener(() {
      _controller.updateEmail(_emailController.text);
    });

    // Listen for video selection to initialize player
    _controller.addListener(_onControllerUpdate);
  }

  void _onControllerUpdate() {
    final state = _controller.state;

    // Initialize video player when video is selected
    if (state.hasVideo && _videoPlayerController == null) {
      _initializeVideoPlayer();
    }

    // Clean up video player when video is cleared
    if (!state.hasVideo && _videoPlayerController != null) {
      _disposeVideoPlayer();
    }
  }

  Future<void> _initializeVideoPlayer() async {
    final video = _controller.state.video;
    if (video == null) return;

    try {
      VideoPlayerController controller;

      if (kIsWeb) {
        // For web, use network URL
        controller = VideoPlayerController.networkUrl(Uri.parse(video.path));
      } else {
        // For mobile/desktop, use file
        controller = VideoPlayerController.file(File(video.path));
      }

      await controller.initialize();

      if (mounted) {
        setState(() {
          _videoPlayerController = controller;
          _isVideoPlayerInitialized = true;
        });
      }
    } catch (e) {
      // Video player initialization failed - show placeholder instead
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not load video preview: $e'),
            backgroundColor: AppDesignSystem.errorRed,
          ),
        );
      }
    }
  }

  void _disposeVideoPlayer() {
    _videoPlayerController?.dispose();
    _videoPlayerController = null;
    setState(() {
      _isVideoPlayerInitialized = false;
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _controller.removeListener(_onControllerUpdate);
    _controller.dispose();
    _disposeVideoPlayer();
    super.dispose();
  }

  Future<void> _handleUpload() async {
    final state = _controller.state;

    // Check if we should recommend timestamps
    if (state.shouldRecommendTimestamps) {
      final shouldProceed = await showDialog<bool>(
        context: context,
        builder: (context) =>
            RecommendTimestampsDialog(videoDuration: state.effectiveDuration),
      );

      // If user chose to add timestamps instead, don't proceed with upload
      if (shouldProceed == false) {
        return;
      }
    }

    // Proceed with upload
    await _controller.upload();

    // Show success message if upload succeeded
    if (mounted && _controller.state.status == UploadStatus.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Video uploaded successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Duration get _currentVideoPosition =>
      _videoPlayerController?.value.position ?? Duration.zero;

  void _seekToTimestamp(Duration startTime) {
    _videoPlayerController?.seekTo(startTime);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Practice Video'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final state = _controller.state;
          return SafeArea(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Video player or placeholder
                  if (state.hasVideo && _isVideoPlayerInitialized)
                    _buildVideoPlayer()
                  else if (state.hasVideo)
                    _buildVideoLoadingPlaceholder()
                  else
                    const VideoPlaceholder(),

                  // Header section with actions
                  _buildHeaderSection(state),

                  // Timestamp list (similar to feedback list)
                  Container(
                    constraints: BoxConstraints(
                      minHeight: 200,
                      maxHeight: MediaQuery.of(context).size.height * 0.4,
                    ),
                    decoration: const BoxDecoration(
                      color: AppDesignSystem.backgroundMedium,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(AppDesignSystem.radiusSm),
                        topRight: Radius.circular(AppDesignSystem.radiusSm),
                      ),
                    ),
                    child: state.hasVideo
                        ? _buildTimestampsList(state)
                        : _buildEmptyVideoState(),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildVideoPlayer() {
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.4,
      ),
      child: AspectRatio(
        aspectRatio: _videoPlayerController!.value.aspectRatio,
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            VideoPlayer(_videoPlayerController!),
            _buildVideoControls(),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoLoadingPlaceholder() {
    return Container(
      height: 300,
      color: AppDesignSystem.backgroundDark,
      child: const Center(
        child: CircularProgressIndicator(color: AppDesignSystem.accentBlue),
      ),
    );
  }

  Widget _buildVideoControls() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, Colors.black.withValues(alpha: 0.7)],
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              _videoPlayerController!.value.isPlaying
                  ? Icons.pause
                  : Icons.play_arrow,
              color: Colors.white,
            ),
            onPressed: () {
              setState(() {
                if (_videoPlayerController!.value.isPlaying) {
                  _videoPlayerController!.pause();
                } else {
                  _videoPlayerController!.play();
                }
              });
            },
          ),
          Expanded(
            child: VideoProgressIndicator(
              _videoPlayerController!,
              allowScrubbing: true,
              colors: const VideoProgressColors(
                playedColor: AppDesignSystem.accentBlue,
                bufferedColor: Colors.white24,
                backgroundColor: Colors.white12,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDesignSystem.spacingSm,
            ),
            child: Text(
              _formatDuration(_videoPlayerController!.value.position),
              style: AppDesignSystem.smallTextStyle.copyWith(
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderSection(UploadState state) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDesignSystem.spacingMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Email input
          if (!state.hasVideo) ...[
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              style: const TextStyle(color: AppDesignSystem.textPrimary),
              decoration: InputDecoration(
                labelText: 'Email',
                labelStyle: const TextStyle(
                  color: AppDesignSystem.textSecondary,
                ),
                hintText: 'you@example.com',
                hintStyle: TextStyle(
                  color: AppDesignSystem.textSecondary.withValues(alpha: 0.5),
                ),
                errorText: state.email.isEmpty || state.isEmailValid
                    ? null
                    : 'Enter a valid email',
                filled: true,
                fillColor: AppDesignSystem.backgroundMedium,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppDesignSystem.radiusXs),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: AppDesignSystem.spacingMd),
          ],

          // Video selection buttons or video info
          if (!state.hasVideo)
            _buildVideoSelectionButtons(state)
          else
            _buildVideoInfo(state),

          // Error message
          if (state.errorMessage != null) ...[
            const SizedBox(height: AppDesignSystem.spacingSm),
            Container(
              padding: const EdgeInsets.all(AppDesignSystem.spacingMd),
              decoration: BoxDecoration(
                color: AppDesignSystem.errorRed.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppDesignSystem.radiusXs),
                border: Border.all(
                  color: AppDesignSystem.errorRed.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: AppDesignSystem.errorRed,
                    size: 20,
                  ),
                  const SizedBox(width: AppDesignSystem.spacingSm),
                  Expanded(
                    child: Text(
                      state.errorMessage!,
                      style: AppDesignSystem.feedbackStyle.copyWith(
                        color: AppDesignSystem.errorRed,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildVideoSelectionButtons(UploadState state) {
    final isBusy = _isBusy(state);

    if (kIsWeb) {
      return ElevatedButton.icon(
        onPressed: isBusy
            ? null
            : () => _controller.pickVideo(ImageSource.gallery),
        icon: const Icon(Icons.upload_file),
        label: const Text('Choose video file'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppDesignSystem.accentBlue,
          foregroundColor: AppDesignSystem.backgroundDark,
          padding: const EdgeInsets.symmetric(
            vertical: AppDesignSystem.spacingMd,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDesignSystem.radiusXs),
          ),
        ),
      );
    }

    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: isBusy
                ? null
                : () => _controller.pickVideo(ImageSource.camera),
            icon: const Icon(Icons.videocam),
            label: const Text('Record'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppDesignSystem.accentBlue,
              foregroundColor: AppDesignSystem.backgroundDark,
              padding: const EdgeInsets.symmetric(
                vertical: AppDesignSystem.spacingMd,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDesignSystem.radiusXs),
              ),
            ),
          ),
        ),
        const SizedBox(width: AppDesignSystem.spacingSm),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: isBusy
                ? null
                : () => _controller.pickVideo(ImageSource.gallery),
            icon: const Icon(Icons.video_library),
            label: const Text('Choose'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppDesignSystem.accentBlue,
              padding: const EdgeInsets.symmetric(
                vertical: AppDesignSystem.spacingMd,
              ),
              side: const BorderSide(color: AppDesignSystem.accentBlue),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDesignSystem.radiusXs),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVideoInfo(UploadState state) {
    final video = state.video!;
    final durationSeconds = state.effectiveDuration.inSeconds;
    final sizeMb = (video.sizeBytes / (1024 * 1024)).toStringAsFixed(1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Video Ready',
                    style: const TextStyle(
                      color: AppDesignSystem.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppDesignSystem.spacingXs),
                  Text(
                    'Duration: ${durationSeconds}s • Size: ${sizeMb}MB',
                    style: AppDesignSystem.feedbackStyle.copyWith(
                      color: AppDesignSystem.textSecondary,
                    ),
                  ),
                  if (state.isTrimmed)
                    Text(
                      'Trimmed from ${_formatDuration(state.trimStart)} to ${_formatDuration(state.trimEnd ?? video.duration)}',
                      style: AppDesignSystem.smallTextStyle.copyWith(
                        color: AppDesignSystem.accentBlue,
                      ),
                    ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close),
              color: AppDesignSystem.textSecondary,
              onPressed: () {
                setState(() {
                  _controller.pickVideo(ImageSource.gallery);
                });
              },
              tooltip: 'Remove video',
            ),
          ],
        ),
        const SizedBox(height: AppDesignSystem.spacingMd),

        // TODO: Trimming controls (marked as complex feature)
        // For now, just show a placeholder button
        OutlinedButton.icon(
          onPressed: null, // TODO: Implement trimming UI
          icon: const Icon(Icons.content_cut),
          label: const Text('Trim Video (TODO)'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppDesignSystem.textDisabled,
            side: BorderSide(color: AppDesignSystem.dividerLight),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDesignSystem.radiusXs),
            ),
          ),
        ),
        const SizedBox(height: AppDesignSystem.spacingMd),

        // Upload button
        ElevatedButton(
          onPressed: state.canUpload && !_isBusy(state) ? _handleUpload : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppDesignSystem.accentBlue,
            foregroundColor: AppDesignSystem.backgroundDark,
            disabledBackgroundColor: AppDesignSystem.textDisabled,
            padding: const EdgeInsets.symmetric(
              vertical: AppDesignSystem.spacingMd,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDesignSystem.radiusXs),
            ),
          ),
          child: _isBusy(state)
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppDesignSystem.backgroundDark,
                    ),
                  ),
                )
              : Text(
                  'Upload for Analysis',
                  style: AppDesignSystem.tabStyle.copyWith(fontSize: 16),
                ),
        ),

        // Status text
        if (_isBusy(state)) ...[
          const SizedBox(height: AppDesignSystem.spacingSm),
          Text(
            state.statusLabel,
            textAlign: TextAlign.center,
            style: AppDesignSystem.feedbackStyle.copyWith(
              color: AppDesignSystem.textSecondary,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildEmptyVideoState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDesignSystem.spacingXl),
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
              'No video selected',
              style: const TextStyle(
                color: AppDesignSystem.textSecondary,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: AppDesignSystem.spacingSm),
            Text(
              'Select or record a video to get started',
              textAlign: TextAlign.center,
              style: AppDesignSystem.smallTextStyle.copyWith(
                color: AppDesignSystem.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimestampsList(UploadState state) {
    return Column(
      children: [
        // Header with add button
        Container(
          padding: const EdgeInsets.all(AppDesignSystem.spacingMd),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Dance Steps',
                      style: TextStyle(
                        color: AppDesignSystem.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppDesignSystem.spacingXs),
                    Text(
                      state.timestamps.isEmpty
                          ? 'No timestamps added'
                          : '${state.timestamps.length} timestamp${state.timestamps.length == 1 ? '' : 's'}',
                      style: AppDesignSystem.feedbackStyle.copyWith(
                        color: AppDesignSystem.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed:
                    state.isAddingTimestamp || state.editingTimestampId != null
                    ? null
                    : () => _controller.startAddingTimestamp(),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppDesignSystem.accentBlue,
                  foregroundColor: AppDesignSystem.backgroundDark,
                  disabledBackgroundColor: AppDesignSystem.textDisabled,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDesignSystem.spacingMd,
                    vertical: AppDesignSystem.spacingSm,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      AppDesignSystem.radiusXs,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Timestamp list or empty state
        Expanded(
          child: state.timestamps.isEmpty && !state.isAddingTimestamp
              ? _buildEmptyTimestampsState()
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDesignSystem.spacingMd,
                    vertical: AppDesignSystem.spacingMd,
                  ),
                  itemCount:
                      state.timestamps.length +
                      (state.isAddingTimestamp ? 1 : 0),
                  itemBuilder: (context, index) {
                    // Show inline add form at the end if adding
                    if (state.isAddingTimestamp &&
                        index == state.timestamps.length) {
                      return InlineTimestampForm(
                        currentVideoPosition: _currentVideoPosition,
                        onSave: (startTime, endTime, label) {
                          _controller.addTimestamp(startTime, endTime, label);
                        },
                        onCancel: _controller.cancelTimestampForm,
                        maxDuration: state.video?.duration,
                      );
                    }

                    final timestamp = state.timestamps[index];
                    final isEditing = state.editingTimestampId == timestamp.id;

                    return TimestampListItem(
                      timestamp: timestamp,
                      onTap: () => _seekToTimestamp(timestamp.startTime),
                      onEdit: () =>
                          _controller.startEditingTimestamp(timestamp.id),
                      onDelete: () => _controller.removeTimestamp(timestamp.id),
                      isEditing: isEditing,
                      editForm: isEditing
                          ? InlineTimestampForm(
                              currentVideoPosition: _currentVideoPosition,
                              existingTimestamp: timestamp,
                              onSave: (startTime, endTime, label) {
                                _controller.updateTimestamp(
                                  timestamp.id,
                                  startTime: startTime,
                                  endTime: endTime,
                                  label: label,
                                );
                              },
                              onCancel: _controller.cancelTimestampForm,
                              maxDuration: state.video?.duration,
                            )
                          : null,
                    );
                  },
                ),
        ),

        // Info text
        Container(
          padding: const EdgeInsets.all(AppDesignSystem.spacingMd),
          child: Text(
            state.timestamps.isEmpty
                ? 'Timestamps help mark different dance steps in longer videos for better analysis.'
                : 'Tap a timestamp to seek the video. Edit or delete as needed.',
            textAlign: TextAlign.center,
            style: AppDesignSystem.smallTextStyle.copyWith(
              color: AppDesignSystem.textSecondary,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyTimestampsState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDesignSystem.spacingXl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bookmark_border,
              size: 48,
              color: AppDesignSystem.textSecondary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: AppDesignSystem.spacingMd),
            Text(
              'No timestamps yet',
              style: AppDesignSystem.feedbackStyle.copyWith(
                color: AppDesignSystem.textSecondary,
              ),
            ),
            const SizedBox(height: AppDesignSystem.spacingSm),
            Text(
              'Add timestamps to mark different\ndance steps or routine segments',
              textAlign: TextAlign.center,
              style: AppDesignSystem.smallTextStyle.copyWith(
                color: AppDesignSystem.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _isBusy(UploadState state) {
    return switch (state.status) {
      UploadStatus.uploading || UploadStatus.processing => true,
      _ => false,
    };
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60);
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';

import '../../../../config/routes.dart';
import '../../../../generated/api/models/dance_style.dart';
import '../../../../shared/extensions/dance_style_extensions.dart';
import '../../../../shared/design_system/theme.dart';
import '../../../../shared/services/auth_service.dart';
import '../../../../shared/widgets/discard_confirmation_dialog.dart';
import '../../../../shared/widgets/timestamp_manager.dart';
import '../controllers/upload_controller.dart';
import '../controllers/upload_state.dart';
import '../controllers/video_player_manager.dart';

/// Main content widget for the upload page.
///
/// Separated from UploadPage to allow testing and cleaner provider access.
/// This widget watches the UploadController and VideoPlayerManager for state changes.
class UploadPageContent extends StatefulWidget {
  const UploadPageContent({super.key});

  @override
  State<UploadPageContent> createState() => _UploadPageContentState();
}

class _UploadPageContentState extends State<UploadPageContent> {
  bool _isCheckingAuthForPicker = false;

  Future<bool> _ensureAuthenticatedForUpload() async {
    final auth = context.read<AuthService>();

    if (auth.isAuthenticated) {
      return true;
    }

    setState(() {
      _isCheckingAuthForPicker = true;
    });

    try {
      final result = await context.push<bool>('/login');
      return result == true && mounted && auth.isAuthenticated;
    } finally {
      if (mounted) {
        setState(() {
          _isCheckingAuthForPicker = false;
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      context.read<UploadController>().addListener(_onUploadStateChanged);
      registerUploadPageGuard(() => _handleNavigationAttempt(context));
    });
  }

  @override
  void dispose() {
    try {
      context.read<UploadController>().removeListener(_onUploadStateChanged);
    } catch (e) {
      // Controller may already be disposed
    }
    registerUploadPageGuard(null);
    super.dispose();
  }

  void _onUploadStateChanged() {
    if (!mounted) return;

    final controller = context.read<UploadController>();
    final state = controller.state;

    if (state.hasVideo) {
      final playerManager = context.read<VideoPlayerManager>();

      if (!playerManager.isInitialized) {
        final videoPath = state.video!.path;
        playerManager.initialize(videoPath, isWeb: kIsWeb).catchError((e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Could not load video preview: $e')),
            );
          }
          return null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<UploadController>();

    return PopScope(
      canPop: !controller.hasUnsavedWork,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        final confirmed = await _handleNavigationAttempt(context);
        if (confirmed && context.mounted) {
          controller.clearVideo();
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Upload Video'), centerTitle: true),
        body: Consumer<UploadController>(
          builder: (context, controller, _) {
            final state = controller.state;

            return SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppDesignSystem.spacingMd),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (!state.hasVideo)
                      _buildVideoSelectionSection(context, controller),

                    if (state.hasVideo) _buildVideoPreviewSection(context, state),

                    const SizedBox(height: AppDesignSystem.spacingLg),

                    if (state.hasVideo) ...[
                      _buildTimestampSection(context, controller, state),
                      const SizedBox(height: AppDesignSystem.spacingLg),
                    ],

                    _buildDanceStyleDropdown(context, controller, state),

                    const SizedBox(height: AppDesignSystem.spacingLg),

                    _buildUploadButton(context, controller, state),

                    if (state.errorMessage != null) ...[
                      const SizedBox(height: AppDesignSystem.spacingMd),
                      _buildErrorMessage(context, state.errorMessage!),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildVideoSelectionSection(
    BuildContext context,
    UploadController controller,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(AppDesignSystem.spacingXl),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppDesignSystem.radiusSm),
        border: Border.all(color: colorScheme.outline, width: 2),
      ),
      child: Column(
        children: [
          Icon(
            Icons.video_library_outlined,
            size: 64,
            color: colorScheme.primary,
          ),
          const SizedBox(height: AppDesignSystem.spacingMd),
          Text(
            'Select a Video',
            style: textTheme.titleLarge,
          ),
          const SizedBox(height: AppDesignSystem.spacingSm),
          Text(
            'Choose a dance practice video to analyze',
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppDesignSystem.spacingLg),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isCheckingAuthForPicker
                      ? null
                      : () async {
                          final allowed = await _ensureAuthenticatedForUpload();
                          if (!allowed || !mounted) return;
                          controller.pickVideo(ImageSource.gallery);
                        },
                  icon: const Icon(Icons.folder_open),
                  label: const Text('Gallery'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppDesignSystem.spacingMd,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppDesignSystem.spacingMd),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isCheckingAuthForPicker
                      ? null
                      : () async {
                          final allowed = await _ensureAuthenticatedForUpload();
                          if (!allowed || !mounted) return;
                          controller.pickVideo(ImageSource.camera);
                        },
                  icon: const Icon(Icons.videocam),
                  label: const Text('Record'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppDesignSystem.spacingMd,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVideoPreviewSection(BuildContext context, UploadState state) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Consumer<VideoPlayerManager>(
      builder: (context, playerManager, _) {
        if (!playerManager.isInitialized) {
          return Container(
            height: 200,
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(AppDesignSystem.radiusSm),
            ),
            child: const Center(child: CircularProgressIndicator()),
          );
        }

        return Column(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(AppDesignSystem.radiusSm),
              ),
              child: AspectRatio(
                aspectRatio: playerManager.controller!.value.aspectRatio,
                child: VideoPlayer(playerManager.controller!),
              ),
            ),
            const SizedBox(height: AppDesignSystem.spacingSm),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDesignSystem.spacingMd,
              ),
              child: Column(
                children: [
                  VideoProgressIndicator(
                    playerManager.controller!,
                    allowScrubbing: true,
                    colors: VideoProgressColors(
                      playedColor: colorScheme.primary,
                      bufferedColor: colorScheme.primary.withValues(alpha: 0.3),
                      backgroundColor: colorScheme.outline,
                    ),
                  ),
                  const SizedBox(height: AppDesignSystem.spacingXs),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatDuration(playerManager.position),
                        style: textTheme.bodySmall,
                      ),
                      Text(
                        _formatDuration(playerManager.duration),
                        style: textTheme.bodySmall,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppDesignSystem.spacingSm),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: Icon(
                    playerManager.isPlaying ? Icons.pause : Icons.play_arrow,
                    color: colorScheme.primary,
                  ),
                  onPressed: playerManager.togglePlayPause,
                ),
                const SizedBox(width: AppDesignSystem.spacingMd),
                ElevatedButton.icon(
                  onPressed: () => _handleClearVideo(context),
                  icon: const Icon(Icons.close, size: 18),
                  label: const Text('Clear'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.surface,
                    foregroundColor: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildDanceStyleDropdown(
    BuildContext context,
    UploadController controller,
    UploadState state,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    return DropdownButtonFormField<DanceStyle>(
      key: ValueKey(state.danceStyle),
      initialValue: state.danceStyle,
      decoration: InputDecoration(
        labelText: 'Dance Style',
        hintText: 'Select the type of dance',
        prefixIcon: Icon(Icons.music_note, color: colorScheme.primary),
      ),
      dropdownColor: colorScheme.surface,
      items: DanceStyle.$valuesDefined.map((style) {
        return DropdownMenuItem<DanceStyle>(
          value: style,
          child: Text(style.displayName),
        );
      }).toList(),
      onChanged: (DanceStyle? newValue) {
        controller.updateDanceStyle(newValue);
      },
      validator: (value) {
        if (value == null) {
          return 'Please select a dance style';
        }
        return null;
      },
    );
  }

  Widget _buildUploadButton(
    BuildContext context,
    UploadController controller,
    UploadState state,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final isUploading =
        state.status == UploadStatus.uploadingToStorage ||
        state.status == UploadStatus.submittingJob;

    if (!isUploading) {
      return ElevatedButton(
        onPressed: state.canUpload ? () => controller.upload() : null,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: AppDesignSystem.spacingMd),
        ),
        child: const Text(
          'Upload Video',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      );
    }

    // Progress bar that fills the button shape from left to right
    final progress = (state.uploadProgress ?? 0.0).clamp(0.0, 1.0);

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppDesignSystem.radiusPill),
      child: SizedBox(
        height: 52,
        child: Stack(
          children: [
            Positioned.fill(child: ColoredBox(color: colorScheme.surface)),
            FractionallySizedBox(
              widthFactor: progress,
              heightFactor: 1.0,
              child: ColoredBox(color: colorScheme.primary),
            ),
            Center(
              child: Text(
                state.status == UploadStatus.submittingJob
                    ? 'Submitting…'
                    : progress >= 1.0
                    ? 'Processing…'
                    : 'Uploading… ${(progress * 100).toInt()}%',
                style: textTheme.labelLarge?.copyWith(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorMessage(BuildContext context, String message) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(AppDesignSystem.spacingMd),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(AppDesignSystem.radiusXs),
        border: Border.all(color: colorScheme.error),
      ),
      child: Row(
        children: [
          Icon(Icons.error, color: colorScheme.error),
          const SizedBox(width: AppDesignSystem.spacingSm),
          Expanded(
            child: Text(
              message,
              style: textTheme.bodyMedium?.copyWith(color: colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }

  Future<bool> _handleNavigationAttempt(BuildContext context) async {
    final controller = context.read<UploadController>();

    if (!controller.hasUnsavedWork) {
      return true;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => DiscardConfirmationDialog(
        timestampCount: controller.state.timestamps.length,
      ),
    );

    return confirmed == true;
  }

  Future<void> _handleClearVideo(BuildContext context) async {
    final controller = context.read<UploadController>();
    final state = controller.state;

    if (state.timestamps.isNotEmpty) {
      final colorScheme = Theme.of(context).colorScheme;
      final textTheme = Theme.of(context).textTheme;

      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Clear Video?'),
          content: Text(
            'You have ${state.timestamps.length} timestamp${state.timestamps.length == 1 ? '' : 's'}. '
            'Clearing the video will remove all timestamps. This cannot be undone.',
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'Cancel',
                style: textTheme.labelLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(
                'Clear',
                style: TextStyle(color: colorScheme.error),
              ),
            ),
          ],
        ),
      );

      if (confirmed != true) return;
    }

    controller.clearVideo();
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60);
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  Widget _buildTimestampSection(
    BuildContext context,
    UploadController controller,
    UploadState state,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    return Consumer<VideoPlayerManager>(
      builder: (context, playerManager, _) {
        return Container(
          height: 300,
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(AppDesignSystem.radiusSm),
          ),
          child: TimestampManager(
            timestamps: state.timestamps,
            isAddingTimestamp: state.isAddingTimestamp,
            editingTimestampId: state.editingTimestampId,
            currentVideoPosition: playerManager.position,
            maxDuration: state.video?.duration,
            onAddTimestamp: controller.startAddingTimestamp,
            onSaveTimestamp: (start, end, label) {
              controller.addTimestamp(start, end, label);
            },
            onEditTimestamp: controller.startEditingTimestamp,
            onUpdateTimestamp: (id, start, end, label) {
              controller.updateTimestamp(
                id,
                startTime: start,
                endTime: end,
                label: label,
              );
            },
            onDeleteTimestamp: controller.removeTimestamp,
            onSeekToTimestamp: (time) {
              playerManager.seekTo(time);
            },
            onCancelForm: controller.cancelTimestampForm,
          ),
        );
      },
    );
  }
}

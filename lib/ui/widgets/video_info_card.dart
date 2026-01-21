import 'package:flutter/material.dart';

import '../design_system.dart';

/// Video information card widget displaying metadata and action buttons.
///
/// This widget shows key video information including duration, file size,
/// and trim status. It also provides an upload button with loading state
/// and a remove button to clear the selected video.
///
/// The card is designed to be reusable in any context where video metadata
/// needs to be displayed with upload/removal capabilities.
///
/// Example usage:
/// ```dart
/// VideoInfoCard(
///   durationSeconds: 45,
///   sizeMb: 12.3,
///   isTrimmed: false,
///   canUpload: true,
///   isBusy: false,
///   onUpload: () => uploadController.upload(),
///   onRemove: () => uploadController.clearVideo(),
/// )
/// ```
class VideoInfoCard extends StatelessWidget {
  const VideoInfoCard({
    super.key,
    required this.durationSeconds,
    required this.sizeMb,
    this.isTrimmed = false,
    this.trimStartFormatted,
    this.trimEndFormatted,
    this.canUpload = false,
    this.isBusy = false,
    this.statusLabel,
    required this.onUpload,
    required this.onRemove,
  });

  /// Total duration of the video in seconds
  final int durationSeconds;

  /// File size in megabytes
  final double sizeMb;

  /// Whether the video has been trimmed
  final bool isTrimmed;

  /// Formatted trim start time (e.g., "0:05")
  /// Only used if isTrimmed is true
  final String? trimStartFormatted;

  /// Formatted trim end time (e.g., "1:30")
  /// Only used if isTrimmed is true
  final String? trimEndFormatted;

  /// Whether the upload button should be enabled
  final bool canUpload;

  /// Whether an upload/processing operation is in progress
  final bool isBusy;

  /// Optional status message to display during upload/processing
  final String? statusLabel;

  /// Callback invoked when user taps the upload button
  final VoidCallback onUpload;

  /// Callback invoked when user taps the remove/close button
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Video metadata and remove button
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Video Ready',
                    style: TextStyle(
                      color: AppDesignSystem.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppDesignSystem.spacingXs),
                  Text(
                    'Duration: ${durationSeconds}s • Size: ${sizeMb.toStringAsFixed(1)}MB',
                    style: AppDesignSystem.feedbackStyle.copyWith(
                      color: AppDesignSystem.textSecondary,
                    ),
                  ),
                  if (isTrimmed &&
                      trimStartFormatted != null &&
                      trimEndFormatted != null)
                    Text(
                      'Trimmed from $trimStartFormatted to $trimEndFormatted',
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
              onPressed: onRemove,
              tooltip: 'Remove video',
            ),
          ],
        ),
        const SizedBox(height: AppDesignSystem.spacingMd),

        // Upload button
        ElevatedButton(
          onPressed: canUpload && !isBusy ? onUpload : null,
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
          child: isBusy
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

        // Status text during upload/processing
        if (isBusy && statusLabel != null) ...[
          const SizedBox(height: AppDesignSystem.spacingSm),
          Text(
            statusLabel!,
            textAlign: TextAlign.center,
            style: AppDesignSystem.feedbackStyle.copyWith(
              color: AppDesignSystem.textSecondary,
            ),
          ),
        ],
      ],
    );
  }
}

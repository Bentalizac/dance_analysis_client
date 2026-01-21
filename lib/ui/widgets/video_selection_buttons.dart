import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../design_system.dart';

/// Video selection buttons widget that adapts to platform capabilities.
///
/// On web platforms, displays a single "Choose video file" button.
/// On mobile/desktop platforms, displays two buttons: "Record" and "Choose".
///
/// This widget handles the platform-specific UI differences and provides
/// consistent callbacks for video selection regardless of the source.
///
/// Example usage:
/// ```dart
/// VideoSelectionButtons(
///   onVideoSelected: (source) => controller.pickVideo(source),
///   isBusy: uploadController.isBusy,
/// )
/// ```
class VideoSelectionButtons extends StatelessWidget {
  const VideoSelectionButtons({
    super.key,
    required this.onVideoSelected,
    this.isBusy = false,
  });

  /// Callback invoked when user selects a video source
  /// Receives the ImageSource (camera or gallery) chosen by the user
  final ValueChanged<ImageSource> onVideoSelected;

  /// Whether the buttons should be disabled (e.g., during upload)
  final bool isBusy;

  @override
  Widget build(BuildContext context) {
    // Web: Single button for file selection
    if (kIsWeb) {
      return ElevatedButton.icon(
        onPressed: isBusy ? null : () => onVideoSelected(ImageSource.gallery),
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

    // Mobile/Desktop: Dual buttons for camera and gallery
    return Row(
      children: [
        // Record button
        Expanded(
          child: ElevatedButton.icon(
            onPressed: isBusy
                ? null
                : () => onVideoSelected(ImageSource.camera),
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

        // Choose from gallery button
        Expanded(
          child: OutlinedButton.icon(
            onPressed: isBusy
                ? null
                : () => onVideoSelected(ImageSource.gallery),
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
}

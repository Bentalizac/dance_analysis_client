import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';

import '../state/upload_state.dart';
import 'video_service_io.dart' if (dart.library.html) 'video_service_web.dart';

/// Service responsible for interacting with the device camera/gallery
/// and enforcing basic video validation rules.
class VideoService {
  VideoService({ImagePicker? picker}) : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  /// Maximum duration we accept for a clip.
  static const Duration maxDuration = Duration(seconds: 20);

  /// Maximum allowed file size in bytes (e.g. ~50MB).
  ///
  /// TODO: Make this configurable via a remote config or build-time flag.
  static const int maxSizeBytes = 100 * 1024 * 1024;

  /// Pick or record a video from the given [source] and validate it.
  ///
  /// Throws a [VideoValidationException] on validation errors. A `null`
  /// return value indicates the user cancelled the picker.
  Future<SelectedVideo?> pickAndValidateVideo(ImageSource source) async {
    // On web, camera recording is not well supported, so we only allow gallery selection
    if (kIsWeb && source == ImageSource.camera) {
      throw const VideoValidationException(
        'Camera recording is not supported on web. Please select an existing video file.',
      );
    }

    // Limit recorded clips to the desired max duration at the capture level (mobile only)
    final XFile? picked = await _picker.pickVideo(
      source: source,
      maxDuration: kIsWeb ? null : maxDuration,
    );

    if (picked == null) {
      // User cancelled; let the UI decide how to react.
      return null;
    }

    // Validate file size
    final size = await picked.length();
    if (size > maxSizeBytes) {
      throw const VideoValidationException('Video file is too large (max 50MB).');
    }

    // Read duration - use platform-specific implementation
    final duration = await readVideoDuration(picked);
    if (duration > maxDuration) {
      throw const VideoValidationException('Video is longer than 20 seconds.');
    }

    return SelectedVideo(
      xFile: picked,
      duration: duration,
      sizeBytes: size,
    );
  }
}

/// Lightweight error type specifically for validation failures.
class VideoValidationException implements Exception {
  const VideoValidationException(this.message);

  final String message;

  @override
  String toString() => 'VideoValidationException: $message';
}

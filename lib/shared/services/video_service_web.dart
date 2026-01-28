import 'dart:async';
import 'dart:js_interop';

import 'package:image_picker/image_picker.dart';
import 'package:web/web.dart' as web;

/// Platform-specific implementation for reading video duration on web.
///
/// Uses HTML5 video element to read metadata without displaying the video.
Future<Duration> readVideoDuration(XFile videoFile) async {
  final completer = Completer<Duration>();

  // Create a video element to read metadata
  final bytes = await videoFile.readAsBytes();
  final blob = web.Blob([bytes.toJS].toJS);
  final url = web.URL.createObjectURL(blob);

  final videoElement =
      web.document.createElement('video') as web.HTMLVideoElement
        ..preload = 'metadata'
        ..src = url;

  // Listen for metadata loaded event
  videoElement.addEventListener(
    'loadedmetadata',
    (JSAny? event) {
      final durationSeconds = videoElement.duration;
      if (!durationSeconds.isNaN && !durationSeconds.isInfinite) {
        completer.complete(
          Duration(milliseconds: (durationSeconds * 1000).round()),
        );
      } else {
        completer.completeError(Exception('Could not read video duration'));
      }
      // Clean up
      web.URL.revokeObjectURL(url);
    }.toJS,
  );

  // Handle errors
  videoElement.addEventListener(
    'error',
    (JSAny? event) {
      completer.completeError(Exception('Error loading video metadata'));
      web.URL.revokeObjectURL(url);
    }.toJS,
  );

  return completer.future.timeout(
    const Duration(seconds: 10),
    onTimeout: () {
      web.URL.revokeObjectURL(url);
      throw Exception('Timeout reading video metadata');
    },
  );
}

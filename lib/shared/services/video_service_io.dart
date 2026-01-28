import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';

/// Platform-specific implementation for reading video duration on IO platforms
/// (mobile and desktop).
Future<Duration> readVideoDuration(XFile videoFile) async {
  final file = File(videoFile.path);
  final controller = VideoPlayerController.file(file);
  try {
    await controller.initialize();
    return controller.value.duration;
  } finally {
    await controller.dispose();
  }
}

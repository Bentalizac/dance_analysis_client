import 'package:flutter/material.dart';

/// Clips a child widget into a rounded aspect-ratio panel for video preview.
class VideoPreviewPanel extends StatelessWidget {
  const VideoPreviewPanel({
    super.key,
    required this.child,
    this.aspectRatio = 16 / 9,
  });

  final Widget child;
  final double aspectRatio;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: aspectRatio,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: child,
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../models/pose_data.dart';
import '../design_system.dart';

/// Custom painter for drawing pose skeleton overlay on top of video
class PoseOverlayPainter extends CustomPainter {
  PoseOverlayPainter({
    required this.poseData,
    required this.videoSize,
    this.showSkeleton = true,
    this.showKeypoints = true,
    this.highlightedKeypointIndices = const [],
    this.highlightColor = AppDesignSystem.errorRed,
  });

  /// Pose data to render
  final PoseData? poseData;

  /// Size of the video being rendered
  final Size videoSize;

  /// Whether to draw skeleton connections
  final bool showSkeleton;

  /// Whether to draw keypoint circles
  final bool showKeypoints;

  /// Indices of keypoints to highlight (e.g., for feedback)
  final List<int> highlightedKeypointIndices;

  /// Color for highlighted elements
  final Color highlightColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (poseData == null || poseData!.keypoints.isEmpty) return;

    // Calculate scale factor to map video coordinates to widget size
    final scaleX = size.width / videoSize.width;
    final scaleY = size.height / videoSize.height;

    final keypoints = poseData!.keypoints;

    // Draw skeleton connections first (so they appear behind keypoints)
    if (showSkeleton) {
      _drawSkeleton(canvas, keypoints, scaleX, scaleY);
    }

    // Draw keypoints
    if (showKeypoints) {
      _drawKeypoints(canvas, keypoints, scaleX, scaleY);
    }

    // Draw highlights (red circles) for flagged keypoints
    if (highlightedKeypointIndices.isNotEmpty) {
      _drawHighlights(canvas, keypoints, scaleX, scaleY);
    }
  }

  /// Draw skeleton connections between keypoints
  void _drawSkeleton(
    Canvas canvas,
    List<Keypoint> keypoints,
    double scaleX,
    double scaleY,
  ) {
    final paint = Paint()
      ..color = AppDesignSystem.accentBlue.withOpacity(0.6)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final connections = PoseConnections.getConnectionIndices(keypoints);

    for (final connection in connections) {
      final startKeypoint = keypoints[connection[0]];
      final endKeypoint = keypoints[connection[1]];

      // Only draw if both keypoints are visible
      if (startKeypoint.isVisible && endKeypoint.isVisible) {
        final start = Offset(
          startKeypoint.x * scaleX,
          startKeypoint.y * scaleY,
        );
        final end = Offset(endKeypoint.x * scaleX, endKeypoint.y * scaleY);

        canvas.drawLine(start, end, paint);
      }
    }
  }

  /// Draw keypoint circles
  void _drawKeypoints(
    Canvas canvas,
    List<Keypoint> keypoints,
    double scaleX,
    double scaleY,
  ) {
    final paint = Paint()
      ..color = AppDesignSystem.accentBlue
      ..style = PaintingStyle.fill;

    for (var i = 0; i < keypoints.length; i++) {
      final keypoint = keypoints[i];

      if (!keypoint.isVisible) continue;

      final center = Offset(keypoint.x * scaleX, keypoint.y * scaleY);

      // Draw outer circle
      canvas.drawCircle(center, 5.0, paint);

      // Draw inner white circle for contrast
      final whitePaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;
      canvas.drawCircle(center, 2.0, whitePaint);
    }
  }

  /// Draw highlight circles around flagged keypoints
  void _drawHighlights(
    Canvas canvas,
    List<Keypoint> keypoints,
    double scaleX,
    double scaleY,
  ) {
    final highlightPaint = Paint()
      ..color = highlightColor.withOpacity(0.3)
      ..style = PaintingStyle.fill;

    final outlinePaint = Paint()
      ..color = highlightColor
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;

    for (final index in highlightedKeypointIndices) {
      if (index < 0 || index >= keypoints.length) continue;

      final keypoint = keypoints[index];
      if (!keypoint.isVisible) continue;

      final center = Offset(keypoint.x * scaleX, keypoint.y * scaleY);

      // Draw filled circle
      canvas.drawCircle(center, 25.0, highlightPaint);

      // Draw outline
      canvas.drawCircle(center, 25.0, outlinePaint);

      // Optional: draw pulsing animation circle
      canvas.drawCircle(center, 30.0, outlinePaint..strokeWidth = 1.5);
    }
  }

  @override
  bool shouldRepaint(PoseOverlayPainter oldDelegate) {
    return oldDelegate.poseData != poseData ||
        oldDelegate.videoSize != videoSize ||
        oldDelegate.showSkeleton != showSkeleton ||
        oldDelegate.showKeypoints != showKeypoints ||
        oldDelegate.highlightedKeypointIndices != highlightedKeypointIndices;
  }
}

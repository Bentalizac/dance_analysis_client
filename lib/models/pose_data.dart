import 'feedback_item.dart';

/// Represents pose skeleton data for a specific frame/timestamp
class PoseData {
  const PoseData({
    required this.timestamp,
    required this.keypoints,
    this.highlightedKeypoints,
  });

  /// Timestamp in the video (in seconds)
  final double timestamp;

  /// All detected keypoints in this frame
  final List<Keypoint> keypoints;

  /// Indices of keypoints to highlight (e.g., for feedback)
  final List<int>? highlightedKeypoints;

  /// Convert from JSON (from backend)
  factory PoseData.fromJson(Map<String, dynamic> json) {
    return PoseData(
      timestamp: (json['timestamp'] as num).toDouble(),
      keypoints: (json['keypoints'] as List)
          .map((k) => Keypoint.fromJson(k as Map<String, dynamic>))
          .toList(),
      highlightedKeypoints: json['highlighted_keypoints'] != null
          ? List<int>.from(json['highlighted_keypoints'] as List)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp,
      'keypoints': keypoints.map((k) => k.toJson()).toList(),
      'highlighted_keypoints': highlightedKeypoints,
    };
  }
}

/// Represents a single keypoint in the pose skeleton
class Keypoint {
  const Keypoint({
    required this.name,
    required this.x,
    required this.y,
    required this.confidence,
  });

  /// Keypoint name (e.g., 'left_ankle', 'right_wrist')
  final String name;

  /// X coordinate (normalized 0-1 or pixel coordinates)
  final double x;

  /// Y coordinate (normalized 0-1 or pixel coordinates)
  final double y;

  /// Detection confidence score (0-1)
  final double confidence;

  /// Whether this keypoint is visible/detected with good confidence
  bool get isVisible => confidence > 0.5;

  factory Keypoint.fromJson(Map<String, dynamic> json) {
    return Keypoint(
      name: json['name'] as String,
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
      confidence: (json['confidence'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {'name': name, 'x': x, 'y': y, 'confidence': confidence};
  }
}

/// Standard pose skeleton connections for drawing
class PoseConnections {
  PoseConnections._();

  /// Define which keypoints connect to form the skeleton
  /// Format: [start_keypoint_name, end_keypoint_name]
  static const List<List<String>> connections = [
    // Head and torso
    ['nose', 'left_eye'],
    ['nose', 'right_eye'],
    ['left_eye', 'left_ear'],
    ['right_eye', 'right_ear'],
    ['left_shoulder', 'right_shoulder'],
    ['left_shoulder', 'left_hip'],
    ['right_shoulder', 'right_hip'],
    ['left_hip', 'right_hip'],

    // Left arm
    ['left_shoulder', 'left_elbow'],
    ['left_elbow', 'left_wrist'],

    // Right arm
    ['right_shoulder', 'right_elbow'],
    ['right_elbow', 'right_wrist'],

    // Left leg
    ['left_hip', 'left_knee'],
    ['left_knee', 'left_ankle'],

    // Right leg
    ['right_hip', 'right_knee'],
    ['right_knee', 'right_ankle'],
  ];

  /// Get connections as pairs of indices for faster rendering
  static List<List<int>> getConnectionIndices(List<Keypoint> keypoints) {
    final indices = <List<int>>[];
    final nameToIndex = <String, int>{};

    // Build name-to-index map
    for (var i = 0; i < keypoints.length; i++) {
      nameToIndex[keypoints[i].name] = i;
    }

    // Convert connections to index pairs
    for (final connection in connections) {
      final startIndex = nameToIndex[connection[0]];
      final endIndex = nameToIndex[connection[1]];

      if (startIndex != null && endIndex != null) {
        indices.add([startIndex, endIndex]);
      }
    }

    return indices;
  }
}

/// Complete analysis result from backend
class AnalysisResult {
  const AnalysisResult({
    required this.feedbackItems,
    required this.poseData,
    this.videoPath,
  });

  /// List of timestamped feedback
  final List<FeedbackItem> feedbackItems;

  /// Pose data for each frame/timestamp
  final List<PoseData> poseData;

  /// Optional: path to local video file
  final String? videoPath;

  factory AnalysisResult.fromJson(Map<String, dynamic> json) {
    return AnalysisResult(
      feedbackItems:
          (json['feedback_items'] as List?)
              ?.map((f) => FeedbackItem.fromJson(f as Map<String, dynamic>))
              .toList() ??
          [],
      poseData:
          (json['pose_data'] as List?)
              ?.map((p) => PoseData.fromJson(p as Map<String, dynamic>))
              .toList() ??
          [],
      videoPath: json['video_path'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'feedback_items': feedbackItems.map((f) => f.toJson()).toList(),
      'pose_data': poseData.map((p) => p.toJson()).toList(),
      'video_path': videoPath,
    };
  }
}

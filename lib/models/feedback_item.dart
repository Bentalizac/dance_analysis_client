/// Represents a single piece of feedback tied to a specific timestamp in the video
class FeedbackItem {
  const FeedbackItem({
    required this.timestamp,
    required this.type,
    this.feedback,
  });

  /// The timestamp in the video (e.g., "0:08", "0:14")
  final String timestamp;

  /// Type of feedback: positive or negative
  final FeedbackType type;

  /// Optional detailed feedback text
  /// If null, this is just a timestamp marker without detailed feedback
  final String? feedback;

  /// Whether this item has detailed feedback text
  bool get hasFeedback => feedback != null && feedback!.isNotEmpty;

  /// Icon to display based on feedback type
  String get icon => type == FeedbackType.positive ? '▲' : '▼';

  /// Parse timestamp string to Duration
  Duration get duration {
    final parts = timestamp.split(':');
    if (parts.length != 2) return Duration.zero;

    final minutes = int.tryParse(parts[0]) ?? 0;
    final seconds = int.tryParse(parts[1]) ?? 0;

    return Duration(minutes: minutes, seconds: seconds);
  }

  /// Convert to JSON for serialization
  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp,
      'type': type.name,
      'feedback': feedback,
    };
  }

  /// Create from JSON
  factory FeedbackItem.fromJson(Map<String, dynamic> json) {
    return FeedbackItem(
      timestamp: json['timestamp'] as String,
      type: FeedbackType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => FeedbackType.negative,
      ),
      feedback: json['feedback'] as String?,
    );
  }
}

/// Type of feedback: positive (good form) or negative (needs improvement)
enum FeedbackType { positive, negative }

/// Extension to get display properties for feedback types
extension FeedbackTypeExtension on FeedbackType {
  bool get isPositive => this == FeedbackType.positive;
  bool get isNegative => this == FeedbackType.negative;
}

/// Represents a user-defined timestamp in a video marking a dance step or routine segment
class VideoTimestamp {
  const VideoTimestamp({
    required this.id,
    required this.startTime,
    required this.endTime,
    required this.label,
  });

  /// Unique identifier for this timestamp
  final String id;

  /// The start time of this segment in the video (Duration)
  final Duration startTime;

  /// The end time of this segment in the video (Duration)
  final Duration endTime;

  /// User-provided label for this timestamp (e.g., "Pirouette", "Grand Jeté")
  final String label;

  /// Format start time as MM:SS
  String get formattedStartTime {
    final minutes = startTime.inMinutes;
    final seconds = startTime.inSeconds.remainder(60);
    return '${minutes.toString().padLeft(1, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// Format end time as MM:SS
  String get formattedEndTime {
    final minutes = endTime.inMinutes;
    final seconds = endTime.inSeconds.remainder(60);
    return '${minutes.toString().padLeft(1, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// Format time range as MM:SS - MM:SS
  String get formattedTimeRange => '$formattedStartTime - $formattedEndTime';

  /// Duration of this segment
  Duration get duration => endTime - startTime;

  /// Create a copy with updated fields
  VideoTimestamp copyWith({
    String? id,
    Duration? startTime,
    Duration? endTime,
    String? label,
  }) {
    return VideoTimestamp(
      id: id ?? this.id,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      label: label ?? this.label,
    );
  }

  /// Convert to JSON for serialization
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'start_time_seconds': startTime.inSeconds,
      'end_time_seconds': endTime.inSeconds,
      'label': label,
    };
  }

  /// Create from JSON
  factory VideoTimestamp.fromJson(Map<String, dynamic> json) {
    return VideoTimestamp(
      id: json['id'] as String,
      startTime: Duration(seconds: json['start_time_seconds'] as int),
      endTime: Duration(seconds: json['end_time_seconds'] as int),
      label: json['label'] as String,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is VideoTimestamp &&
        other.id == id &&
        other.startTime == startTime &&
        other.endTime == endTime &&
        other.label == label;
  }

  @override
  int get hashCode => Object.hash(id, startTime, endTime, label);

  @override
  String toString() =>
      'VideoTimestamp(id: $id, range: $formattedTimeRange, label: $label)';
}

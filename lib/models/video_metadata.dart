/// Represents metadata about a video including trimming information and references
///
/// This model is used to track video state locally and can be serialized
/// for storage or transmission to the backend.
class VideoMetadata {
  const VideoMetadata({
    required this.id,
    required this.originalPath,
    this.trimmedPath,
    this.startTime = Duration.zero,
    this.endTime,
    required this.totalDuration,
    this.uploadedAt,
    this.backendReference,
  });

  /// Unique identifier for this video
  final String id;

  /// Path to the original video file (local or remote)
  final String originalPath;

  /// Path to the trimmed video file if trimming was applied
  /// If null, no trimming has been performed
  final String? trimmedPath;

  /// Start time for trimming (defaults to beginning)
  final Duration startTime;

  /// End time for trimming (defaults to total duration if not set)
  final Duration? endTime;

  /// Total duration of the original video
  final Duration totalDuration;

  /// Timestamp when this video was uploaded to the backend
  final DateTime? uploadedAt;

  /// Reference ID or URL returned from the backend after upload
  /// This allows us to reference the video later without re-uploading
  final String? backendReference;

  /// The actual path to use for playback (trimmed if available, otherwise original)
  String get effectivePath => trimmedPath ?? originalPath;

  /// The effective end time (explicit endTime or totalDuration)
  Duration get effectiveEndTime => endTime ?? totalDuration;

  /// Duration of the trimmed segment
  Duration get trimmedDuration => effectiveEndTime - startTime;

  /// Whether this video has been trimmed
  bool get isTrimmed =>
      startTime > Duration.zero ||
      (endTime != null && endTime! < totalDuration);

  /// Whether this video has been uploaded to the backend
  bool get isUploaded => backendReference != null;

  /// Create a copy with updated fields
  VideoMetadata copyWith({
    String? id,
    String? originalPath,
    String? trimmedPath,
    bool clearTrimmedPath = false,
    Duration? startTime,
    Duration? endTime,
    bool clearEndTime = false,
    Duration? totalDuration,
    DateTime? uploadedAt,
    bool clearUploadedAt = false,
    String? backendReference,
    bool clearBackendReference = false,
  }) {
    return VideoMetadata(
      id: id ?? this.id,
      originalPath: originalPath ?? this.originalPath,
      trimmedPath: clearTrimmedPath ? null : (trimmedPath ?? this.trimmedPath),
      startTime: startTime ?? this.startTime,
      endTime: clearEndTime ? null : (endTime ?? this.endTime),
      totalDuration: totalDuration ?? this.totalDuration,
      uploadedAt: clearUploadedAt ? null : (uploadedAt ?? this.uploadedAt),
      backendReference: clearBackendReference
          ? null
          : (backendReference ?? this.backendReference),
    );
  }

  /// Convert to JSON for serialization
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'originalPath': originalPath,
      'trimmedPath': trimmedPath,
      'startTime_seconds': startTime.inSeconds,
      'endTime_seconds': endTime?.inSeconds,
      'totalDuration_seconds': totalDuration.inSeconds,
      'uploadedAt': uploadedAt?.toIso8601String(),
      'backendReference': backendReference,
    };
  }

  /// Create from JSON
  factory VideoMetadata.fromJson(Map<String, dynamic> json) {
    return VideoMetadata(
      id: json['id'] as String,
      originalPath: json['originalPath'] as String,
      trimmedPath: json['trimmedPath'] as String?,
      startTime: Duration(seconds: json['startTime_seconds'] as int),
      endTime: json['endTime_seconds'] != null
          ? Duration(seconds: json['endTime_seconds'] as int)
          : null,
      totalDuration: Duration(seconds: json['totalDuration_seconds'] as int),
      uploadedAt: json['uploadedAt'] != null
          ? DateTime.parse(json['uploadedAt'] as String)
          : null,
      backendReference: json['backendReference'] as String?,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is VideoMetadata &&
        other.id == id &&
        other.originalPath == originalPath &&
        other.trimmedPath == trimmedPath &&
        other.startTime == startTime &&
        other.endTime == endTime &&
        other.totalDuration == totalDuration &&
        other.uploadedAt == uploadedAt &&
        other.backendReference == backendReference;
  }

  @override
  int get hashCode => Object.hash(
    id,
    originalPath,
    trimmedPath,
    startTime,
    endTime,
    totalDuration,
    uploadedAt,
    backendReference,
  );

  @override
  String toString() {
    return 'VideoMetadata(id: $id, originalPath: $originalPath, '
        'trimmed: $isTrimmed, uploaded: $isUploaded)';
  }
}

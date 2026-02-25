import '../generated/api/models/job_status.dart';
import 'dance_style.dart';

/// Represents a locally-recorded submission that links an uploaded video
/// to its backend job.
///
/// Written to local storage after a successful upload so the History page
/// can display entries immediately (before the next `/jobs` sync).
class Submission {
  const Submission({
    required this.localId,
    required this.jobId,
    required this.localVideoPath,
    required this.totalDuration,
    required this.createdAt,
    this.danceStyle,
    this.lastKnownStatus = JobStatus.pending,
  });

  /// Local UUID (from VideoMetadata.id)
  final String localId;

  /// Backend job ID (storageReference from upload)
  final String jobId;

  /// Path to the video file on this device
  final String localVideoPath;

  /// Total duration of the original video
  final Duration totalDuration;

  /// Dance style selected at upload time
  final DanceStyle? danceStyle;

  /// When the submission was created locally
  final DateTime createdAt;

  /// Cached status from last sync with backend
  final JobStatus lastKnownStatus;

  Submission copyWith({
    String? localId,
    String? jobId,
    String? localVideoPath,
    Duration? totalDuration,
    DanceStyle? danceStyle,
    bool clearDanceStyle = false,
    DateTime? createdAt,
    JobStatus? lastKnownStatus,
  }) {
    return Submission(
      localId: localId ?? this.localId,
      jobId: jobId ?? this.jobId,
      localVideoPath: localVideoPath ?? this.localVideoPath,
      totalDuration: totalDuration ?? this.totalDuration,
      danceStyle: clearDanceStyle ? null : (danceStyle ?? this.danceStyle),
      createdAt: createdAt ?? this.createdAt,
      lastKnownStatus: lastKnownStatus ?? this.lastKnownStatus,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'localId': localId,
      'jobId': jobId,
      'localVideoPath': localVideoPath,
      'totalDuration_ms': totalDuration.inMilliseconds,
      'danceStyle': danceStyle?.toJson(),
      'createdAt': createdAt.toIso8601String(),
      'lastKnownStatus': lastKnownStatus.json,
    };
  }

  factory Submission.fromJson(Map<String, dynamic> json) {
    return Submission(
      localId: json['localId'] as String,
      jobId: json['jobId'] as String,
      localVideoPath: json['localVideoPath'] as String,
      totalDuration: Duration(milliseconds: json['totalDuration_ms'] as int),
      danceStyle: json['danceStyle'] != null
          ? DanceStyle.fromJson(json['danceStyle'] as String)
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastKnownStatus: json['lastKnownStatus'] != null
          ? JobStatus.fromJson(json['lastKnownStatus'] as String)
          : JobStatus.pending,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Submission &&
        other.localId == localId &&
        other.jobId == jobId &&
        other.localVideoPath == localVideoPath &&
        other.totalDuration == totalDuration &&
        other.danceStyle == danceStyle &&
        other.createdAt == createdAt &&
        other.lastKnownStatus == lastKnownStatus;
  }

  @override
  int get hashCode => Object.hash(
        localId,
        jobId,
        localVideoPath,
        totalDuration,
        danceStyle,
        createdAt,
        lastKnownStatus,
      );

  @override
  String toString() =>
      'Submission(jobId: $jobId, status: $lastKnownStatus, style: $danceStyle)';
}

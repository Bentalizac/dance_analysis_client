import '../generated/api/models/job_response.dart';
import '../generated/api/models/job_status.dart';
import 'dance_style.dart';
import 'submission.dart';

/// Merged view of a local [Submission] and a remote [JobResponse] for display
/// on the History page.
///
/// The [job] is always present (source of truth for status).
/// The [submission] may be null for jobs that only exist remotely
/// (e.g. uploaded from another device).
class HistoryItem {
  const HistoryItem({
    this.submission,
    required this.job,
  });

  /// Local submission data (video path, dance style, etc.)
  /// Null if this job was not uploaded from this device.
  final Submission? submission;

  /// Remote job data — always present and authoritative for status.
  final JobResponse job;

  /// Current status from the backend.
  JobStatus get effectiveStatus => job.status;

  /// Best available creation time: prefer local, fall back to remote.
  DateTime get effectiveCreatedAt => submission?.createdAt ?? job.createdAt;

  /// Local video path, if available.
  String? get localVideoPath => submission?.localVideoPath;

  /// Whether a local video file reference exists for this item.
  bool get hasLocalVideo => submission?.localVideoPath != null;

  /// Dance style from the local submission, if available.
  DanceStyle? get danceStyle => submission?.danceStyle;

  /// Display title — dance style name or generic fallback.
  String get displayTitle => danceStyle?.displayName ?? 'Dance analysis';

  /// Whether this job has completed and might have feedback.
  bool get hasFeedback => job.status == JobStatus.completed;

  /// Whether this job is still in progress.
  bool get isInProgress =>
      job.status == JobStatus.pending || job.status == JobStatus.processing;

  /// Whether this job failed.
  bool get isFailed => job.status == JobStatus.failed;

  /// Whether this job has been soft-deleted (hidden).
  bool get isHidden => job.status == JobStatus.failedHidden;

  /// Processing progress (0–100), or null if not applicable.
  double? get progress => job.progress?.toDouble();

  @override
  String toString() =>
      'HistoryItem(jobId: ${job.jobId}, status: $effectiveStatus, '
      'hasLocal: $hasLocalVideo)';
}

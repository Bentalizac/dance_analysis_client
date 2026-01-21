import 'package:image_picker/image_picker.dart';

import '../models/video_metadata.dart';
import '../models/video_timestamp.dart';
import '../services/video_service.dart';

/// High-level status values exposed to the UI.
///
/// Keep these generic so backend changes don't force client changes.
enum UploadStatus {
  idle,
  pickingVideo,
  validating,
  ready,
  uploading,
  processing,
  success,
  error,
}

/// Represents a validated local video file the user selected or recorded.
class SelectedVideo {
  SelectedVideo({
    required this.xFile,
    required this.duration,
    required this.sizeBytes,
  });

  /// The XFile reference that works across platforms (including web).
  final XFile xFile;

  /// Convenience getter for the file path (mainly for display purposes).
  String get path => xFile.path;

  /// Total duration of the clip.
  final Duration duration;

  /// File size in bytes.
  final int sizeBytes;
}

/// Immutable snapshot of all UI-relevant state for the upload flow.
class UploadState {
  const UploadState({
    required this.status,
    required this.email,
    required this.isEmailValid,
    required this.video,
    required this.errorMessage,
    required this.timestamps,
    required this.videoMetadata,
    required this.trimStart,
    required this.trimEnd,
    required this.isAddingTimestamp,
    required this.editingTimestampId,
  });

  factory UploadState.initial() => const UploadState(
    status: UploadStatus.idle,
    email: '',
    isEmailValid: false,
    video: null,
    errorMessage: null,
    timestamps: [],
    videoMetadata: null,
    trimStart: Duration.zero,
    trimEnd: null,
    isAddingTimestamp: false,
    editingTimestampId: null,
  );

  final UploadStatus status;
  final String email;
  final bool isEmailValid;
  final SelectedVideo? video;
  final String? errorMessage;

  /// User-defined timestamps marking dance steps or routine segments
  final List<VideoTimestamp> timestamps;

  /// Metadata about the video including trimming and upload information
  final VideoMetadata? videoMetadata;

  /// Trim start time (defaults to beginning of video)
  final Duration trimStart;

  /// Trim end time (null means use full video duration)
  final Duration? trimEnd;

  /// Whether the user is currently adding a new timestamp
  final bool isAddingTimestamp;

  /// ID of the timestamp currently being edited (null if none)
  final String? editingTimestampId;

  bool get hasVideo => video != null;

  /// Whether the user can attempt an upload.
  bool get canUpload => hasVideo && isEmailValid && !_isBusy;

  /// Internal convenience for disabling UI while work is in progress.
  bool get _isBusy => switch (status) {
    UploadStatus.uploading || UploadStatus.processing => true,
    _ => false,
  };

  /// Whether the video has been trimmed from its original length
  bool get isTrimmed =>
      trimStart > Duration.zero ||
      (trimEnd != null && video != null && trimEnd! < video!.duration);

  /// Effective duration after trimming
  Duration get effectiveDuration {
    if (video == null) return Duration.zero;
    final end = trimEnd ?? video!.duration;
    return end - trimStart;
  }

  /// Whether the video exceeds recommended length for single-step analysis
  bool get exceedsRecommendedLength =>
      video != null && effectiveDuration > VideoConfig.recommendedStepDuration;

  /// Whether timestamps are recommended (video is longer than 15 seconds)
  bool get shouldRecommendTimestamps =>
      exceedsRecommendedLength && timestamps.isEmpty;

  /// Simple human-readable label for the current status.
  String get statusLabel => switch (status) {
    UploadStatus.idle => 'Idle',
    UploadStatus.pickingVideo => 'Picking video…',
    UploadStatus.validating => 'Validating video…',
    UploadStatus.ready => 'Ready to upload',
    UploadStatus.uploading => 'Uploading…',
    UploadStatus.processing => 'Processing on server…',
    UploadStatus.success => 'Upload complete',
    UploadStatus.error => 'Error',
  };

  UploadState copyWith({
    UploadStatus? status,
    String? email,
    bool? isEmailValid,
    SelectedVideo? video,
    bool clearVideo = false,
    String? errorMessage,
    bool clearError = false,
    List<VideoTimestamp>? timestamps,
    VideoMetadata? videoMetadata,
    bool clearVideoMetadata = false,
    Duration? trimStart,
    Duration? trimEnd,
    bool clearTrimEnd = false,
    bool? isAddingTimestamp,
    String? editingTimestampId,
    bool clearEditingTimestampId = false,
  }) {
    return UploadState(
      status: status ?? this.status,
      email: email ?? this.email,
      isEmailValid: isEmailValid ?? this.isEmailValid,
      video: clearVideo ? null : (video ?? this.video),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      timestamps: timestamps ?? this.timestamps,
      videoMetadata: clearVideoMetadata
          ? null
          : (videoMetadata ?? this.videoMetadata),
      trimStart: trimStart ?? this.trimStart,
      trimEnd: clearTrimEnd ? null : (trimEnd ?? this.trimEnd),
      isAddingTimestamp: isAddingTimestamp ?? this.isAddingTimestamp,
      editingTimestampId: clearEditingTimestampId
          ? null
          : (editingTimestampId ?? this.editingTimestampId),
    );
  }
}

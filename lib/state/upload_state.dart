import 'package:image_picker/image_picker.dart';

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
  });

  factory UploadState.initial() => const UploadState(
        status: UploadStatus.idle,
        email: '',
        isEmailValid: false,
        video: null,
        errorMessage: null,
      );

  final UploadStatus status;
  final String email;
  final bool isEmailValid;
  final SelectedVideo? video;
  final String? errorMessage;

  bool get hasVideo => video != null;

  /// Whether the user can attempt an upload.
  bool get canUpload => hasVideo && isEmailValid && !_isBusy;

  /// Internal convenience for disabling UI while work is in progress.
  bool get _isBusy => switch (status) {
        UploadStatus.uploading || UploadStatus.processing => true,
        _ => false,
      };

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
  }) {
    return UploadState(
      status: status ?? this.status,
      email: email ?? this.email,
      isEmailValid: isEmailValid ?? this.isEmailValid,
      video: clearVideo ? null : (video ?? this.video),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

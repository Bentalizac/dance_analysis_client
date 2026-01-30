import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../models/dance_style.dart';
import '../../../../models/video_metadata.dart';
import '../../../../models/video_timestamp.dart';
import '../../../../shared/services/api_client.dart';
import '../../../../shared/services/video_service.dart';
import '../../domain/repositories/video_repository.dart';
import 'upload_state.dart';

/// ChangeNotifier that coordinates upload flow including video selection,
/// trimming, timestamp management, and upload to the backend.
///
/// Responsibilities:
/// - Video selection and validation
/// - Video trimming (start/end time adjustment)
/// - Timestamp/dance step management
/// - Upload coordination with metadata
///
/// Keeping this free of widget code makes it easy to test and reuse.
///
/// TODO: Add local persistence to save upload progress
/// This would prevent users from losing timestamps/trimming if they:
/// - Close the app mid-upload
/// - Switch to another app and iOS kills the process
/// - Navigate away accidentally
/// Implementation would use shared_preferences to serialize state (video path,
/// email, timestamps, trim times) and restore on app launch. Need to handle:
/// - Video file moved/deleted (graceful failure)
/// - App updates/schema changes
/// - Storage quota limits
class UploadController extends ChangeNotifier {
  UploadController({
    required VideoRepository videoRepository,
    required ApiClient apiClient,
  }) : _videoRepository = videoRepository,
       _apiClient = apiClient;

  final VideoRepository _videoRepository;
  final ApiClient _apiClient;

  UploadState _state = UploadState.initial();

  UploadState get state => _state;

  /// Check if there's unsaved work (for navigation guards)
  bool get hasUnsavedWork => _state.hasVideo && _state.timestamps.isNotEmpty;

  /// Generate a unique ID for new entities
  String _generateId() => DateTime.now().millisecondsSinceEpoch.toString();

  /// Basic email validation – intentionally simple for the MVP.
  bool _isValidEmail(String email) {
    final trimmed = email.trim();
    if (trimmed.isEmpty) return false;
    final regex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
    return regex.hasMatch(trimmed);
  }

  void updateEmail(String email) {
    final valid = _isValidEmail(email);
    _state = _state.copyWith(
      email: email,
      isEmailValid: valid,
      clearError: true,
    );
    notifyListeners();
  }

  void updateDanceStyle(DanceStyle? style) {
    _state = _state.copyWith(
      danceStyle: style,
      clearDanceStyle: style == null,
      clearError: true,
    );
    notifyListeners();
  }

  Future<void> pickVideo(ImageSource source) async {
    _state = _state.copyWith(
      status: UploadStatus.pickingVideo,
      clearError: true,
    );
    notifyListeners();

    try {
      final selected = await _videoRepository.pickVideo(source);
      if (selected == null) {
        // User cancelled; go back to idle without treating as an error.
        _state = _state.copyWith(status: UploadStatus.idle);
      } else {
        // Create metadata for the new video
        final metadata = VideoMetadata(
          id: _generateId(),
          originalPath: selected.path,
          totalDuration: selected.duration,
        );

        _state = _state.copyWith(
          status: UploadStatus.ready,
          video: selected,
          videoMetadata: metadata,
          // Reset trimming and timestamps when new video is selected
          trimStart: Duration.zero,
          clearTrimEnd: true,
          timestamps: [],
          // Keep dance style selection when picking a new video
        );
      }
    } on VideoValidationException catch (e) {
      _state = _state.copyWith(
        status: UploadStatus.error,
        errorMessage: e.message,
      );
    } on Exception catch (e) {
      // TODO: Consider logging unexpected errors to a crash reporting tool.
      _state = _state.copyWith(
        status: UploadStatus.error,
        errorMessage: 'Unexpected error while selecting video: $e',
      );
    }
    notifyListeners();
  }

  /// Add a timestamp marker for a dance step or routine segment
  /// Automatically closes the inline form after adding
  void addTimestamp(Duration startTime, Duration endTime, String label) {
    if (label.trim().isEmpty) {
      return;
    }

    // Ensure end time is after start time
    if (endTime <= startTime) {
      return;
    }

    final newTimestamp = VideoTimestamp(
      id: _generateId(),
      startTime: startTime,
      endTime: endTime,
      label: label.trim(),
    );

    // Insert in chronological order by start time
    final updatedTimestamps = List<VideoTimestamp>.from(_state.timestamps)
      ..add(newTimestamp)
      ..sort((a, b) => a.startTime.compareTo(b.startTime));

    _state = _state.copyWith(
      timestamps: updatedTimestamps,
      clearError: true,
      isAddingTimestamp: false, // Close the form
    );
    notifyListeners();
  }

  /// Update an existing timestamp
  /// Automatically closes the inline form after updating
  void updateTimestamp(
    String id, {
    Duration? startTime,
    Duration? endTime,
    String? label,
  }) {
    final index = _state.timestamps.indexWhere((t) => t.id == id);
    if (index == -1) return;

    final updated = _state.timestamps[index].copyWith(
      startTime: startTime,
      endTime: endTime,
      label: label,
    );

    // Validate that end time is after start time
    if (updated.endTime <= updated.startTime) {
      return;
    }

    final updatedTimestamps = List<VideoTimestamp>.from(_state.timestamps)
      ..[index] = updated
      ..sort((a, b) => a.startTime.compareTo(b.startTime));

    _state = _state.copyWith(
      timestamps: updatedTimestamps,
      clearEditingTimestampId: true, // Close the form
    );
    notifyListeners();
  }

  /// Remove a timestamp by ID
  void removeTimestamp(String id) {
    final updatedTimestamps = _state.timestamps
        .where((t) => t.id != id)
        .toList();

    _state = _state.copyWith(timestamps: updatedTimestamps);
    notifyListeners();
  }

  /// Start adding a new timestamp (opens inline form)
  void startAddingTimestamp() {
    _state = _state.copyWith(
      isAddingTimestamp: true,
      clearEditingTimestampId: true,
    );
    notifyListeners();
  }

  /// Cancel adding/editing timestamp (closes inline form)
  void cancelTimestampForm() {
    _state = _state.copyWith(
      isAddingTimestamp: false,
      clearEditingTimestampId: true,
    );
    notifyListeners();
  }

  /// Start editing an existing timestamp (opens inline form for that timestamp)
  void startEditingTimestamp(String id) {
    _state = _state.copyWith(isAddingTimestamp: false, editingTimestampId: id);
    notifyListeners();
  }

  /// Update the trim start time
  void updateTrimStart(Duration startTime) {
    if (_state.video == null) return;

    // Ensure start time is within valid range
    final maxStart = _state.trimEnd ?? _state.video!.duration;
    final clampedStart = startTime < Duration.zero
        ? Duration.zero
        : (startTime > maxStart ? maxStart : startTime);

    _state = _state.copyWith(trimStart: clampedStart);
    notifyListeners();
  }

  /// Update the trim end time
  void updateTrimEnd(Duration? endTime) {
    if (_state.video == null) return;

    // If endTime is null, use full video duration
    if (endTime == null) {
      _state = _state.copyWith(clearTrimEnd: true);
      notifyListeners();
      return;
    }

    // Ensure end time is within valid range
    final clampedEnd = endTime < _state.trimStart
        ? _state.trimStart
        : (endTime > _state.video!.duration ? _state.video!.duration : endTime);

    _state = _state.copyWith(trimEnd: clampedEnd);
    notifyListeners();
  }

  /// Reset trimming to use the full video
  void resetTrimming() {
    _state = _state.copyWith(trimStart: Duration.zero, clearTrimEnd: true);
    notifyListeners();
  }

  /// Clear the currently selected video and reset state
  void clearVideo() {
    _state = _state.copyWith(
      clearVideo: true,
      clearVideoMetadata: true,
      status: UploadStatus.idle,
      timestamps: [],
      trimStart: Duration.zero,
      clearTrimEnd: true,
      clearError: true,
      clearDanceStyle: true,
    );
    notifyListeners();
  }

  /// Apply trimming by updating the video metadata
  /// TODO: Actual video trimming/encoding would happen here in a full implementation
  /// For now, we just track the trim points in metadata
  void applyTrimming() {
    if (_state.videoMetadata == null) return;

    final updatedMetadata = _state.videoMetadata!.copyWith(
      startTime: _state.trimStart,
      endTime: _state.trimEnd,
      // In a real implementation, this would be the path to the trimmed file
      // For now, we leave it null and rely on startTime/endTime
      // trimmedPath: await _videoService.trimVideo(...),
    );

    _state = _state.copyWith(videoMetadata: updatedMetadata);
    notifyListeners();
  }

  Future<void> upload() async {
    if (!_state.canUpload || _state.video == null) {
      // Defensive guard: UI should already disable the button.
      return;
    }

    _state = _state.copyWith(status: UploadStatus.uploading, clearError: true);
    notifyListeners();

    try {
      // Upload video with metadata (timestamps and trim information)
      final backendRef = await _apiClient.uploadVideo(
        video: _state.video!,
        email: _state.email.trim(),
        danceStyle: _state.danceStyle!,
        timestamps: _state.timestamps,
        trimStart: _state.trimStart,
        trimEnd: _state.trimEnd,
      );

      // Update metadata with upload information
      final updatedMetadata = _state.videoMetadata?.copyWith(
        uploadedAt: DateTime.now(),
        backendReference: backendRef,
      );

      _state = _state.copyWith(
        status: UploadStatus.success,
        videoMetadata: updatedMetadata,
      );
    } on ApiException catch (e) {
      _state = _state.copyWith(
        status: UploadStatus.error,
        errorMessage: e.message,
      );
    } catch (e) {
      _state = _state.copyWith(
        status: UploadStatus.error,
        errorMessage: 'Unexpected error during upload: $e',
      );
    }
    notifyListeners();
  }
}

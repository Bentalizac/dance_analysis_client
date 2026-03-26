import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../features/routine_videos/data/videos_data_source.dart';
import '../../../../models/dance_style.dart';
import '../../../../models/video_metadata.dart';
import '../../../../models/video_timestamp.dart';
import '../../../../shared/services/video_service.dart';
import '../../domain/repositories/video_repository.dart';
import 'upload_state.dart';

/// ChangeNotifier that coordinates the session-scoped upload flow:
/// register → PUT to presigned URL → finalize (triggers analysis).
///
/// Scoped to the session upload page — receives [sessionId] at construction.
class UploadController extends ChangeNotifier {
  UploadController({
    required String sessionId,
    required VideoRepository videoRepository,
    required VideosDataSource videosDataSource,
  }) : _sessionId = sessionId,
       _videoRepository = videoRepository,
       _videosDataSource = videosDataSource;

  final String _sessionId;
  final VideoRepository _videoRepository;
  final VideosDataSource _videosDataSource;

  UploadState _state = UploadState.initial();
  UploadState get state => _state;

  String _generateId() => DateTime.now().millisecondsSinceEpoch.toString();

  bool get hasUnsavedWork => _state.hasVideo && _state.timestamps.isNotEmpty;

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
        _state = _state.copyWith(status: UploadStatus.idle);
      } else {
        final metadata = VideoMetadata(
          id: _generateId(),
          originalPath: selected.path,
          totalDuration: selected.duration,
        );
        _state = _state.copyWith(
          status: UploadStatus.ready,
          video: selected,
          videoMetadata: metadata,
          trimStart: Duration.zero,
          clearTrimEnd: true,
          timestamps: [],
        );
      }
    } on VideoValidationException catch (e) {
      _state = _state.copyWith(
        status: UploadStatus.error,
        errorMessage: e.message,
      );
    } on Exception catch (e) {
      _state = _state.copyWith(
        status: UploadStatus.error,
        errorMessage: 'Unexpected error while selecting video: $e',
      );
    }
    notifyListeners();
  }

  void addTimestamp(Duration startTime, Duration endTime, String label) {
    if (label.trim().isEmpty || endTime <= startTime) return;

    final newTimestamp = VideoTimestamp(
      id: _generateId(),
      startTime: startTime,
      endTime: endTime,
      label: label.trim(),
    );

    final updated = List<VideoTimestamp>.from(_state.timestamps)
      ..add(newTimestamp)
      ..sort((a, b) => a.startTime.compareTo(b.startTime));

    _state = _state.copyWith(
      timestamps: updated,
      clearError: true,
      isAddingTimestamp: false,
    );
    notifyListeners();
  }

  void updateTimestamp(String id, {Duration? startTime, Duration? endTime, String? label}) {
    final index = _state.timestamps.indexWhere((t) => t.id == id);
    if (index == -1) return;

    final updated = _state.timestamps[index].copyWith(
      startTime: startTime,
      endTime: endTime,
      label: label,
    );
    if (updated.endTime <= updated.startTime) return;

    final updatedList = List<VideoTimestamp>.from(_state.timestamps)
      ..[index] = updated
      ..sort((a, b) => a.startTime.compareTo(b.startTime));

    _state = _state.copyWith(
      timestamps: updatedList,
      clearEditingTimestampId: true,
    );
    notifyListeners();
  }

  void removeTimestamp(String id) {
    _state = _state.copyWith(
      timestamps: _state.timestamps.where((t) => t.id != id).toList(),
    );
    notifyListeners();
  }

  void startAddingTimestamp() {
    _state = _state.copyWith(
      isAddingTimestamp: true,
      clearEditingTimestampId: true,
    );
    notifyListeners();
  }

  void cancelTimestampForm() {
    _state = _state.copyWith(
      isAddingTimestamp: false,
      clearEditingTimestampId: true,
    );
    notifyListeners();
  }

  void startEditingTimestamp(String id) {
    _state = _state.copyWith(isAddingTimestamp: false, editingTimestampId: id);
    notifyListeners();
  }

  void updateTrimStart(Duration startTime) {
    if (_state.video == null) return;
    final max = _state.trimEnd ?? _state.video!.duration;
    final clamped = startTime.isNegative
        ? Duration.zero
        : (startTime > max ? max : startTime);
    _state = _state.copyWith(trimStart: clamped);
    notifyListeners();
  }

  void updateTrimEnd(Duration? endTime) {
    if (_state.video == null) return;
    if (endTime == null) {
      _state = _state.copyWith(clearTrimEnd: true);
      notifyListeners();
      return;
    }
    final clamped = endTime < _state.trimStart
        ? _state.trimStart
        : (endTime > _state.video!.duration ? _state.video!.duration : endTime);
    _state = _state.copyWith(trimEnd: clamped);
    notifyListeners();
  }

  void resetTrimming() {
    _state = _state.copyWith(trimStart: Duration.zero, clearTrimEnd: true);
    notifyListeners();
  }

  void clearVideo() {
    _state = _state.copyWith(
      status: UploadStatus.idle,
      timestamps: [],
      trimStart: Duration.zero,
      clearTrimEnd: true,
      clearError: true,
      clearDanceStyle: true,
      clearUploadProgress: true,
    );
    notifyListeners();
  }

  void applyTrimming() {
    if (_state.videoMetadata == null) return;
    _state = _state.copyWith(
      videoMetadata: _state.videoMetadata!.copyWith(
        startTime: _state.trimStart,
        endTime: _state.trimEnd,
      ),
    );
    notifyListeners();
  }

  /// Uploads the selected video to the session:
  /// 1. Register upload → get presigned URL + videoId
  /// 2. PUT video bytes to presigned URL
  /// 3. Finalize → analysis starts automatically on the backend
  Future<void> upload() async {
    if (!_state.canUpload || _state.video == null) return;

    _state = _state.copyWith(
      status: UploadStatus.uploadingToStorage,
      clearError: true,
      uploadProgress: 0.0,
    );
    notifyListeners();

    try {
      final video = _state.video!;
      final filename = video.xFile.name;
      final fileSize = video.sizeBytes;

      // Step 1: Register upload with the backend
      final registerResponse = await _videosDataSource.registerUpload(
        _sessionId,
        filename: filename,
        contentType: 'video/mp4',
        fileSize: fileSize,
      );

      final videoId = registerResponse.video.id;
      final uploadUrl = registerResponse.uploadUrl;

      // Step 2: PUT video bytes directly to presigned URL
      await _putToPresignedUrl(
        uploadUrl,
        video,
        onSendProgress: (sent, total) {
          final progress = total > 0 ? (sent / total).clamp(0.0, 1.0) : null;
          if (_state.status == UploadStatus.uploadingToStorage && progress != null) {
            _state = _state.copyWith(uploadProgress: progress);
            notifyListeners();
          }
        },
      );

      // Step 3: Finalize — triggers analysis automatically
      _state = _state.copyWith(
        status: UploadStatus.submittingJob,
        clearUploadProgress: true,
      );
      notifyListeners();

      await _videosDataSource.finalizeUpload(_sessionId, videoId);

      _state = _state.copyWith(
        status: UploadStatus.success,
        storageReference: videoId,
        clearUploadProgress: true,
      );
    } on UploadException catch (e) {
      _state = _state.copyWith(
        status: UploadStatus.error,
        errorMessage: e.message,
        clearUploadProgress: true,
      );
    } catch (e) {
      _state = _state.copyWith(
        status: UploadStatus.error,
        errorMessage: 'Unexpected error during upload: $e',
        clearUploadProgress: true,
      );
    }
    notifyListeners();
  }

  /// PUT video bytes to the presigned storage URL using a bare Dio instance
  /// (no auth headers — the presigned URL is self-authenticating).
  Future<void> _putToPresignedUrl(
    String uploadUrl,
    SelectedVideo video, {
    void Function(int sent, int total)? onSendProgress,
  }) async {
    final file = File(video.xFile.path);
    if (!await file.exists()) {
      throw const UploadException(
        'Local video file no longer exists. Please re-select the video.',
      );
    }

    final length = await file.length();
    final stream = file.openRead();

    final s3Dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(minutes: 15),
      receiveTimeout: const Duration(minutes: 5),
    ));

    try {
      await s3Dio.put<void>(
        uploadUrl,
        data: stream,
        options: Options(
          headers: {'Content-Type': 'video/mp4', 'Content-Length': length},
          followRedirects: true,
        ),
        onSendProgress: onSendProgress,
      );
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      final body = e.response?.data;
      final msg = StringBuffer('Failed to upload video to storage.');
      if (status != null) msg.write(' HTTP $status.');
      if (e.message != null) msg.write(' ${e.message}');
      if (body != null) msg.write(' Response: $body');
      throw UploadException(msg.toString());
    } catch (e) {
      throw UploadException('Unexpected error while uploading to storage: $e');
    } finally {
      s3Dio.close();
    }
  }
}

/// Exception thrown during the upload flow.
class UploadException implements Exception {
  const UploadException(this.message);
  final String message;

  @override
  String toString() => 'UploadException: $message';
}

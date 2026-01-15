import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import '../services/api_client.dart';
import '../services/video_service.dart';
import 'upload_state.dart';

/// Simple ChangeNotifier that coordinates UI events, validation, and
/// service calls.
///
/// Keeping this free of widget code makes it easy to test and reuse.
class UploadController extends ChangeNotifier {
  UploadController({
    required VideoService videoService,
    required ApiClient apiClient,
  })  : _videoService = videoService,
        _apiClient = apiClient;

  final VideoService _videoService;
  final ApiClient _apiClient;

  UploadState _state = UploadState.initial();

  UploadState get state => _state;

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

  Future<void> pickVideo(ImageSource source) async {
    _state = _state.copyWith(
      status: UploadStatus.pickingVideo,
      clearError: true,
    );
    notifyListeners();

    try {
      final selected = await _videoService.pickAndValidateVideo(source);
      if (selected == null) {
        // User cancelled; go back to idle without treating as an error.
        _state = _state.copyWith(status: UploadStatus.idle);
      } else {
        _state = _state.copyWith(
          status: UploadStatus.ready,
          video: selected,
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
        errorMessage: 'Unexpected error while selecting video:$e',
      );
    }
    notifyListeners();
  }

  Future<void> upload() async {
    if (!_state.canUpload || _state.video == null) {
      // Defensive guard: UI should already disable the button.
      return;
    }

    _state = _state.copyWith(
      status: UploadStatus.uploading,
      clearError: true,
    );
    notifyListeners();

    try {
      await _apiClient.uploadVideo(
        video: _state.video!,
        email: _state.email.trim(),
      );
      // Backend returns immediately; any deeper processing is server-side.
      _state = _state.copyWith(status: UploadStatus.success);
    } on ApiException catch (e) {
      _state = _state.copyWith(
        status: UploadStatus.error,
        errorMessage: e.message,
      );
    } catch (_) {
      _state = _state.copyWith(
        status: UploadStatus.error,
        errorMessage: 'Unexpected error during upload.',
      );
    }
    notifyListeners();
  }
}

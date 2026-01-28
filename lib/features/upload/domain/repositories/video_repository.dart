import 'package:image_picker/image_picker.dart';

import '../../../../shared/services/video_service.dart';
import '../../presentation/controllers/upload_state.dart';

/// Repository for video-related operations.
///
/// This provides a clean abstraction over VideoService, making it easier
/// to test and mock. Future enhancements could include:
/// - Local video caching
/// - Video compression/optimization
/// - Metadata extraction
/// - Thumbnail generation
class VideoRepository {
  VideoRepository(this._videoService);

  final VideoService _videoService;

  /// Pick or record a video from the given source and validate it.
  ///
  /// Returns null if the user cancelled the picker.
  /// Throws [VideoValidationException] on validation errors.
  Future<SelectedVideo?> pickVideo(ImageSource source) async {
    return await _videoService.pickAndValidateVideo(source);
  }

  /// Get validation configuration
  static VideoConfig get config => VideoConfig();
}

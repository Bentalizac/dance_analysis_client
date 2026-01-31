import '../../presentation/controllers/upload_state.dart';

/// Abstract repository for video storage operations.
///
/// This interface allows different storage backend implementations
/// (e.g., S3, self-hosted, Google Cloud Storage) without changing
/// client code.
///
/// Implementations should handle:
/// - Platform-specific file uploads (web vs mobile)
/// - Network timeouts and retries
/// - Authentication/authorization if needed
abstract class StorageRepository {
  /// Upload a video to storage and return a reference/URL.
  ///
  /// The returned reference should be:
  /// - Retrievable by the backend for processing
  /// - Unique and stable (won't change)
  /// - Format depends on the storage backend:
  ///   - S3: s3://bucket/key or presigned URL
  ///   - Self-hosted: storage ID or file path
  ///   - CDN: CDN URL
  ///
  /// Throws [StorageException] on any upload failure.
  Future<String> uploadToStorage(SelectedVideo video);
}

/// Exception thrown when storage operations fail.
class StorageException implements Exception {
  const StorageException(this.message);

  final String message;

  @override
  String toString() => 'StorageException: $message';
}

import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;

import '../../domain/repositories/storage_repository.dart';
import '../../presentation/controllers/upload_state.dart';

/// HTTP-based storage repository implementation.
///
/// Uploads videos via HTTP multipart POST to a configurable endpoint.
/// Suitable for:
/// - Self-hosted storage servers
/// - Backend services that proxy to storage
/// - Development/testing environments
///
/// For production, consider:
/// - [S3StorageRepository] for direct S3 uploads with presigned URLs
/// - [GcsStorageRepository] for Google Cloud Storage
class HttpStorageRepository implements StorageRepository {
  HttpStorageRepository({http.Client? client, String? storageUrl})
      : _client = client ?? http.Client(),
        _storageUrl = storageUrl ?? _getStorageUrl();

  final http.Client _client;
  final String _storageUrl;

  static String _getStorageUrl() {
    const storageUrl = String.fromEnvironment('STORAGE_API_URL');
    if (storageUrl.isNotEmpty) {
      return storageUrl;
    }

    // Fallback: derive from ANALYZE_API_URL
    const analyzeUrl = String.fromEnvironment('ANALYZE_API_URL');
    if (analyzeUrl.isEmpty) {
      return '';
    }

    // Replace /analyze with /upload
    if (analyzeUrl.endsWith('/analyze')) {
      return '${analyzeUrl.substring(0, analyzeUrl.length - 8)}/upload';
    }

    // If no /analyze suffix, just append /upload
    return '$analyzeUrl/upload';
  }

  @override
  Future<String> uploadToStorage(SelectedVideo video) async {
    if (_storageUrl.isEmpty) {
      throw const StorageException(
        'Storage URL is not configured. Set STORAGE_API_URL or ANALYZE_API_URL.',
      );
    }

    final uri = Uri.parse(_storageUrl);
    final request = http.MultipartRequest('POST', uri);

    // Use XFile for cross-platform compatibility (web and mobile/desktop)
    if (kIsWeb) {
      // On web, read bytes from XFile since we don't have direct file path access
      final bytes = await video.xFile.readAsBytes();
      request.files.add(
        http.MultipartFile.fromBytes(
          'video',
          bytes,
          filename: video.xFile.name,
        ),
      );
    } else {
      // On mobile/desktop, use the more efficient fromPath method
      request.files.add(await http.MultipartFile.fromPath('video', video.path));
    }

    try {
      final streamed = await _client
          .send(request)
          .timeout(
            const Duration(seconds: 60),
          ); // Longer timeout for video upload
      final response = await http.Response.fromStream(streamed);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw StorageException(
          'Storage upload failed: HTTP ${response.statusCode}',
        );
      }

      // Extract storage reference from response
      // Expected response format: {"video_reference": "storage-url-or-id"}
      try {
        final responseData = response.body;
        // Simple extraction - backend should return just the reference
        // If it's JSON, we might need to parse it
        if (responseData.startsWith('{')) {
          // Try to extract from JSON (though backend might just return plain text)
          final match = RegExp(
            r'"video_reference"\s*:\s*"([^"]+)"',
          ).firstMatch(responseData);
          if (match != null) {
            return match.group(1)!;
          }
        }
        // If not JSON or no match, return the whole response body as reference
        return responseData.trim();
      } catch (e) {
        throw StorageException('Failed to parse storage response: $e');
      }
    } on TimeoutException {
      throw const StorageException(
        'Storage upload timed out. Please try again.',
      );
    } on SocketException {
      throw const StorageException(
        'Network error during storage upload. Check your connection.',
      );
    } on http.ClientException catch (e) {
      throw StorageException('Storage upload failed: ${e.message}');
    }
  }
}

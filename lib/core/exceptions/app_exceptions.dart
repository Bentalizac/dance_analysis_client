import 'package:dio/dio.dart';

/// Base exception for domain-level errors across all features.
class AppException implements Exception {
  const AppException(this.message);

  final String message;

  @override
  String toString() => 'AppException: $message';
}

/// Resource not found or caller lacks access (404).
class NotFoundException extends AppException {
  const NotFoundException([super.message = 'Not found or no access.']);
}

/// Request is not authenticated (401).
class UnauthorizedException extends AppException {
  const UnauthorizedException([super.message = 'Not authenticated.']);
}

/// Network-level failure (timeout, no connectivity, etc.).
class NetworkException extends AppException {
  const NetworkException(
      [super.message = 'Network error. Please check your connection.']);
}

/// Maps a [DioException] to a domain [AppException].
///
/// Use this in every data source `catch (DioException)` block to keep
/// error handling consistent across features.
AppException mapDioException(DioException e) {
  final status = e.response?.statusCode;

  if (status == 401) {
    return const UnauthorizedException();
  }
  if (status == 404) {
    return const NotFoundException();
  }

  // Connection-level failures
  if (e.type == DioExceptionType.connectionTimeout ||
      e.type == DioExceptionType.receiveTimeout ||
      e.type == DioExceptionType.sendTimeout ||
      e.type == DioExceptionType.connectionError) {
    return const NetworkException();
  }

  // Fallback with as much detail as possible
  final detail = e.response?.data is Map
      ? (e.response?.data as Map)['detail']?.toString()
      : null;
  return AppException(detail ?? e.message ?? 'An unexpected error occurred.');
}

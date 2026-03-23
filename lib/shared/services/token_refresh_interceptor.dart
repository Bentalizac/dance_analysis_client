import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show debugPrint;

/// A Dio interceptor that transparently handles access token expiry.
///
/// Behaviour on HTTP 401:
///
/// 1. If the failing request is already the refresh endpoint, the refresh
///    token itself is invalid or expired → call [onSessionExpired] and let
///    the error propagate.
/// 2. Otherwise, call [refreshAccessToken] to obtain a new access token.
///    - Concurrent 401 failures are **coalesced**: only one refresh attempt
///      runs at a time; all other waiting requests resume once it completes.
/// 3. On success the original request is retried; the auth interceptor on
///    [dio] will automatically attach the updated token.
/// 4. On any failure during refresh, call [onSessionExpired] so the caller
///    can clear local auth state and redirect to login.
///
/// This class is intentionally decoupled from [AuthService]: it communicates
/// purely through callbacks so there is no circular dependency.
class TokenRefreshInterceptor extends Interceptor {
  TokenRefreshInterceptor({
    required this.dio,
    required this.refreshAccessToken,
    required this.onSessionExpired,
    this.refreshPath = '/api/v1/auth/refresh',
  });

  /// The same [Dio] instance used for regular requests. Used to retry.
  final Dio dio;

  /// Called to perform the token refresh. Must update the token in [Dio]'s
  /// auth interceptor as a side effect. Returns the new access token on
  /// success, or `null` if the session should be terminated.
  final Future<String?> Function() refreshAccessToken;

  /// Called when the session cannot be recovered (expired refresh token,
  /// network failure during refresh, etc.). Should clear local auth state
  /// without making further authenticated network calls.
  final Future<void> Function() onSessionExpired;

  /// Path fragment used to identify the refresh endpoint so that a 401 on
  /// the refresh request itself does not trigger an infinite retry loop.
  final String refreshPath;

  // When non-null, a refresh is already in flight. Subsequent 401 failures
  // await this rather than starting their own refresh.
  Completer<String?>? _refreshCompleter;

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode != 401) {
      // Not a 401 — nothing to do here.
      return handler.next(err);
    }

    final path = err.requestOptions.path;

    if (path.contains(refreshPath)) {
      // The refresh request itself returned 401: the refresh token is invalid
      // or expired. Terminate the session without retrying.
      debugPrint(
        '[TokenRefreshInterceptor] Refresh endpoint returned 401 — '
        'session expired.',
      );
      await onSessionExpired();
      return handler.next(err);
    }

    debugPrint(
      '[TokenRefreshInterceptor] 401 on $path — attempting token refresh.',
    );

    try {
      final newToken = await _coalesceRefresh();

      if (newToken == null) {
        debugPrint(
          '[TokenRefreshInterceptor] Refresh returned null token — '
          'ending session.',
        );
        await onSessionExpired();
        return handler.next(err);
      }

      debugPrint(
        '[TokenRefreshInterceptor] Refresh succeeded — retrying original '
        'request: $path',
      );

      // Retry the original request. The auth interceptor on [dio] will inject
      // the updated token automatically.
      final retryResponse = await dio.fetch<dynamic>(err.requestOptions);
      return handler.resolve(retryResponse);
    } catch (e) {
      debugPrint(
        '[TokenRefreshInterceptor] Refresh threw $e — ending session.',
      );
      await onSessionExpired();
      return handler.next(err);
    }
  }

  /// Starts a refresh attempt or joins one that is already in progress.
  ///
  /// Using a [Completer] ensures that when several requests fail with 401
  /// simultaneously, only one call to [refreshAccessToken] is made. All
  /// callers receive the same result once it completes.
  Future<String?> _coalesceRefresh() async {
    if (_refreshCompleter != null) {
      debugPrint(
        '[TokenRefreshInterceptor] Joining in-flight refresh attempt.',
      );
      return _refreshCompleter!.future;
    }

    _refreshCompleter = Completer<String?>();

    try {
      final token = await refreshAccessToken();
      _refreshCompleter!.complete(token);
      return token;
    } catch (e) {
      _refreshCompleter!.completeError(e);
      rethrow;
    } finally {
      _refreshCompleter = null;
    }
  }
}

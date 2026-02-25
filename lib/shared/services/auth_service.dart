import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../generated/api/export.dart';
import '../../shared/services/api_service.dart';

/// Authentication service backed by the API `AuthClient`.
///
/// Responsibilities:
/// - Manage current authenticated user
/// - Perform login and registration against the backend
/// - Hold the access token in memory and configure Dio auth header
/// - Expose loading + error states for the UI
class AuthService extends ChangeNotifier {
  AuthService(this._apiService);

  final ApiService _apiService;

  AuthUser? _currentUser;
  String? _accessToken;
  bool _isLoading = false;

  /// Currently authenticated user, or null if logged out.
  AuthUser? get currentUser => _currentUser;

  /// Whether a user is currently authenticated.
  bool get isAuthenticated => _currentUser != null && _accessToken != null;

  /// Whether an auth action is in progress (login/register/logout).
  bool get isLoading => _isLoading;

  /// Access token for authorized API calls (in-memory only for now).
  String? get accessToken => _accessToken;

  /// Login using email + password via backend.
  ///
  /// Flow:
  /// 1. Validate basic email/password format
  /// 2. Call `/api/v1/auth/login` to get JWT token
  /// 3. Store token in memory and on Dio as Authorization header
  /// 4. Call `/api/v1/auth/me` to fetch user profile
  /// 5. Expose user via [currentUser]
  ///
  /// Throws [AuthException] for user-facing errors.
  Future<void> signIn({required String email, required String password}) async {
    if (_isLoading) return;

    _setLoading(true);

    try {
      final trimmedEmail = email.trim();

      if (trimmedEmail.isEmpty) {
        throw const AuthException('Please enter your email.');
      }

      final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
      if (!emailRegex.hasMatch(trimmedEmail)) {
        throw const AuthException('Please enter a valid email address.');
      }

      if (password.isEmpty) {
        throw const AuthException('Please enter your password.');
      }

      if (password.length < 8) {
        throw const AuthException(
          'Password must be at least 8 characters long.',
        );
      }

      // 1. Call login endpoint
      final loginBody = UserLogin(email: trimmedEmail, password: password);
      final token = await _apiService.client.auth.loginApiV1AuthLoginPost(
        body: loginBody,
      );

      if (token.accessToken.isEmpty) {
        throw const AuthException('Received empty token from server.');
      }

      // 2. Store token and configure Dio auth header
      _accessToken = token.accessToken;
      _apiService.setAuthToken(token.accessToken);

      // 3. Fetch current user info
      final userResponse = await _apiService.client.auth
          .getCurrentUserInfoApiV1AuthMeGet();

      _currentUser = AuthUser(
        id: userResponse.id.toString(),
        email: userResponse.email,
        displayName: userResponse.username.isNotEmpty
            ? userResponse.username
            : _deriveDisplayNameFromEmail(userResponse.email),
      );

      notifyListeners();
    } on DioException catch (e) {
      // Map common HTTP errors to user-friendly messages
      final status = e.response?.statusCode;
      if (status == 401 || status == 403) {
        throw const AuthException('Invalid email or password.');
      }
      throw AuthException(
        'Failed to sign in. ${e.message ?? 'Please try again.'}',
      );
    } on AuthException {
      rethrow;
    } catch (_) {
      throw const AuthException('Failed to sign in. Please try again.');
    } finally {
      _setLoading(false);
    }
  }

  /// Register a new user via backend.
  ///
  /// Flow:
  /// 1. Validate basic fields
  /// 2. Call `/api/v1/auth/register`
  /// 3. Optionally auto-login by calling [signIn]
  ///
  /// Throws [AuthException] for user-facing errors.
  Future<void> register({
    required String email,
    required String username,
    required String password,
  }) async {
    if (_isLoading) return;

    _setLoading(true);

    try {
      final trimmedEmail = email.trim();
      final trimmedUsername = username.trim();

      if (trimmedEmail.isEmpty) {
        throw const AuthException('Please enter your email.');
      }

      final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
      if (!emailRegex.hasMatch(trimmedEmail)) {
        throw const AuthException('Please enter a valid email address.');
      }

      if (trimmedUsername.isEmpty) {
        throw const AuthException('Please enter a username.');
      }

      if (trimmedUsername.length < 3) {
        throw const AuthException(
          'Username must be at least 3 characters long.',
        );
      }

      if (password.isEmpty) {
        throw const AuthException('Please enter your password.');
      }

      if (password.length < 8) {
        throw const AuthException(
          'Password must be at least 8 characters long.',
        );
      }

      final body = UserCreate(
        email: trimmedEmail,
        username: trimmedUsername,
        password: password,
      );

      await _apiService.client.auth.registerUserApiV1AuthRegisterPost(
        body: body,
      );

      // Optionally auto-login after successful registration
      await signIn(email: trimmedEmail, password: password);
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      if (status == 400 || status == 422) {
        // Backend likely returns validation errors (e.g. email already used)
        throw const AuthException(
          'Could not create account. Check your details and try again.',
        );
      }
      if (status == 409) {
        throw const AuthException('Email or username already in use.');
      }
      throw AuthException(
        'Failed to create account. ${e.message ?? 'Please try again.'}',
      );
    } on AuthException {
      rethrow;
    } catch (_) {
      throw const AuthException('Failed to create account. Please try again.');
    } finally {
      _setLoading(false);
    }
  }

  /// Logs out the current user.
  ///
  /// Clears in-memory user and token and removes Authorization header.
  Future<void> signOut() async {
    if (_isLoading) return;

    _setLoading(true);
    try {
      _currentUser = null;
      _accessToken = null;
      _apiService.clearAuthToken();
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  /// Internal helper to update the loading flag and notify listeners.
  void _setLoading(bool value) {
    if (_isLoading == value) return;
    _isLoading = value;
    notifyListeners();
  }

  String _deriveDisplayNameFromEmail(String email) {
    final localPart = email.split('@').first;
    if (localPart.isEmpty) return email;

    // Convert "john.doe_123" -> "John Doe 123"
    final sanitized = localPart.replaceAll(RegExp(r'[\.\_\-]+'), ' ');
    if (sanitized.isEmpty) return email;

    return sanitized
        .split(' ')
        .where((part) => part.trim().isNotEmpty)
        .map((part) {
          if (part.length == 1) return part.toUpperCase();
          return part[0].toUpperCase() + part.substring(1).toLowerCase();
        })
        .join(' ');
  }
}

/// Simple in-memory representation of an authenticated user.
///
/// This intentionally keeps only a few basic fields.
/// Extend this later based on backend needs (e.g. avatar URL, roles, etc.).
class AuthUser {
  const AuthUser({
    required this.id,
    required this.email,
    required this.displayName,
  });

  /// Unique identifier for the user.
  ///
  /// In a real system this would come from your backend / identity provider.
  final String id;

  /// Email address used to sign in.
  final String email;

  /// Display name for UI purposes.
  final String displayName;
}

/// Exception type used by [AuthService] for user-facing auth errors.
class AuthException implements Exception {
  const AuthException(this.message);

  final String message;

  @override
  String toString() => 'AuthException: $message';
}

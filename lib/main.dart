import 'dart:async';

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'config/routes.dart';
import 'features/upload/domain/repositories/video_repository.dart';
import 'shared/design_system/theme.dart';
import 'shared/services/api_client.dart';
import 'shared/services/video_service.dart';

void main() {
  // Set up global error handling
  runZonedGuarded(
    () {
      // Capture Flutter framework errors
      FlutterError.onError = (FlutterErrorDetails details) {
        FlutterError.presentError(details);
        _logError('Flutter Error', details.exception, details.stack);
      };

      runApp(const MyApp());
    },
    // Capture async errors not caught by Flutter
    (error, stack) {
      _logError('Async Error', error, stack);
    },
  );
}

/// Log errors for debugging and future crash reporting integration
void _logError(String context, Object error, StackTrace? stack) {
  // For MVP, just print to console
  // In production, this would send to crash reporting service (e.g., Sentry, Firebase Crashlytics)
  debugPrint('[$context] $error');
  if (stack != null) {
    debugPrint('Stack trace:\n$stack');
  }
}

/// Custom error widget shown when a widget build error occurs
class _CustomErrorWidget extends StatelessWidget {
  const _CustomErrorWidget({required this.details});

  final FlutterErrorDetails details;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppDesignSystem.backgroundDark,
      child: Container(
        padding: const EdgeInsets.all(AppDesignSystem.spacingXl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: AppDesignSystem.errorRed,
            ),
            const SizedBox(height: AppDesignSystem.spacingMd),
            Text(
              'Something went wrong',
              style: TextStyle(
                color: AppDesignSystem.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDesignSystem.spacingSm),
            Text(
              'The app encountered an error. Please restart the app.',
              style: AppDesignSystem.feedbackStyle.copyWith(
                color: AppDesignSystem.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDesignSystem.spacingLg),
            // Show error details in debug mode
            if (kDebugMode)
              Container(
                padding: const EdgeInsets.all(AppDesignSystem.spacingMd),
                decoration: BoxDecoration(
                  color: AppDesignSystem.backgroundMedium,
                  borderRadius: BorderRadius.circular(AppDesignSystem.radiusXs),
                ),
                child: Text(
                  details.exception.toString(),
                  style: AppDesignSystem.smallTextStyle.copyWith(
                    color: AppDesignSystem.errorRed,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Root widget for the MVP upload client.
///
/// Kept intentionally small: a single screen with basic theming.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Provide services as singletons
        Provider<VideoService>(
          create: (_) => VideoService(),
        ),
        Provider<ApiClient>(
          create: (_) => ApiClient(),
        ),
        // Provide repositories
        ProxyProvider<VideoService, VideoRepository>(
          update: (_, videoService, __) => VideoRepository(videoService),
        ),
      ],
      child: MaterialApp.router(
        title: 'Dance Coaching Upload',
        debugShowCheckedModeBanner: false,
        theme: AppDesignSystem.darkTheme,
        routerConfig: appRouter,
        // Custom error widget for better UX
        builder: (context, child) {
          ErrorWidget.builder = (FlutterErrorDetails details) {
            return _CustomErrorWidget(details: details);
          };
          return child ?? const SizedBox.shrink();
        },
      ),
    );
  }
}

# WARP.md

This file provides guidance to WARP (warp.dev) when working with code in this repository.

## Project Overview

This is a Flutter MVP client for uploading dance practice videos. The app allows users to select/record a video, validate it client-side, and upload it to a backend analysis service. The architecture emphasizes code clarity, readability, and ease of debugging.

## Common Commands

### Development
```bash
# Run the app with backend API URL configured
flutter run --dart-define=ANALYZE_API_URL=http://your-backend-url/analyze

# Run on specific platform
flutter run -d chrome --dart-define=ANALYZE_API_URL=http://localhost:8080/analyze
flutter run -d macos --dart-define=ANALYZE_API_URL=http://localhost:8080/analyze
```

### Testing
```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/widget_test.dart
```

### Code Quality
```bash
# Run static analysis
flutter analyze

# Format code
flutter format lib/ test/
```

### Build
```bash
# Build for production (requires ANALYZE_API_URL)
flutter build apk --dart-define=ANALYZE_API_URL=https://prod-api.example.com/analyze
flutter build ios --dart-define=ANALYZE_API_URL=https://prod-api.example.com/analyze
flutter build web --dart-define=ANALYZE_API_URL=https://prod-api.example.com/analyze
```

### Dependencies
```bash
# Install dependencies
flutter pub get

# Update dependencies
flutter pub upgrade

# Check for outdated packages
flutter pub outdated
```

## Architecture

### High-Level Structure

The codebase follows a layered architecture with clear separation of concerns:

**UI Layer** (`lib/ui/`)
- `upload_page.dart`: Single-screen UI for the MVP upload flow
- Uses `AnimatedBuilder` to react to state changes from the controller
- Platform-aware: shows different UI options for web vs mobile (camera recording not supported on web)

**State Management** (`lib/state/`)
- `upload_controller.dart`: ChangeNotifier that coordinates UI events, validation, and service calls. Contains no widget code for testability.
- `upload_state.dart`: Immutable state snapshots with `UploadStatus` enum driving UI behavior
- State is copied immutably using `copyWith()` pattern

**Services Layer** (`lib/services/`)
- `video_service.dart`: Handles video selection/recording via ImagePicker and enforces validation rules (max 20s duration, max 100MB size)
- `video_service_io.dart` / `video_service_web.dart`: Platform-specific implementations for reading video duration using conditional imports
- `api_client.dart`: HTTP client for uploading videos to the backend `/analyze` endpoint using multipart requests

### Key Architectural Patterns

1. **Platform Abstraction**: Uses conditional imports (`dart:io` vs `dart.library.html`) to provide platform-specific implementations for IO vs web. See `video_service.dart` importing `video_service_io.dart` / `video_service_web.dart`.

2. **Configuration via Environment Variables**: Backend URL is provided via `--dart-define=ANALYZE_API_URL=...` at build/run time. The app fails fast if this is not configured.

3. **Cross-Platform File Handling**: Uses `XFile` from `image_picker` for cross-platform compatibility. On web, reads bytes directly; on IO platforms, uses file paths for efficiency.

4. **Validation Strategy**: Two-tier validation:
   - Client-side: File size and duration checked before upload
   - Backend-side: All business logic and video analysis happens server-side (MVP keeps client simple)

5. **Error Handling**: Uses custom exception types (`VideoValidationException`, `ApiException`) with user-friendly messages propagated to UI state.

### State Flow

```
User Action → UploadController → Service (VideoService/ApiClient)
                ↓
          State Update (copyWith)
                ↓
         notifyListeners()
                ↓
    UI Rebuild (AnimatedBuilder)
```

### Important Constraints

- **Video Limits**: Max 20 seconds duration, max 100MB file size (configured in `VideoService`)
- **Web Limitations**: Camera recording disabled on web (only file upload supported)
- **Network Timeout**: API requests timeout after 30 seconds
- **MVP Scope**: Backend response body is intentionally ignored; all intelligence is server-side

## Development Notes

- The project name in some files is still "learning" (legacy from template) but the actual package name is `dance_analysis_client`
- Dependencies like `http`, `image_picker`, and `video_player` are not pinned to specific versions (marked with TODOs for production)
- Platform-specific permissions for camera/gallery access need to be configured in Android/iOS manifests for production use
- The default widget test is a placeholder and should be replaced with actual tests for the upload flow

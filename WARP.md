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
- `results_page.dart`: Displays analysis results with timestamped feedback
- `demo_results_page.dart`: Demo/preview page showing sample feedback data
- `design_system.dart`: Centralized design tokens (colors, typography, spacing) extracted from Figma
- `widgets/`: Reusable UI components (feedback list items, video player with pose overlay, pose skeleton painter)
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

**Models Layer** (`lib/models/`)

- `feedback_item.dart`: Represents timestamped feedback with positive/negative type indicators
- `pose_data.dart`: Pose skeleton data with keypoints, connections, and JSON serialization for backend integration
- `AnalysisResult`: Complete backend response structure (feedback + pose data)

**Documentation** (`docs`)

- Write ups for features go in the /docs folder in the project root, except for the main README.md and WARP.md.

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

- **Video Limits**: Max 20 seconds duration, max 100MB file size (configured in `VideoConfig`)
- **Web Limitations**: Camera recording disabled on web (only file upload supported)
- **Network Timeout**: API requests timeout after 30 seconds
- **MVP Scope**: Backend response body is intentionally ignored; all intelligence is server-side
- **Pose Data Sync**: Video player syncs pose overlay within 100ms threshold of current timestamp

### Planned Features (Not Yet Implemented)

- **Video Trimming**: The state management infrastructure supports video trimming (start/end time tracking), but the UI and actual video encoding are not yet implemented. Trim times are tracked in `VideoMetadata` and can be sent to the backend, but users cannot currently adjust them through the UI.

### Design System

The app uses a centralized design system (`lib/ui/design_system.dart`) with:

- **Color Palette**: Dark theme with accent blue (#A5D0F7) and error red (#DE3737)
- **Typography**: Consistent font sizes (16pt timestamps, 14pt feedback/tabs, 12pt small text)
- **Spacing Scale**: XS (4px), SM (8px), MD (16px), LG (22px), XL (31px)
- **Border Radius**: Standardized radii from 7px (XS) to 100px (pill shapes)
- **Shadows**: Subtle card shadows for depth

All design tokens are extracted from Figma designs to ensure UI consistency.

### Custom Painters

The pose overlay system uses Flutter's `CustomPainter` API:

- `PoseOverlayPainter`: Draws skeleton connections and keypoint circles over video
- Supports highlighting specific keypoints (e.g., for feedback visualization)
- Automatically scales coordinates from video space to widget space
- Optimized with `shouldRepaint` to minimize redraws

## Code Quality Notes

### Recent Code Quality Improvements

- ✅ **Fixed Deprecation Warnings**: All 24 deprecation warnings resolved (Color.withOpacity → withValues, ColorScheme.background → surface)
- ✅ **Pinned Dependencies**: All main dependencies now pinned to specific versions (http ^1.6.0, image_picker ^1.2.1, video_player ^2.10.1)
- ✅ **Type Safety**: Fixed `AnalysisResult.feedbackItems` to use `List<FeedbackItem>` instead of `List<dynamic>`
- ✅ **Centralized Configuration**: Created `VideoConfig` class for validation constants (fixes 50MB vs 100MB error message inconsistency)
- ✅ **Dependency Injection**: Services now provided via Provider instead of direct instantiation in widgets
- ✅ **Global Error Handling**: Added runZonedGuarded and custom error widget for better error handling

### Remaining Known Issues

1. **Test Coverage**:
   - No unit tests for controllers, services, or models
   - No widget tests for key UI components
   - Need to add test infrastructure

### Extensibility Strengths

- **Dependency Injection**: Controllers accept services via constructor for easy testing/mocking
- **Platform Abstraction**: Clean separation between IO and web implementations
- **Design System**: Centralized theming makes visual updates straightforward
- **State Immutability**: `copyWith()` pattern makes state changes predictable
- **Custom Exceptions**: `VideoValidationException` and `ApiException` provide clear error categorization

### Recommended Improvements for Production

1. Add analytics/crash reporting layer (Firebase Crashlytics, Sentry)
2. Create configuration abstraction for environment-specific values
3. Add proper logging with structured log levels
4. Implement retry logic for network requests
5. Add internationalization (i18n) support
6. Configure platform-specific permissions in manifests
7. Add accessibility labels for screen readers
8. Consider state persistence for offline support

See `CODE_QUALITY_ASSESSMENT.md` for detailed analysis.

## Development Notes

- The project name in some files is still "learning" (legacy from template) but the actual package name is `dance_analysis_client`
- `main.dart` currently shows `DemoResultsPage` by default; uncomment `UploadPage` import to switch to upload flow
- Platform-specific permissions for camera/gallery access need to be configured in Android/iOS manifests for production use

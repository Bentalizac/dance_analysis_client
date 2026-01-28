# Dance Analysis Client - Rebuild Guide

## Overview

This document provides guidance for a clean rebuild of the dance analysis client using Flutter best practices, proper architecture, and modern navigation patterns. The goal is to maintain all current functionality and styling while building a maintainable, debuggable foundation that minimizes future refactoring needs.

## Why Rebuild?

The current codebase has several architectural issues that make it difficult to maintain and extend:

1. **No Centralized Navigation**: Uses direct `Navigator.push` calls scattered throughout the codebase, making it difficult to handle deep linking, navigation guards, and state restoration
2. **Mixed State Management Concerns**: Video player controllers are managed at the widget level instead of in dedicated state management
3. **Tight Coupling**: Direct dependencies between UI and services without proper abstractions
4. **Navigation Guard Implementation**: Current implementation uses `GlobalKey` and custom methods (`canNavigateAway()`) which is fragile
5. **Missing Routing Architecture**: No named routes, route generation, or route parameters handling

## Goals

- ✅ **Keep**: All existing styling (design system), data models, and business logic
- ✅ **Improve**: Navigation architecture, state management patterns, testability
- ✅ **Add**: Proper routing with go_router, dependency injection patterns, navigation guards
- ✅ **Maintain**: All current functionality (video upload, timestamp management, trimming, etc.)

---

## Architecture Overview

### High-Level Structure

```
lib/
├── main.dart                          # App entry point with providers
├── config/
│   ├── routes.dart                    # Route definitions and guards
│   └── dependencies.dart              # DI setup
├── core/
│   ├── error/
│   │   └── error_handler.dart         # Global error handling
│   └── utils/
│       └── validators.dart            # Shared validation utilities
├── features/
│   ├── home/
│   │   ├── presentation/
│   │   │   └── home_page.dart
│   │   └── widgets/
│   │       └── navigation_card.dart
│   ├── upload/
│   │   ├── data/
│   │   │   └── repositories/
│   │   │       └── video_repository.dart
│   │   ├── domain/
│   │   │   ├── entities/              # Keep existing models
│   │   │   └── usecases/
│   │   │       ├── pick_video.dart
│   │   │       ├── upload_video.dart
│   │   │       └── manage_timestamps.dart
│   │   ├── presentation/
│   │   │   ├── controllers/
│   │   │   │   └── upload_controller.dart
│   │   │   ├── pages/
│   │   │   │   └── upload_page.dart
│   │   │   └── widgets/
│   │   │       ├── video_player_section.dart
│   │   │       ├── timestamp_list.dart
│   │   │       └── upload_form.dart
│   │   └── navigation/
│   │       └── upload_route_guard.dart
│   ├── results/
│   │   └── presentation/
│   │       ├── pages/
│   │       │   └── results_page.dart
│   │       └── widgets/
│   │           └── feedback_list.dart
│   └── history/
│       └── presentation/
│           └── pages/
│               └── history_page.dart  # Stub for now
├── shared/
│   ├── design_system/
│   │   ├── theme.dart                 # Keep existing design system
│   │   ├── colors.dart
│   │   ├── typography.dart
│   │   └── spacing.dart
│   ├── services/
│   │   ├── video_service.dart         # Keep existing
│   │   └── api_client.dart            # Keep existing
│   └── widgets/
│       ├── video_player_with_overlay.dart
│       └── loading_indicator.dart
└── models/                             # Keep all existing models
    ├── feedback_item.dart
    ├── pose_data.dart
    ├── video_metadata.dart
    └── video_timestamp.dart
```

### Key Architectural Patterns

#### 1. Feature-Based Organization

Each feature (upload, results, history) is self-contained with its own:
- **Domain layer**: Business logic and entities
- **Data layer**: Repositories and data sources
- **Presentation layer**: UI, controllers, and widgets

#### 2. Dependency Injection

Use `provider` package (already in use) with a proper hierarchy:

```dart
// main.dart
MultiProvider(
  providers: [
    // Services (singletons)
    Provider<VideoService>(create: (_) => VideoService()),
    Provider<ApiClient>(create: (_) => ApiClient()),
    
    // Repositories
    ProxyProvider<VideoService>(
      update: (_, videoService, __) => VideoRepository(videoService),
    ),
    
    // Route-specific controllers created via ChangeNotifierProvider.value
    // when navigating to that route
  ],
  child: MyApp(),
)
```

#### 3. Navigation with go_router

Replace all `Navigator.push` calls with declarative routing:

```dart
// config/routes.dart
final router = GoRouter(
  routes: [
    ShellRoute(
      builder: (context, state, child) => MainScaffold(child: child),
      routes: [
        GoRoute(
          path: '/',
          name: 'home',
          builder: (context, state) => const HomePage(),
        ),
        GoRoute(
          path: '/upload',
          name: 'upload',
          redirect: (context, state) => _uploadGuard(context, state),
          builder: (context, state) {
            return ChangeNotifierProvider(
              create: (context) => UploadController(
                videoService: context.read<VideoService>(),
                apiClient: context.read<ApiClient>(),
              ),
              child: const UploadPage(),
            );
          },
        ),
        GoRoute(
          path: '/results',
          name: 'results',
          builder: (context, state) {
            final args = state.extra as ResultsPageArgs;
            return ResultsPage(
              feedbackItems: args.feedbackItems,
              videoPath: args.videoPath,
              poseDataList: args.poseDataList,
            );
          },
        ),
        GoRoute(
          path: '/history',
          name: 'history',
          builder: (context, state) => const HistoryStubPage(),
        ),
        GoRoute(
          path: '/profile',
          name: 'profile',
          builder: (context, state) => const ProfileStubPage(),
        ),
      ],
    ),
  ],
);

// Navigation guard for upload page
String? _uploadGuard(BuildContext context, GoRouterState state) {
  // Check if there's unsaved work when navigating away
  final controller = context.read<UploadController?>();
  if (controller != null && controller.hasUnsavedWork) {
    // Show dialog and handle accordingly
    return null; // Allow navigation
  }
  return null;
}
```

#### 4. State Management Pattern

Use a clear hierarchy:
- **App-level state**: Services and repositories (Provider)
- **Feature-level state**: Controllers (ChangeNotifierProvider)
- **Widget-level state**: Local StatefulWidget state for UI-only concerns

**Example: UploadController**
```dart
class UploadController extends ChangeNotifier {
  UploadController({
    required VideoRepository videoRepository,
    required AnalysisRepository analysisRepository,
  }) : _videoRepository = videoRepository,
       _analysisRepository = analysisRepository;

  final VideoRepository _videoRepository;
  final AnalysisRepository _analysisRepository;
  
  UploadState _state = UploadState.initial();
  UploadState get state => _state;
  
  // Pure business logic methods
  Future<void> pickVideo(ImageSource source) async {
    _updateState(_state.copyWith(status: UploadStatus.pickingVideo));
    try {
      final video = await _videoRepository.pickVideo(source);
      _updateState(_state.copyWith(
        status: UploadStatus.ready,
        video: video,
      ));
    } catch (e) {
      _updateState(_state.copyWith(
        status: UploadStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }
  
  void _updateState(UploadState newState) {
    _state = newState;
    notifyListeners();
  }
  
  bool get hasUnsavedWork => 
    _state.hasVideo && _state.timestamps.isNotEmpty;
}
```

#### 5. Video Player Management

Move video player lifecycle management into a dedicated controller:

```dart
class VideoPlayerManager extends ChangeNotifier {
  VideoPlayerController? _controller;
  VideoPlayerController? get controller => _controller;
  
  bool get isInitialized => _controller?.value.isInitialized ?? false;
  Duration get position => _controller?.value.position ?? Duration.zero;
  
  Future<void> initialize(String path) async {
    await dispose();
    _controller = VideoPlayerController.file(File(path));
    await _controller!.initialize();
    notifyListeners();
  }
  
  Future<void> seekTo(Duration position) async {
    await _controller?.seekTo(position);
    notifyListeners();
  }
  
  @override
  Future<void> dispose() async {
    await _controller?.dispose();
    _controller = null;
    super.dispose();
  }
}
```

Then provide it at the appropriate level:

```dart
class UploadPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => VideoPlayerManager(),
        ),
      ],
      child: const _UploadPageContent(),
    );
  }
}
```

---

## Migration Strategy

### Phase 1: Foundation (Day 1)

1. **Add go_router dependency**
   ```yaml
   dependencies:
     go_router: ^14.6.2
   ```

2. **Create new directory structure**
   - Create `lib/config/`, `lib/core/`, `lib/features/`, `lib/shared/`
   - Move existing files to appropriate locations (don't modify yet)

3. **Extract design system**
   - Move `ui/design_system.dart` to `shared/design_system/theme.dart`
   - Split into separate files if needed (colors, typography, spacing)

4. **Set up routing infrastructure**
   - Create `config/routes.dart` with basic route definitions
   - Update `main.dart` to use `MaterialApp.router` with `GoRouter`
   - Test basic navigation between home and stub pages

### Phase 2: Shared Components (Day 2)

1. **Move models to shared location**
   - Copy existing model files to `lib/models/` (already correct)
   - Verify no changes needed to models (they're already well-designed)

2. **Move services to shared location**
   - Copy `services/` to `lib/shared/services/`
   - Keep existing implementation (already well-abstracted)

3. **Extract shared widgets**
   - Move `ui/widgets/video_player_with_overlay.dart` to `shared/widgets/`
   - Move `ui/widgets/pose_overlay_painter.dart` to `shared/widgets/`
   - Keep other widgets in feature folders

### Phase 3: Home Feature (Day 2-3)

1. **Create home feature structure**
   ```
   lib/features/home/
   ├── presentation/
   │   ├── pages/
   │   │   └── home_page.dart
   │   └── widgets/
   │       └── navigation_card.dart
   ```

2. **Refactor HomePage**
   - Extract navigation card widget
   - Replace `Navigator.push` with `context.go()` or `context.push()`
   - Remove stub page implementations (move to separate feature folders)

3. **Update routes**
   - Add home route to `config/routes.dart`
   - Set as initial route

### Phase 4: Upload Feature (Day 3-5)

1. **Create upload feature structure**
   ```
   lib/features/upload/
   ├── domain/
   │   ├── entities/
   │   │   ├── video_metadata.dart       # Move from models/
   │   │   └── video_timestamp.dart      # Move from models/
   │   └── repositories/
   │       └── video_repository.dart     # New abstraction
   ├── presentation/
   │   ├── controllers/
   │   │   ├── upload_controller.dart    # Refactored
   │   │   └── video_player_manager.dart # New
   │   ├── pages/
   │   │   └── upload_page.dart          # Refactored
   │   └── widgets/
   │       ├── video_selection_buttons.dart
   │       ├── video_info_card.dart
   │       ├── timestamp_manager.dart
   │       └── ... (other upload widgets)
   └── navigation/
       └── upload_route_guard.dart       # New
   ```

2. **Create VideoRepository abstraction**
   ```dart
   class VideoRepository {
     VideoRepository(this._videoService);
     final VideoService _videoService;
     
     Future<SelectedVideo?> pickVideo(ImageSource source) async {
       return await _videoService.pickAndValidateVideo(source);
     }
   }
   ```

3. **Refactor UploadController**
   - Inject repository instead of service
   - Remove video player management (move to VideoPlayerManager)
   - Keep all business logic (timestamps, trimming, validation)

4. **Create VideoPlayerManager**
   - Extract all video player lifecycle code from `_UploadPageState`
   - Provide as ChangeNotifier at page level
   - Widget listens to both UploadController and VideoPlayerManager

5. **Implement navigation guard**
   - Create `upload_route_guard.dart`
   - Implement using go_router's redirect mechanism
   - Show discard confirmation dialog when needed

6. **Refactor UploadPage**
   - Remove StatefulWidget (make StatelessWidget)
   - All state managed by providers
   - Widget tree builds from controller state

### Phase 5: Results Feature (Day 5-6)

1. **Create results feature structure**
   ```
   lib/features/results/
   ├── presentation/
   │   ├── pages/
   │   │   ├── results_page.dart
   │   │   └── demo_results_page.dart
   │   └── widgets/
   │       ├── feedback_list.dart
   │       └── feedback_list_item.dart
   ```

2. **Refactor ResultsPage**
   - Accept parameters via route extra or params
   - Use VideoPlayerManager for video playback
   - Keep existing UI structure

3. **Add results route**
   - Define route with parameters
   - Handle navigation from upload completion

### Phase 6: Bottom Navigation (Day 6-7)

1. **Refactor MainScaffold**
   - Use ShellRoute in go_router for persistent bottom nav
   - Remove IndexedStack approach (go_router handles this)
   - Listen to route changes to update selected tab

2. **Update tab navigation**
   - Use `context.go()` for tab switching
   - Remove manual navigation guard logic (handled by routes)

### Phase 7: Testing & Polish (Day 7-8)

1. **Update existing tests**
   - Fix controller tests with new repository injection
   - Update widget tests with proper provider setup

2. **Add navigation tests**
   - Test route guards
   - Test deep linking scenarios
   - Test back navigation behavior

3. **Performance testing**
   - Verify video player memory management
   - Test rapid navigation scenarios
   - Check for memory leaks

---

## Files to Keep vs Rebuild

### ✅ **KEEP (Copy As-Is)**

These files are well-designed and don't need changes:

**Models** (all excellent, immutable, well-tested):
- `lib/models/feedback_item.dart` ✅
- `lib/models/pose_data.dart` ✅
- `lib/models/video_metadata.dart` ✅
- `lib/models/video_timestamp.dart` ✅

**Services** (well-abstracted, platform-specific):
- `lib/services/video_service.dart` ✅
- `lib/services/video_service_io.dart` ✅
- `lib/services/video_service_web.dart` ✅
- `lib/services/api_client.dart` ✅

**Design System** (comprehensive, consistent):
- `lib/ui/design_system.dart` ✅ (just move to `shared/design_system/`)

**Widgets** (reusable, well-designed):
- `lib/ui/widgets/feedback_list_item.dart` ✅
- `lib/ui/widgets/video_placeholder.dart` ✅
- `lib/ui/widgets/pose_overlay_painter.dart` ✅
- `lib/ui/widgets/video_player_with_overlay.dart` ✅
- `lib/ui/widgets/discard_confirmation_dialog.dart` ✅
- `lib/ui/widgets/recommend_timestamps_dialog.dart` ✅

**Tests** (keep and update as needed):
- All test files in `test/` directory ✅

**Platform Configuration**:
- `pubspec.yaml` (add go_router)
- Platform-specific files (android, ios, web, etc.)

### 🔄 **REFACTOR**

These files need architectural changes but keep business logic:

**State Management**:
- `lib/state/upload_controller.dart` 🔄
  - Keep: All business logic, validation, timestamp management
  - Change: Inject repository instead of service, remove video player management
  
- `lib/state/upload_state.dart` 🔄
  - Keep: State structure, copyWith pattern
  - Change: May need minor adjustments for new controller structure

**Pages**:
- `lib/ui/upload_page.dart` 🔄
  - Keep: UI layout, widget structure
  - Change: Convert to StatelessWidget, use providers for all state
  
- `lib/ui/home_page.dart` 🔄
  - Keep: UI design, navigation card concept
  - Change: Extract widgets, use go_router navigation
  
- `lib/ui/results_page.dart` 🔄
  - Keep: UI structure, feedback list
  - Change: Use route parameters, VideoPlayerManager
  
- `lib/ui/demo_results_page.dart` 🔄
  - Keep: Demo data, UI structure
  - Change: Use go_router navigation

**Scaffolding**:
- `lib/ui/main_scaffold.dart` 🔄
  - Keep: Bottom nav design
  - Change: Use ShellRoute, remove IndexedStack/GlobalKey patterns

**Widgets**:
- `lib/ui/widgets/timestamp_manager.dart` 🔄
  - Keep: UI components
  - Change: Use Consumer pattern for controller access
  
- `lib/ui/widgets/video_player_widget.dart` 🔄
  - Keep: Player controls UI
  - Change: Use VideoPlayerManager instead of passed controller
  
- `lib/ui/widgets/inline_timestamp_form.dart` 🔄
  - Keep: Form UI and validation
  - Change: Use controller from context
  
- `lib/ui/widgets/timestamp_list_item.dart` 🔄
  - Keep: Item UI
  - Change: Minor cleanup if needed
  
- `lib/ui/widgets/video_info_card.dart` 🔄
  - Keep: UI display
  - Change: Access data via provider
  
- `lib/ui/widgets/video_selection_buttons.dart` 🔄
  - Keep: Button UI
  - Change: Use controller from context

### ❌ **REMOVE / REPLACE**

- `lib/ui/stub_pages.dart` ❌ (replace with proper feature pages)
- Any GlobalKey usage ❌ (replace with proper state management)
- Direct `Navigator.push` calls ❌ (replace with go_router)

---

## New Files to Create

### Core Infrastructure

1. **`lib/config/routes.dart`**
   - All route definitions
   - Route guards
   - Route parameters

2. **`lib/config/dependencies.dart`** (optional)
   - Dependency injection setup
   - Service initialization

3. **`lib/core/error/error_handler.dart`**
   - Move error handling from main.dart
   - Centralized error logging

### Feature-Specific

4. **`lib/features/upload/domain/repositories/video_repository.dart`**
   - Abstraction over VideoService
   - Easier testing and mocking

5. **`lib/features/upload/presentation/controllers/video_player_manager.dart`**
   - Dedicated video player lifecycle management
   - Separated from business logic

6. **`lib/features/upload/navigation/upload_route_guard.dart`**
   - Navigation guard logic
   - Discard confirmation handling

7. **`lib/features/home/widgets/navigation_card.dart`**
   - Extracted from HomePage
   - Reusable component

### Stub Features

8. **`lib/features/history/presentation/pages/history_page.dart`**
9. **`lib/features/profile/presentation/pages/profile_page.dart`**

---

## Implementation Checklist

### Pre-Development

- [ ] Review this document with the team
- [ ] Set up a new branch: `refactor/clean-architecture`
- [ ] Create backup of current working state
- [ ] Install go_router package

### Phase 1: Foundation

- [ ] Create new directory structure
- [ ] Move design system to `shared/design_system/`
- [ ] Create `config/routes.dart` with basic routes
- [ ] Update `main.dart` to use GoRouter
- [ ] Test basic navigation works

### Phase 2: Models & Services

- [ ] Verify model locations are correct
- [ ] Move services to `shared/services/`
- [ ] Create shared widgets directory
- [ ] Update imports across project

### Phase 3: Home Feature

- [ ] Create home feature structure
- [ ] Extract NavigationCard widget
- [ ] Refactor HomePage to use go_router
- [ ] Create stub feature pages
- [ ] Test home navigation

### Phase 4: Upload Feature

- [ ] Create upload feature structure
- [ ] Create VideoRepository
- [ ] Create VideoPlayerManager
- [ ] Refactor UploadController
- [ ] Refactor UploadPage to StatelessWidget
- [ ] Implement navigation guard
- [ ] Test upload flow end-to-end

### Phase 5: Results Feature

- [ ] Create results feature structure
- [ ] Refactor ResultsPage
- [ ] Add results route with parameters
- [ ] Test results navigation

### Phase 6: Bottom Navigation

- [ ] Implement ShellRoute for bottom nav
- [ ] Remove IndexedStack logic
- [ ] Update tab switching to use go_router
- [ ] Test tab navigation and state preservation

### Phase 7: Testing

- [ ] Update unit tests for controllers
- [ ] Update widget tests
- [ ] Add navigation tests
- [ ] Performance testing
- [ ] Memory leak checks
- [ ] End-to-end flow testing

### Phase 8: Cleanup

- [ ] Remove old unused files
- [ ] Update documentation
- [ ] Run `flutter analyze`
- [ ] Run `flutter format`
- [ ] Final code review

---

## Common Patterns

### Navigation

**Old way (don't do this):**
```dart
Navigator.push(
  context,
  MaterialPageRoute(builder: (context) => ResultsPage(...)),
);
```

**New way:**
```dart
context.push('/results', extra: ResultsPageArgs(...));
// or for named routes:
context.pushNamed('results', extra: ResultsPageArgs(...));
// or for replacement:
context.go('/results');
```

### Accessing State

**Old way:**
```dart
class _MyPageState extends State<MyPage> {
  late final MyController _controller;
  
  @override
  void initState() {
    super.initState();
    _controller = MyController(...);
  }
}
```

**New way:**
```dart
class MyPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => MyController(
        repository: context.read<MyRepository>(),
      ),
      child: const _MyPageContent(),
    );
  }
}

class _MyPageContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final controller = context.watch<MyController>();
    final state = controller.state;
    // ... build UI from state
  }
}
```

### Video Player Management

**Old way:**
```dart
class _MyPageState extends State<MyPage> {
  VideoPlayerController? _videoController;
  
  void _initializePlayer() {
    _videoController = VideoPlayerController.file(File(path));
    // ...
  }
  
  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }
}
```

**New way:**
```dart
class MyPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => VideoPlayerManager(),
      child: const _MyPageContent(),
    );
  }
}

class _MyPageContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final playerManager = context.watch<VideoPlayerManager>();
    // Use playerManager.controller for VideoPlayer widget
  }
}
```

---

## Testing Strategy

### Unit Tests

Focus on business logic (controllers, repositories):

```dart
void main() {
  late UploadController controller;
  late MockVideoRepository mockRepository;
  
  setUp(() {
    mockRepository = MockVideoRepository();
    controller = UploadController(
      videoRepository: mockRepository,
    );
  });
  
  test('should update state when picking video succeeds', () async {
    // Given
    final mockVideo = SelectedVideo(...);
    when(mockRepository.pickVideo(any))
        .thenAnswer((_) async => mockVideo);
    
    // When
    await controller.pickVideo(ImageSource.gallery);
    
    // Then
    expect(controller.state.video, equals(mockVideo));
    expect(controller.state.status, equals(UploadStatus.ready));
  });
}
```

### Widget Tests

Test UI behavior with proper provider setup:

```dart
void main() {
  testWidgets('should show video info when video is selected', (tester) async {
    // Given
    final mockController = MockUploadController();
    when(mockController.state).thenReturn(
      UploadState(video: SelectedVideo(...), ...),
    );
    
    // When
    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider<UploadController>.value(
          value: mockController,
          child: const UploadPage(),
        ),
      ),
    );
    
    // Then
    expect(find.byType(VideoInfoCard), findsOneWidget);
  });
}
```

### Integration Tests

Test navigation flows:

```dart
void main() {
  testWidgets('should navigate to results after upload', (tester) async {
    // Given
    await tester.pumpWidget(MyApp());
    
    // When
    await tester.tap(find.text('Upload'));
    await tester.pumpAndSettle();
    
    // Then
    expect(find.byType(UploadPage), findsOneWidget);
  });
}
```

---

## Performance Considerations

1. **Video Player Memory**: Always dispose video controllers properly
   - Solution: Use VideoPlayerManager with proper lifecycle

2. **State Preservation**: Maintain state when switching tabs
   - Solution: ShellRoute in go_router maintains widget tree

3. **Rebuild Optimization**: Minimize unnecessary rebuilds
   - Solution: Use `context.read()` for actions, `context.watch()` for listening

4. **Large Lists**: Efficiently render long timestamp/feedback lists
   - Solution: Already using ListView.builder (good)

---

## Future Enhancements

After the rebuild is complete, these will be easier to add:

1. **Deep Linking**: go_router provides built-in support
2. **State Persistence**: Add shared_preferences or similar
3. **Offline Support**: Add local database (sqlite, hive)
4. **Analytics**: Hook into route observers
5. **Authentication**: Add auth guards to routes
6. **Background Upload**: Easier with separated concerns

---

## References

- [go_router Documentation](https://pub.dev/packages/go_router)
- [Provider Best Practices](https://pub.dev/packages/provider)
- [Flutter Architecture Samples](https://github.com/brianegan/flutter_architecture_samples)
- [Clean Architecture in Flutter](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html)

---

## Questions & Decisions

**Q: Should we use Riverpod instead of Provider?**
A: Stick with Provider for now since it's already in use and works well. Riverpod can be considered for future major refactor.

**Q: Do we need a full data layer with DTOs?**
A: Not yet. Models are already simple and backend-aligned. Add DTOs only if backend contract diverges significantly.

**Q: Should video trimming be extracted to a separate service?**
A: Not in this refactor. Keep trimming logic in UploadController. If it grows complex, extract later.

**Q: Should we add BLoC pattern?**
A: No. ChangeNotifier with Provider is sufficient for this app's complexity. BLoC adds unnecessary overhead.

---

## Contact

For questions about this rebuild guide, contact the development team or refer to:
- Original WARP.md documentation
- CODE_QUALITY_ASSESSMENT.md for known issues
- Architecture decision records in /design/architecture/

# Files to Keep During Rebuild - Quick Reference

This is a quick reference guide for the rebuild. See `REBUILD_GUIDE.md` for full details.

## ✅ Keep As-Is (No Changes Needed)

### Models (Excellent Quality)
All models are well-designed with immutability, serialization, and proper validation:

- ✅ `lib/models/feedback_item.dart` - Timestamped feedback model with type enum
- ✅ `lib/models/pose_data.dart` - Pose skeleton data with keypoints and connections
- ✅ `lib/models/video_metadata.dart` - Video metadata with trimming support
- ✅ `lib/models/video_timestamp.dart` - User-defined timestamp markers

**Why keep**: Immutable, well-tested, proper JSON serialization, no dependencies on UI layer.

### Services (Well-Abstracted)
Platform-agnostic service layer with clean abstractions:

- ✅ `lib/services/video_service.dart` - Video picking and validation logic
- ✅ `lib/services/video_service_io.dart` - Platform-specific implementation (IO)
- ✅ `lib/services/video_service_web.dart` - Platform-specific implementation (Web)
- ✅ `lib/services/api_client.dart` - HTTP client for backend communication

**Why keep**: Already follows dependency injection pattern, platform-specific implementations are clean, no UI coupling.

### Design System (Complete & Consistent)
Centralized design tokens extracted from Figma:

- ✅ `lib/ui/design_system.dart` - Colors, typography, spacing, shadows, theme

**Why keep**: Comprehensive, consistent, no dependencies. Just move to `shared/design_system/theme.dart`.

### Reusable Widgets (Presentation-Only)
Well-designed, stateless presentation widgets:

- ✅ `lib/ui/widgets/feedback_list_item.dart` - Display feedback items
- ✅ `lib/ui/widgets/video_placeholder.dart` - Empty state for video area
- ✅ `lib/ui/widgets/pose_overlay_painter.dart` - Custom painter for pose skeleton
- ✅ `lib/ui/widgets/video_player_with_overlay.dart` - Video player with pose overlay
- ✅ `lib/ui/widgets/discard_confirmation_dialog.dart` - Confirmation dialog
- ✅ `lib/ui/widgets/recommend_timestamps_dialog.dart` - Timestamp recommendation dialog

**Why keep**: Pure presentation, no business logic, reusable, well-tested.

### Tests
All existing test files provide value:

- ✅ `test/models/` - Model tests
- ✅ `test/services/` - Service tests
- ✅ `test/state/` - Controller tests
- ✅ `test/ui/widgets/` - Widget tests

**Why keep**: Provide regression testing. Update as needed for new architecture.

---

## 🔄 Refactor (Keep Business Logic, Change Structure)

### State Management
**Keep**: All business logic, validation, timestamp management  
**Change**: Dependency injection, separation of concerns

- 🔄 `lib/state/upload_controller.dart` - Inject repository instead of service, remove video player management
- 🔄 `lib/state/upload_state.dart` - Minor adjustments for new controller structure

### Pages
**Keep**: UI layout, design, widget structure  
**Change**: Navigation, state access patterns, lifecycle management

- 🔄 `lib/ui/upload_page.dart` - Convert to StatelessWidget, use providers for all state
- 🔄 `lib/ui/home_page.dart` - Extract widgets, use go_router navigation
- 🔄 `lib/ui/results_page.dart` - Use route parameters, VideoPlayerManager
- 🔄 `lib/ui/demo_results_page.dart` - Use go_router navigation

### Main Scaffold
**Keep**: Bottom nav design, tab structure  
**Change**: Use ShellRoute, remove IndexedStack/GlobalKey patterns

- 🔄 `lib/ui/main_scaffold.dart`

### Feature-Specific Widgets
**Keep**: UI components, form validation  
**Change**: Access controller via context.read/watch

- 🔄 `lib/ui/widgets/timestamp_manager.dart` - Use Consumer pattern
- 🔄 `lib/ui/widgets/video_player_widget.dart` - Use VideoPlayerManager
- 🔄 `lib/ui/widgets/inline_timestamp_form.dart` - Use controller from context
- 🔄 `lib/ui/widgets/timestamp_list_item.dart` - Minor cleanup
- 🔄 `lib/ui/widgets/video_info_card.dart` - Access data via provider
- 🔄 `lib/ui/widgets/video_selection_buttons.dart` - Use controller from context

---

## ❌ Remove or Replace

### Architectural Anti-Patterns
- ❌ `lib/ui/stub_pages.dart` - Replace with proper feature pages
- ❌ Any GlobalKey usage - Replace with proper state management
- ❌ Direct `Navigator.push` calls - Replace with go_router

### Main Entry Point
- 🔄 `lib/main.dart` - Refactor to use GoRouter and MultiProvider setup

---

## File Move Plan

### Phase 1: Create New Structure
```
lib/
├── config/
├── core/
├── features/
├── shared/
└── models/  (already exists, keep location)
```

### Phase 2: Move Existing Files

**Design System:**
- Move `lib/ui/design_system.dart` → `lib/shared/design_system/theme.dart`

**Services:**
- Move `lib/services/*` → `lib/shared/services/*`

**Shared Widgets:**
- Move `lib/ui/widgets/video_player_with_overlay.dart` → `lib/shared/widgets/`
- Move `lib/ui/widgets/pose_overlay_painter.dart` → `lib/shared/widgets/`
- Move `lib/ui/widgets/video_placeholder.dart` → `lib/shared/widgets/`

**Feature: Home**
- Move `lib/ui/home_page.dart` → `lib/features/home/presentation/pages/`

**Feature: Upload**
- Move `lib/state/upload_controller.dart` → `lib/features/upload/presentation/controllers/`
- Move `lib/state/upload_state.dart` → `lib/features/upload/presentation/controllers/`
- Move `lib/ui/upload_page.dart` → `lib/features/upload/presentation/pages/`
- Move `lib/ui/widgets/timestamp_*` → `lib/features/upload/presentation/widgets/`
- Move `lib/ui/widgets/video_selection_buttons.dart` → `lib/features/upload/presentation/widgets/`
- Move `lib/ui/widgets/video_info_card.dart` → `lib/features/upload/presentation/widgets/`
- Move upload-specific dialogs → `lib/features/upload/presentation/widgets/`

**Feature: Results**
- Move `lib/ui/results_page.dart` → `lib/features/results/presentation/pages/`
- Move `lib/ui/demo_results_page.dart` → `lib/features/results/presentation/pages/`
- Move `lib/ui/widgets/feedback_list_item.dart` → `lib/features/results/presentation/widgets/`

---

## New Files to Create

### Core Infrastructure (3 files)
1. `lib/config/routes.dart` - All route definitions, guards, parameters
2. `lib/config/dependencies.dart` - DI setup (optional)
3. `lib/core/error/error_handler.dart` - Centralized error handling

### Feature: Upload (3 files)
4. `lib/features/upload/domain/repositories/video_repository.dart` - Repository abstraction
5. `lib/features/upload/presentation/controllers/video_player_manager.dart` - Video player lifecycle
6. `lib/features/upload/navigation/upload_route_guard.dart` - Navigation guard

### Feature: Home (1 file)
7. `lib/features/home/presentation/widgets/navigation_card.dart` - Extracted widget

### Feature: Stub Pages (2 files)
8. `lib/features/history/presentation/pages/history_page.dart` - History stub
9. `lib/features/profile/presentation/pages/profile_page.dart` - Profile stub

**Total new files: 9**

---

## Quick Quality Checklist

Use this to verify files before keeping them:

### For Models
- ✅ Immutable (all fields final)
- ✅ Has copyWith method
- ✅ Has toJson/fromJson
- ✅ No UI dependencies
- ✅ Has tests

### For Services
- ✅ Single responsibility
- ✅ No UI dependencies
- ✅ Returns/throws typed errors
- ✅ Platform-agnostic or has platform-specific implementations
- ✅ Testable (can be mocked)

### For Widgets
- ✅ Pure presentation (no business logic)
- ✅ Accepts data via constructor
- ✅ Uses callbacks for actions
- ✅ No direct service calls
- ✅ Reusable across features

### For Controllers
- ✅ Extends ChangeNotifier
- ✅ Exposes immutable state
- ✅ All mutations through methods
- ✅ No widget-specific code
- ✅ Testable with mocks

---

## Summary Statistics

- **Total existing Dart files**: ~40 files in lib/
- **Keep as-is**: 14 files (models + services + design system + widgets)
- **Refactor**: 16 files (pages + controllers + feature widgets)
- **Remove**: 1 file (stub_pages.dart)
- **New files to create**: 9 files

**Reuse ratio**: ~75% of existing code can be kept or refactored (only 25% needs complete rewrite)

---

## Migration Priority

1. **Day 1**: Foundation (config, routing, design system move)
2. **Day 2**: Shared components (models, services, shared widgets)
3. **Day 2-3**: Home feature (simple, good starting point)
4. **Day 3-5**: Upload feature (most complex, most value)
5. **Day 5-6**: Results feature (moderate complexity)
6. **Day 6-7**: Bottom navigation and integration
7. **Day 7-8**: Testing and polish

---

For complete implementation details, see `REBUILD_GUIDE.md`.

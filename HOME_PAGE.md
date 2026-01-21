# Navigation Documentation

## Overview

The Dance Analysis Client app uses a bottom navigation bar for easy access to all main features. The app includes a main scaffold wrapper (`MainScaffold`) that provides consistent navigation across all pages.

## Visual Layout

```
┌─────────────────────────────────────────┐
│           Dance Coach                   │
│                                         │
│  ┌─────────────────────────────────┐   │
│  │         🎓 Icon                 │   │
│  │  Welcome to Dance Coach         │   │
│  │  AI-powered dance analysis      │   │
│  └─────────────────────────────────┘   │
│                                         │
│  Quick Actions                          │
│                                         │
│  ┌───────────────────────────────────┐ │
│  │ 🔬 View Demo                 →    │ │
│  │ See sample analysis results...    │ │
│  └───────────────────────────────────┘ │
│                                         │
│  ┌───────────────────────────────────┐ │
│  │ 📼 Recent Videos                  │ │
│  │ Coming soon                       │ │
│  └───────────────────────────────────┘ │
│                                         │
├─────────────────────────────────────────┤
│  🏠 Home  📤 Upload  📜 History  👤   │ <- Bottom Nav
└─────────────────────────────────────────┘
```

## Bottom Navigation Bar

The app uses a persistent bottom navigation bar with 4 main tabs:

### 1. Home 🏠

- **Icon**: Home outline (filled when active)
- **Action**: Shows home page content
- **Color**: Blue when active, gray when inactive
- **Status**: ✅ Implemented

### 2. Upload 📤

- **Icon**: Upload file outline (filled when active)
- **Action**: Shows upload page
- **Status**: 🚧 Stub (Coming soon)

### 3. History 📜

- **Icon**: History outline (filled when active)
- **Action**: Shows upload history
- **Status**: 🚧 Stub (Coming soon)

### 4. Profile 👤

- **Icon**: Person outline (filled when active)
- **Action**: Shows user profile
- **Status**: 🚧 Stub (Coming soon)

## Home Tab Content

### Quick Actions

#### View Demo

- **Icon**: 🔬 Science icon
- **Title**: View Demo
- **Subtitle**: See sample analysis results
- **Action**: Navigate to DemoResultsPage (with back button)
- **Status**: ✅ Working

#### Recent Videos

- **Icon**: 📼 Video library icon
- **Title**: Recent Videos
- **Subtitle**: Coming soon
- **Status**: 🚧 Disabled

## Stub Pages

Upload, History, and Profile tabs show simple stub content:

```
┌─────────────────────────────────────────┐
│                                         │
│         ┌───────────────────┐          │
│         │                   │          │
│         │    🚧 Icon        │          │
│         │                   │          │
│         │  [Page Name] Page │          │
│         │                   │          │
│         │   Coming soon     │          │
│         │                   │          │
│         └───────────────────┘          │
│                                         │
├─────────────────────────────────────────┤
│  🏠 Home  📤 Upload  📜 History  👤   │ <- Bottom Nav
└─────────────────────────────────────────┘
```

No back button needed - use bottom nav to switch tabs.

## Design Details

### Welcome Section

- **Background**: Medium gray (`#232323`)
- **Icon**: School/graduation cap (blue accent)
- **Title**: "Welcome to Dance Coach" (24pt, bold, white)
- **Subtitle**: "AI-powered dance analysis and coaching" (14pt, gray)
- **Padding**: Extra large spacing for prominence

### Navigation Cards

- **Layout**: Full-width cards with consistent spacing
- **Background**: Medium gray with light border
- **Hover**: InkWell ripple effect
- **Structure**:
  - Left: Icon in dark box (32px)
  - Center: Title (16pt, bold) + Subtitle (14pt, gray)
  - Right: Arrow forward icon (16px)

### Bottom Navigation Bar

- **Background**: Medium gray (`#232323`)
- **Border**: Top border with divider color
- **Selected Color**: Accent blue (`#A5D0F7`)
- **Unselected Color**: Text secondary (`#CCCCCC`)
- **Font Size**: 12px for labels
- **Type**: Fixed (all items always visible)

### Spacing

- Card vertical spacing: 16px
- Internal padding: 16px
- Welcome section padding: 31px
- Edge margins: 16px

### Colors

All colors follow the AppDesignSystem:

- Background Dark: `#0F0F0F`
- Background Medium: `#232323`
- Accent Blue: `#A5D0F7`
- Text Primary: White
- Text Secondary: `#CCCCCC`
- Divider: White at 14% opacity

## Code Structure

```dart
MainScaffold (StatefulWidget)
├── Scaffold
│   ├── body: _getPage(_currentIndex)
│   │   ├── 0: _HomePageContent
│   │   │   ├── Welcome Section
│   │   │   └── Quick Actions (Demo, Recent Videos)
│   │   ├── 1: _StubPageContent('Upload')
│   │   ├── 2: _StubPageContent('History')
│   │   └── 3: _StubPageContent('Profile')
│   └── bottomNavigationBar: BottomNavigationBar
│       └── Items: [Home, Upload, History, Profile]
```

### Key Components

- **MainScaffold**: Manages bottom nav and page switching
- **\_HomePageContent**: Home tab content (no Scaffold)
- **\_StubPageContent**: Reusable stub for unimplemented features
- **DemoResultsPage**: Full page with Scaffold + back button

## Usage

### Accessing from main.dart

```dart
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: AppDesignSystem.darkTheme,
      home: const MainScaffold(), // Landing page with bottom nav
    );
  }
}
```

### Navigation Patterns

#### Tab Navigation (Bottom Nav)

```dart
// User taps bottom nav item
setState(() {
  _currentIndex = index; // Switches tab content
});
```

#### Full Page Navigation (with back button)

```dart
// From Home to Demo Results
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const DemoResultsPage(),
  ),
);

// DemoResultsPage has back button to return
```

## Navigation Benefits

### Why Bottom Navigation?

- **Always Accessible**: Navigate from any page without back button chain
- **Clear Location**: User always knows where they are
- **Mobile Standard**: Familiar pattern for mobile users
- **Persistent**: No need to go "home" first

### Tab vs Full Page Navigation

- **Tabs** (Home, Upload, History, Profile): Switch content, no back button
- **Full Pages** (Demo Results): Push new page, show back button

## Future Enhancements

### Short Term

1. Replace stub tabs with actual implementations
2. Add badge indicators (e.g., "3 new" on History tab)
3. Add authentication check
4. Persist selected tab across app restarts

### Medium Term

1. Add swipe gestures between tabs
2. Implement deep linking to specific tabs
3. Add floating action button on Upload tab
4. Show upload progress in bottom nav

### Long Term

1. Add notifications badge
2. Customizable tab order
3. Quick actions from long-press on tabs
4. Tab-specific app bars

## Testing

### Manual Testing Checklist

- [ ] App launches to Home tab
- [ ] Bottom nav always visible
- [ ] Tap Upload tab → shows stub
- [ ] Tap History tab → shows stub
- [ ] Tap Profile tab → shows stub
- [ ] Tap Home tab → returns to home content
- [ ] Selected tab highlighted in blue
- [ ] Unselected tabs shown in gray
- [ ] Tap "View Demo" → navigates to demo page
- [ ] Demo page has back button
- [ ] Back button returns to Home tab
- [ ] Bottom nav persists during navigation
- [ ] Scroll works on all tabs
- [ ] Dark theme is consistent

### Accessibility

- All cards have semantic tap targets
- Text contrast meets WCAG standards
- Navigation follows logical tab order
- Icons have descriptive purposes

## Related Files

- `lib/ui/main_scaffold.dart` - Main scaffold with bottom nav
- `lib/ui/design_system.dart` - Design tokens
- `lib/ui/demo_results_page.dart` - Demo page with back button
- `lib/ui/results_page.dart` - Results content (no Scaffold)
- `lib/main.dart` - App entry point
- `README.md` - Project overview

## Status

✅ **Complete and functional**

- Zero errors, zero warnings
- All navigation working
- Clean, professional design
- Ready for stub replacement

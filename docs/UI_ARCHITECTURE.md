# UI Architecture

This directory contains the Flutter UI components for the dance analysis client, built from the Figma design reference.

## Structure

```
ui/
├── design_system.dart       # Design tokens (colors, typography, spacing)
├── demo_results_page.dart   # Demo page with sample data
├── results_page.dart        # Main results/feedback display page
├── upload_page.dart         # Original upload page
├── figma_import.dart        # Raw Figma export (reference only, not used)
└── widgets/
    ├── feedback_list_item.dart      # Reusable feedback item widget
    ├── video_placeholder.dart       # Placeholder when video unavailable
    ├── video_player_with_overlay.dart  # Video player with pose overlay
    └── pose_overlay_painter.dart    # CustomPainter for pose skeleton
```

## Design System

The `design_system.dart` file contains all design tokens extracted from the Figma design:

- **Colors**: Background, accent, error, and text colors
- **Typography**: Pre-defined text styles for timestamps, feedback, tabs, etc.
- **Spacing**: Consistent spacing values (XS to XL)
- **Border Radius**: Standard radius values for different UI elements
- **Theme**: Complete Material theme for dark mode

### Usage Example

```dart
import 'package:flutter/material.dart';
import 'design_system.dart';

Text(
  'Hello',
  style: AppDesignSystem.timestampStyle.copyWith(
    color: AppDesignSystem.textPrimary,
  ),
)
```

## Data Models

Located in `lib/models/`:

### FeedbackItem

Represents a single piece of coaching feedback at a specific timestamp:

```dart
FeedbackItem(
  timestamp: '0:14',
  type: FeedbackType.negative,
  feedback: 'left foot should be rotated outward...',
)
```

Properties:

- `timestamp`: String (e.g., "0:14")
- `type`: `FeedbackType.positive` or `FeedbackType.negative`
- `feedback`: Optional detailed feedback text
- `icon`: Auto-generated based on type (▲ for positive, ▼ for negative)
- `duration`: Parsed `Duration` object

## Pages

### ResultsPage

Main page for displaying analysis feedback with timestamps.

**Features:**

- Displays list of feedback items
- Color-coded by feedback type (white for positive, red for negative)
- Expandable feedback details
- Tap timestamps to seek video (when integrated)
- Empty state handling

**Usage:**

```dart
ResultsPage(
  feedbackItems: [
    FeedbackItem(timestamp: '0:08', type: FeedbackType.positive),
    FeedbackItem(
      timestamp: '0:14',
      type: FeedbackType.negative,
      feedback: 'detailed feedback text...',
    ),
  ],
  onTimestampTap: (duration) {
    // Seek video to timestamp
  },
)
```

### DemoResultsPage

Demo page with sample feedback data for testing and demonstration.

## Widgets

### FeedbackListItem

Reusable widget for displaying individual feedback items.

**Features:**

- Shows timestamp with up/down arrow icon
- Color-coded based on feedback type
- Expandable detailed feedback text (click to expand/collapse)
- Tap handler for timestamp navigation
- Animated expand/collapse transitions

### VideoPlaceholder

Placeholder widget shown when video is not available.

**Features:**

- Clean, informative design
- Customizable message and icon
- Consistent with app design system
- Proper spacing and layout

**Usage:**

```dart
VideoPlaceholder(
  height: 250,
  message: 'Video Playback Unavailable',
  subtitle: 'The original video was not saved locally.',
  icon: Icons.video_library_outlined,
)
```

### VideoPlayerWithPoseOverlay

Video player with synchronized pose skeleton overlay (see VIDEO_OVERLAY_GUIDE.md).

**Features:**

- Plays local video files
- Pose skeleton overlay
- Highlight problem areas
- Playback controls
- Auto-sync with timestamps

### PoseOverlayPainter

CustomPainter for rendering pose skeleton on video (see VIDEO_OVERLAY_GUIDE.md).

## Switching Between Pages

In `main.dart`, change the home widget:

```dart
// Show demo results page (with placeholder, no video)
home: const DemoResultsPage(),

// Show upload page
home: const UploadPage(),
```

**Note:** The demo page shows the video placeholder since no actual video path is provided.

## Next Steps

### Integration Ideas

1. **Video Player Integration** ✅ DONE
   - Video player above feedback list
   - Timestamp seeking ready
   - Pose overlay system complete
   - Placeholder for missing videos

2. **API Integration**
   - Fetch feedback from backend after upload
   - Parse API response into `FeedbackItem` objects
   - Navigate from `UploadPage` to `ResultsPage` on success

3. **Enhancements**
   - Add filtering (show only errors, only positive)
   - Add search/filter by feedback text
   - Add export functionality (PDF, share)
   - Add video playback controls
   - Add side-by-side comparison view

### Example Flow

```
UploadPage → [Upload Video] → [Processing] → ResultsPage
                                               ↓
                                      [Display Feedback]
                                               ↓
                                      [Tap Timestamp]
                                               ↓
                                      [Seek Video]
```

## Design Reference

The original Figma design can be found in `figma_import.dart`. This file is kept for reference but should not be used directly due to:

- Invalid `FontWeight` values
- Hardcoded pixel dimensions
- Non-responsive layout
- Monolithic structure

The new implementation extracts the design intent while following Flutter best practices.

## Color Palette

| Color             | Hex       | Usage                               |
| ----------------- | --------- | ----------------------------------- |
| Background Dark   | `#0F0F0F` | Main background                     |
| Background Medium | `#232323` | Card/surface background             |
| Accent Blue       | `#A5D0F7` | Buttons, tabs, highlights           |
| Error Red         | `#DE3737` | Error feedback, negative timestamps |
| Text Primary      | `#FFFFFF` | Primary text                        |
| Text Secondary    | `#CCCCCC` | Secondary text                      |
| Text Disabled     | `#404040` | Disabled elements                   |

## Typography Scale

| Style     | Size | Weight | Usage            |
| --------- | ---- | ------ | ---------------- |
| Timestamp | 16pt | 500    | Timestamp labels |
| Feedback  | 14pt | 500    | Feedback text    |
| Tab       | 14pt | 600    | Tabs and buttons |
| Small     | 12pt | 500    | Small labels     |

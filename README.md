# Dance Analysis Client

A Flutter application for AI-powered dance coaching and analysis.

## Overview

This app allows dancers to upload practice videos, receive AI-generated feedback, and review their performance with detailed pose analysis overlays.

## Features

### ✅ Implemented

- **Home Page** - Main landing page with navigation
- **Results Page** - View analysis results with:
  - Expandable feedback list
  - Color-coded timestamps (positive/negative)
  - Video player with pose skeleton overlay
  - Red circle highlights for problem areas
- **Demo Mode** - Sample results page with demo data
- **Design System** - Consistent dark theme with custom colors and typography
- **Video Overlay System** - Pose skeleton visualization using backend coordinates

### 🚧 Stub Pages (Coming Soon)

- Upload - Upload practice videos for analysis
- Review - Review pending analysis results
- History - View past uploads and track progress
- Profile - Manage account settings

## Project Structure

```
lib/
├── main.dart                    # App entry point
├── models/
│   ├── feedback_item.dart       # Feedback data model
│   └── pose_data.dart           # Pose skeleton data model
├── services/
│   ├── api_client.dart          # Backend API communication
│   └── video_service.dart       # Video handling
├── state/
│   ├── upload_controller.dart   # Upload flow logic
│   └── upload_state.dart        # Upload state management
└── ui/
    ├── design_system.dart       # Design tokens (colors, typography, spacing)
    ├── home_page.dart           # Main landing page
    ├── demo_results_page.dart   # Demo results with sample data
    ├── results_page.dart        # Analysis results display
    ├── upload_page.dart         # Video upload page
    └── widgets/
        ├── feedback_list_item.dart         # Expandable feedback item
        ├── video_placeholder.dart          # Placeholder for missing videos
        ├── video_player_with_overlay.dart  # Video player component
        └── pose_overlay_painter.dart       # CustomPainter for pose skeleton
```

## Navigation Structure

```
HomePage
├── Upload → UploadPage (stub)
├── Review → ReviewPage (stub)
├── History → HistoryPage (stub)
├── Profile → ProfilePage (stub)
└── Demo Results → DemoResultsPage (working demo)
```

## Getting Started

### Prerequisites

- Flutter SDK (3.10.7+)
- Dart SDK
- iOS/Android development tools (for mobile)

### Installation

1. Clone the repository
2. Install dependencies:

   ```bash
   flutter pub get
   ```

3. Run the app:
   ```bash
   flutter run
   ```

## Architecture

### Data Flow

```
User uploads video → Server processes → Returns JSON
         ↓
Local video saved (no re-download!)
         ↓
Client receives:
  - Feedback items (timestamps + text)
  - Pose data (X,Y coordinates per frame)
         ↓
Client displays:
  - Local video with playback
  - Pose skeleton overlay (synchronized)
  - Expandable feedback list
```

### Backend Integration

The app expects JSON responses in this format:

```json
{
  "feedback_items": [
    {
      "timestamp": "0:14",
      "type": "negative",
      "feedback": "left foot should be rotated outward..."
    }
  ],
  "pose_data": [
    {
      "timestamp": 0.14,
      "keypoints": [
        { "name": "left_ankle", "x": 0.45, "y": 0.95, "confidence": 0.95 }
      ],
      "highlighted_keypoints": [5, 6]
    }
  ]
}
```

## Design System

### Colors

- **Background Dark**: `#0F0F0F` - Main background
- **Background Medium**: `#232323` - Cards and surfaces
- **Accent Blue**: `#A5D0F7` - Buttons and highlights
- **Error Red**: `#DE3737` - Negative feedback
- **Text Primary**: `#FFFFFF` - Primary text
- **Text Secondary**: `#CCCCCC` - Secondary text

### Typography

All text uses consistent styles defined in `AppDesignSystem`:

- Timestamps: 16pt, medium weight
- Feedback: 14pt, medium weight
- Tabs: 14pt, semi-bold

## Video Player & Pose Overlay

The app includes a complete video player with pose skeleton overlay system. See `VIDEO_PLAYER_SUMMARY.md` and `lib/ui/VIDEO_OVERLAY_GUIDE.md` for detailed documentation.

### Key Features

- Plays local video files (bandwidth savings)
- Synchronized pose skeleton overlay
- Highlights problem areas with red circles
- Auto-scales to video dimensions
- Supports normalized (0-1) or pixel coordinates

## Development

### Running the Demo

The app launches to the HomePage by default. Click "Demo Results" to see:

- Video placeholder (no actual video)
- Sample feedback items
- Expandable feedback details
- Color-coded timestamps

### Adding New Pages

1. Create page in `lib/ui/`
2. Update HomePage navigation in `home_page.dart`
3. Replace stub navigation with real page

### Code Quality

- ✅ Zero errors, zero warnings
- ✅ Follows Flutter best practices
- ✅ Comprehensive documentation
- ✅ Reusable components
- ✅ Type-safe models

## Documentation

- **README.md** (this file) - Project overview
- **VIDEO_PLAYER_SUMMARY.md** - Video player implementation summary
- **lib/ui/VIDEO_OVERLAY_GUIDE.md** - Complete technical guide for video overlay
- **WARP.md** - Warp-specific documentation

## Next Steps

1. Implement Upload page (connect to UploadPage)
2. Add API endpoint for analysis results
3. Implement Review page (list of pending analyses)
4. Implement History page (past uploads)
5. Implement Profile page (user settings)
6. Add authentication
7. Add cloud storage integration

## License

[Add your license here]

## Support

[Add support contact information]

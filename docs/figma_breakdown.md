# Figma Scaffold Breakdown

This document captures the first-pass breakdown of `docs/figma_generated.dart` into real app widgets.

## Purpose

The generated Figma output is a visual reference, not production-ready Flutter code. The goal is to:

- preserve layout intent
- remove Figma-specific colors and styling
- use the app’s existing theme and design system
- split the giant generated tree into small, reusable widgets
- wire those widgets to real state and behavior

---

## Screens identified in the generated file

The generated file appears to contain three separate mock screens embedded into one widget tree.

### 1. Video detail / conversation screen

This is the first large 375x812 layout.

#### Visible regions
- status bar
- top header
  - back button placeholder
  - title: `Video Title`
  - subtitle: `Routine Name - Group Name`
  - date
- video preview panel
- group filter chips over the video
- comment thread / feedback bubbles
- message composer at the bottom
- bottom action/navigation strip

#### Functional interpretation
This should likely become the primary interaction screen for:
- reviewing a video
- leaving comments or notes
- referencing timestamps in feedback
- sending messages to the group or dancer

#### Suggested screen name
- `VideoDetailScreen`

---

### 2. Activity feed screen

This is the second 375x812 layout.

#### Visible regions
- status bar / top safe area
- header with:
  - `Routine Name`
  - `Group Name`
- section titles:
  - `Steps`
  - `Notes`
  - `Videos`
  - `Activity`
- group chips row
- list of activity feed items
- notification badge
- bottom navigation strip

#### Functional interpretation
This should become a feed-style page showing:
- recent activity
- updates from teammates or coaches
- actions taken on routines, notes, or videos
- quick call-to-action buttons

#### Suggested screen name
- `ActivityScreen`

---

### 3. Routines list screen

This is the third 375x812 layout.

#### Visible regions
- status bar / top safe area
- page title: `Routines`
- group chips row
- repeated routine list rows
- divider lines
- bottom navigation strip

#### Functional interpretation
This should become the routines index page:
- browse routines
- filter by group
- open a routine detail page
- maybe search/sort later

#### Suggested screen name
- `RoutinesScreen`

---

## Shared UI patterns to extract

These should become reusable widgets instead of being recreated in each screen.

### `AppTopBar`

Used for:
- title
- subtitle
- date or secondary metadata
- optional leading and trailing actions

#### Responsibilities
- align with app theme
- use `Theme.of(context).textTheme`
- support optional divider or surface styling
- avoid hardcoded Figma sizing where possible

---

### `AppBottomNavBar`

Used for the bottom navigation/action strip.

#### Responsibilities
- show 4 or 5 primary destinations
- highlight the selected item
- support notification badges
- use the app’s existing navigation pattern

---

### `GroupFilterChips`

Used for the pill-like group filters.

#### Responsibilities
- render a horizontal chip row
- support selected/unselected state
- accept a list of group names
- scroll horizontally on small screens

---

### `CommentBubble`

Used for the chat-style notes in the video screen.

#### Variants seen in the generated file
- plain bubble
- bubble with mention/time text
- bubble with `@All`
- left-aligned conversation style

#### Responsibilities
- support author/receiver alignment
- support rich text spans
- support mention highlighting
- use theme colors, not Figma colors

---

### `VideoPreviewPanel`

Used for the video mock area in the first screen.

#### Responsibilities
- represent the real video player surface
- show playback controls or overlays
- show timeline/progress
- support timestamp markers if needed

---

### `ActivityFeedItem`

Used for the repeated activity cards.

#### Responsibilities
- avatar
- username
- timestamp
- summary text
- optional action button
- unread indicator badge

---

### `RoutineListItem`

Used for the repeated routine rows.

#### Responsibilities
- title
- subtitle
- optional metadata or status
- optional trailing icon
- divider or spacing between rows

---

## Theme migration rules

When rebuilding these widgets, do not preserve the Figma styling verbatim.

### Colors
Replace hardcoded colors with semantic theme values:
- `Theme.of(context).colorScheme.primary`
- `Theme.of(context).colorScheme.secondary`
- `Theme.of(context).colorScheme.surface`
- `Theme.of(context).colorScheme.onSurface`
- `Theme.of(context).colorScheme.outline`
- `Theme.of(context).colorScheme.error`

### Typography
Map generated text styles to the app theme:
- large titles -> `headlineSmall` / `titleLarge`
- section headers -> `titleMedium`
- body text -> `bodyMedium`
- secondary labels -> `bodySmall`
- pill labels / badges -> `labelLarge` / `labelSmall`

### Spacing
Prefer consistent app spacing:
- 4
- 8
- 12
- 16
- 24
- 32

Avoid Figma-specific absolute offsets unless needed for a real layout constraint.

### Borders / shadows
Use the app’s existing card/surface styling instead of Figma-generated borders and shadows.

---

## Suggested folder structure

Keep this feature isolated in its own folder.

```text
lib/features/figma_scaffold/
  presentation/
    screens/
      video_detail_screen.dart
      activity_screen.dart
      routines_screen.dart
    widgets/
      app_top_bar.dart
      app_bottom_nav_bar.dart
      group_filter_chips.dart
      comment_bubble.dart
      video_preview_panel.dart
      activity_feed_item.dart
      routine_list_item.dart
```

Optional later additions:
- `domain/`
- `application/`
- `data/`

---

## Extraction order

### Phase 1: Skeleton
Create the screen shells first:
- `VideoDetailScreen`
- `ActivityScreen`
- `RoutinesScreen`

At this stage, each screen should:
- use `Scaffold`
- use theme-consistent styling
- compose placeholder widgets
- avoid hardcoded Figma visual styling

---

### Phase 2: Shared widgets
Create the reusable widgets next:
- `AppTopBar`
- `GroupFilterChips`
- `CommentBubble`
- `ActivityFeedItem`
- `RoutineListItem`
- `VideoPreviewPanel`
- `AppBottomNavBar`

---

### Phase 3: Behavior
Once the layout is stable:
- connect buttons to actions
- wire navigation
- connect feed data and routine data
- make comment bubbles dynamic
- add real video playback integration

---

### Phase 4: Cleanup
After the new scaffold is complete:
- remove the generated file from the active UI path
- keep it only as a reference if needed
- delete any placeholder wrappers that are no longer useful

---

## Notes on the generated file

The generated output uses many:
- `Positioned`
- `Stack`
- fixed widths/heights
- placeholder icons
- mock avatars
- hardcoded text
- Figma-specific colors

Those should be treated as layout hints only, not implementation details.

---

## Working principle

Use the generated file to answer only these questions:

1. What are the major screens?
2. What are the repeated components?
3. What is the intended hierarchy?
4. Where is the interactive surface?

Then rebuild the implementation using:
- existing theme
- reusable widgets
- app state
- normal Flutter layout primitives

---

## Next implementation step

Create the scaffold folder and start with:
1. screen shells
2. shared widgets
3. route integration

This will make the generated design usable without carrying over the mock styling.

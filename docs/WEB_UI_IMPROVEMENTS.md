# Web UI Improvements

Observations and recommendations based on a code audit of every page and widget. Items are grouped by theme and ordered roughly by impact.

---

## 1. Max-width content containers

**Problem:** Every page lets its content stretch to the full browser window width. On a 1440px monitor a `ListView` of group cards becomes a wall of awkwardly wide rows.

**Affected files:**
- `groups_list_page.dart` — `ListView.separated`, no width constraint
- `routines_list_page.dart` — same
- `group_detail_page.dart` — tabs with `ListView.separated` / `ListView.builder`
- `routine_detail_page.dart` — three tabs, all full-width
- `instance_detail_page.dart` — two tabs, full-width
- `home_page.dart` — `Column` with `CrossAxisAlignment.stretch`

**Fix:** Wrap each page's scroll body in a `Center` → `ConstrainedBox(constraints: BoxConstraints(maxWidth: 960))`. On narrow viewports the constraint has no effect; on wide ones it keeps content readable. Only needs to be applied on web (`kIsWeb`).

---

## 2. Hover cursor on tappable items

**Problem:** Flutter web renders an `arrow` cursor over cards, list tiles, and buttons unless told otherwise. Every clickable surface in a browser should show a `pointer` cursor.

**Affected widgets:**
- `navigation_card.dart` — `InkWell` wraps the card (line 18), no `MouseRegion`
- `group_card.dart` — same pattern (line 18)
- `ListTile`s in `_MembersTab`, `_RoutinesTab`, `_VideosTab` across detail pages
- `ElevatedButton` / `TextButton` — Flutter handles these automatically, not an issue

**Fix:** Wrap `InkWell` usages in a `MouseRegion(cursor: SystemMouseCursors.click, child: ...)`. For `ListTile`s, `ListTile` accepts a `mouseCursor` parameter directly.

---

## 3. Lists → responsive grid on wide screens

**Problem:** All list pages use single-column `ListView`. On a wide screen a grid of cards looks far more natural for browsing groups or routines.

**Affected files:**
- `groups_list_page.dart` — renders one `GroupCard` per row
- `routines_list_page.dart` — renders one routine card per row
- `home_page.dart` — three `NavigationCard`s stacked vertically

**Fix:** Use `LayoutBuilder` to switch between `ListView` (narrow) and `GridView.builder` (wide) based on available width. A reasonable breakpoint is 600px; at that point a 2-column grid works well, and 3 columns at 900px+. The `home_page.dart` navigation cards could become a `Row` of equal-width cards at ≥600px.

---

## 4. Replace FloatingActionButtons with AppBar actions

**Problem:** FABs are a mobile-native pattern — a circular button floating over content doesn't read as well in a browser, and it covers page content on wider viewports.

**Affected files:**
- `groups_list_page.dart` — FAB opens `_showCreateGroupDialog` (line 66)
- `routines_list_page.dart` — FAB opens `CreateRoutineDialog` (line 98)
- `group_detail_page.dart` — FAB switches between `CreateInstanceInGroupDialog` / `CreateInviteDialog` depending on active tab (lines 96–108)
- `routine_detail_page.dart` — FAB switches between actions per tab (lines 131–141)
- `instance_detail_page.dart` — FAB switches per tab (lines 104–114)

**Fix:** On web, pass the action into the page's `AppBar` as a trailing `actions:` `IconButton` or `TextButton` (e.g. `+ New Group`). The FAB can remain for native. Guard with `kIsWeb`.

---

## 5. Dialog max-width constraints

**Problem:** Flutter's `AlertDialog` on web expands to fill a large fraction of the window. `CreateGroupDialog`, `CreateInviteDialog`, and the many inline `AlertDialog`s across detail pages all suffer from this.

**Affected widgets:**
- `create_group_dialog.dart` — `AlertDialog` with `mainAxisSize.min` column, no width cap
- `create_invite_dialog.dart` — same
- Inline `AlertDialog`s in `routine_detail_page.dart` (×4), `group_detail_page.dart` (×1), `instance_detail_page.dart` (×2)

**Fix:** Wrap dialog content in a `ConstrainedBox(constraints: BoxConstraints(maxWidth: 480))`. Flutter's `AlertDialog` respects the `constraints` parameter directly in recent versions, or the wrapping can be done in the `builder` passed to `showDialog`.

---

## 6. Video detail — two-column layout on wide screens

**Problem:** `video_detail_page.dart` renders the video player above a notes list in a single column. On a wide screen this wastes a lot of horizontal space and requires scrolling to see notes while the video plays.

**Fix:** On web at widths ≥ 800px, use a `Row`: video player (`AspectRatio(16/9)`) on the left in a ~60% column, and the notes/info panel on the right in a scrollable ~40% column. The `ComposerBar` can sit below the right column. Use `LayoutBuilder` to switch layouts. The existing `video_detail_page.dart` already separates video and notes into distinct widget helpers, making this straightforward.

---

## 7. Pull-to-refresh

**Problem:** `routines_list_page.dart` wraps its `ListView` in a `RefreshIndicator`. Pull-to-refresh is a touch gesture that doesn't exist in a browser. On web it either does nothing or triggers unexpectedly with a trackpad.

**Fix:** On web, remove the `RefreshIndicator` wrapper and instead add a small refresh `IconButton` to the AppBar (alongside the "add" action from item 4).

---

## 8. Scrollbar visibility

**Problem:** Flutter web hides scrollbars by default on most platforms. Long lists of routines, videos, or notes give no visual indication that the content is scrollable.

**Fix:** Wrap `ListView`s in a `Scrollbar` widget. Flutter's `Scrollbar` is a no-op on mobile (where the OS handles it), so no `kIsWeb` guard is needed — it's safe to add unconditionally. The design system `mainAccent` colour would be automatically applied via `ProgressIndicatorTheme.color` or via an explicit `thumbVisibility: true`.

---

## 9. Page-level AppBar titles on sub-pages

**Problem:** With the global top nav now in place on web, individual page `AppBar`s render a second header bar — one for global nav, one for the page title. This creates a double-header that looks cluttered, especially on detail pages with a `TabBar` bottom.

**Options:**
- Remove the `AppBar` from pages that are navigated to from the global nav (groups list, routines list, home), since the top nav already establishes context
- Keep the `AppBar` on deep-link pages (group detail, routine detail, instance detail, video detail) since those pages need a back button and page-specific title
- For list pages on web: promote the page title into the content area as a `headlineMedium` text widget above the list, and suppress the `AppBar`

---

## 10. Text selection and pointer events

**Problem:** On mobile, most body text is not selectable (correct). On web, users expect to be able to select and copy text like group names, descriptions, usernames, and video titles.

**Affected areas:** Group names / descriptions in `group_card.dart` and `group_detail_page.dart`, routine names in `routine_detail_page.dart`, notes in `instance_detail_page.dart` and `video_detail_page.dart`.

**Fix:** Wrap read-only body text in `SelectableText` instead of `Text` on web. Guard with `kIsWeb` to avoid unwanted selection handles on mobile.

---

## 11. Keyboard shortcuts and focus

**Problem:** Forms across the app use `TextInputAction.done` / `onSubmitted` (e.g. `create_invite_dialog.dart` line 97, `create_group_dialog.dart`), which submit on Enter key — good. But tab-order through multi-field forms isn't explicitly set, so tabbing between fields in the login page or create-group dialog may jump unpredictably.

**Fix:** Add explicit `FocusNode`s and `autofocus: true` on the first field of each dialog/form. Use `FocusScope.of(context).nextFocus()` in `onFieldSubmitted` to move between fields before final submission. The login page (`login_page.dart`) is the highest priority since it has three fields.

---

## Priority order for implementation

| # | Item | Effort | Impact |
|---|---|---|---|
| 1 | Max-width content containers | Low | High |
| 2 | Hover cursor on cards/tiles | Low | High |
| 5 | Dialog max-width | Low | High |
| 4 | FAB → AppBar actions on web | Medium | High |
| 3 | Responsive grid layouts | Medium | High |
| 7 | Remove pull-to-refresh on web | Low | Medium |
| 8 | Scrollbar visibility | Low | Medium |
| 6 | Video detail two-column layout | Medium | Medium |
| 9 | Suppress redundant AppBars on web | Medium | Medium |
| 10 | SelectableText on web | Low | Low |
| 11 | Keyboard focus order | Medium | Low |

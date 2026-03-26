import 'package:flutter/material.dart';

import '../widgets/activity_feed_item.dart';
import '../widgets/group_filter_chips.dart';

class ActivityScreen extends StatefulWidget {
  const ActivityScreen({super.key});

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  int _selectedGroupIndex = 0;

  static const _groups = ['All', 'Group 1', 'Group 2', 'Group 3'];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Routine Name',
              style: textTheme.titleLarge?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Group Name',
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        centerTitle: false,
        elevation: 0,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
      ),
      body: SafeArea(
        child: Column(
          children: [
            const _SectionTabs(),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GroupFilterChips(
                groups: _groups,
                selectedIndex: _selectedGroupIndex,
                onSelected: (i) => setState(() => _selectedGroupIndex = i),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                children: [
                  Text(
                    'Activity',
                    style: textTheme.titleLarge?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const ActivityFeedItem(
                    username: 'starryskies23',
                    timestamp: '1d',
                    summary: 'Added notes for you',
                    actionLabel: 'View',
                    unread: true,
                    avatarLabel: 'SS',
                  ),
                  const SizedBox(height: 12),
                  const ActivityFeedItem(
                    username: 'nebulanomad',
                    timestamp: '1d',
                    summary: 'Uploaded a new video',
                    actionLabel: 'View',
                    unread: true,
                    avatarLabel: 'N',
                  ),
                  const SizedBox(height: 12),
                  const ActivityFeedItem(
                    username: 'emberecho',
                    timestamp: '2d',
                    summary: 'Responded to your note',
                    unread: true,
                    avatarLabel: 'E',
                  ),
                  const SizedBox(height: 12),
                  const ActivityFeedItem(
                    username: 'shadowlynx',
                    timestamp: '4d',
                    summary: 'Changed a Routine',
                    detail: 'New steps here',
                    actionLabel: 'View',
                    unread: true,
                    avatarLabel: 'S',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTabs extends StatelessWidget {
  const _SectionTabs();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final tabs = <({String label, bool selected})>[
      (label: 'Steps', selected: false),
      (label: 'Notes', selected: false),
      (label: 'Videos', selected: false),
      (label: 'Activity', selected: true),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          spacing: 8,
          children: [
            for (final tab in tabs)
              ChoiceChip(
                label: Text(tab.label),
                selected: tab.selected,
                onSelected: (_) {},
                labelStyle: textTheme.labelLarge?.copyWith(
                  color: tab.selected
                      ? colorScheme.onPrimary
                      : colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
                selectedColor: colorScheme.primary,
                backgroundColor: colorScheme.surfaceContainerHighest,
                side: BorderSide(color: colorScheme.outlineVariant),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

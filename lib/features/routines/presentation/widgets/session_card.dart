import 'package:flutter/material.dart';

import '../../../../generated/api/models/routine_session_response.dart';
import '../../../../shared/design_system/theme.dart';

/// Card displaying a shared session in the routines feed.
class SessionCard extends StatelessWidget {
  const SessionCard({
    super.key,
    required this.session,
    required this.isArchived,
    this.onTap,
    this.onArchive,
    this.onUnarchive,
    this.onHide,
  });

  final RoutineSessionResponse session;
  final bool isArchived;
  final VoidCallback? onTap;
  final VoidCallback? onArchive;
  final VoidCallback? onUnarchive;
  final VoidCallback? onHide;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final label = session.label?.isNotEmpty == true ? session.label! : 'Untitled';

    return InkWell(
      onTap: onTap,
      mouseCursor: SystemMouseCursors.click,
      borderRadius: BorderRadius.circular(AppDesignSystem.radiusSm),
      child: Container(
        padding: const EdgeInsets.all(AppDesignSystem.spacingMd),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(AppDesignSystem.radiusSm),
          border: Border.all(color: colorScheme.outline, width: 1),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppDesignSystem.spacingSm),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius:
                    BorderRadius.circular(AppDesignSystem.radiusXs),
              ),
              child: Icon(
                Icons.group_outlined,
                color: colorScheme.secondary,
                size: 24,
              ),
            ),
            const SizedBox(width: AppDesignSystem.spacingMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        'Shared',
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      if (isArchived) ...[
                        const SizedBox(width: AppDesignSystem.spacingSm),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Archived',
                            style: textTheme.labelSmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            if (onArchive != null || onUnarchive != null || onHide != null)
              PopupMenuButton<_SessionAction>(
                icon: Icon(Icons.more_vert,
                    size: 18, color: colorScheme.onSurfaceVariant),
                onSelected: (action) {
                  switch (action) {
                    case _SessionAction.archive:
                      onArchive?.call();
                    case _SessionAction.unarchive:
                      onUnarchive?.call();
                    case _SessionAction.hide:
                      onHide?.call();
                  }
                },
                itemBuilder: (_) => [
                  if (!isArchived && onArchive != null)
                    const PopupMenuItem(
                      value: _SessionAction.archive,
                      child: Text('Archive'),
                    ),
                  if (isArchived && onUnarchive != null)
                    const PopupMenuItem(
                      value: _SessionAction.unarchive,
                      child: Text('Unarchive'),
                    ),
                  if (onHide != null)
                    const PopupMenuItem(
                      value: _SessionAction.hide,
                      child: Text('Remove from my list'),
                    ),
                ],
              )
            else
              Icon(
                Icons.arrow_forward_ios,
                color: colorScheme.onSurfaceVariant,
                size: 16,
              ),
          ],
        ),
      ),
    );
  }
}

enum _SessionAction { archive, unarchive, hide }

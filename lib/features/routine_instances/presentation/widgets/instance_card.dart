import 'package:flutter/material.dart';

import '../../../../generated/api/models/routine_session_response.dart';
import '../../../../shared/design_system/theme.dart';

/// Card displaying a routine instance's label and date.
class InstanceCard extends StatelessWidget {
  const InstanceCard({super.key, required this.instance, this.onTap});

  final RoutineSessionResponse instance;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final label = instance.label ?? 'Routine ${instance.id.substring(0, 8)}';
    final date = instance.createdAt;
    final dateStr = '${date.month}/${date.day}/${date.year}';

    return InkWell(
      onTap: onTap,
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
                borderRadius: BorderRadius.circular(AppDesignSystem.radiusXs),
              ),
              child: Icon(
                Icons.video_library,
                color: colorScheme.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: AppDesignSystem.spacingMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    dateStr,
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
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

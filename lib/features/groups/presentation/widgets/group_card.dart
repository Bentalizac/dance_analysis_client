import 'package:flutter/material.dart';

import '../../../../generated/api/models/group_response.dart';
import '../../../../shared/design_system/theme.dart';

/// Card displaying a group's name and description.
class GroupCard extends StatelessWidget {
  const GroupCard({super.key, required this.group, this.onTap});

  final GroupResponse group;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppDesignSystem.radiusSm),
      child: Container(
        padding: const EdgeInsets.all(AppDesignSystem.spacingMd),
        decoration: BoxDecoration(
          color: AppDesignSystem.backgroundMedium,
          borderRadius: BorderRadius.circular(AppDesignSystem.radiusSm),
          border: Border.all(color: AppDesignSystem.dividerLight, width: 1),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppDesignSystem.spacingMd),
              decoration: BoxDecoration(
                color: AppDesignSystem.backgroundMedium,
                borderRadius: BorderRadius.circular(AppDesignSystem.radiusXs),
              ),
              child: Icon(
                Icons.group,
                color: AppDesignSystem.mainAccent,
                size: 32,
              ),
            ),
            const SizedBox(width: AppDesignSystem.spacingMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    group.name,
                    style: AppDesignSystem.timestampStyle.copyWith(
                      color: AppDesignSystem.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (group.description != null &&
                      group.description!.isNotEmpty) ...[
                    const SizedBox(height: AppDesignSystem.spacingXs),
                    Text(
                      group.description!,
                      style: AppDesignSystem.feedbackStyle.copyWith(
                        color: AppDesignSystem.textSecondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: AppDesignSystem.textSecondary,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}

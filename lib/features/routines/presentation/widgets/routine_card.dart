import 'package:flutter/material.dart';

import '../../../../generated/api/models/routine_response.dart';
import '../../../../shared/design_system/theme.dart';

/// Card displaying a routine's title.
class RoutineCard extends StatelessWidget {
  const RoutineCard({super.key, required this.routine, this.onTap});

  final RoutineResponse routine;
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
              padding: const EdgeInsets.all(AppDesignSystem.spacingSm),
              decoration: BoxDecoration(
                color: AppDesignSystem.backgroundMedium,
                borderRadius: BorderRadius.circular(AppDesignSystem.radiusXs),
              ),
              child: Icon(
                Icons.library_music,
                color: AppDesignSystem.mainAccent,
                size: 24,
              ),
            ),
            const SizedBox(width: AppDesignSystem.spacingMd),
            Expanded(
              child: Text(
                routine.title,
                style: AppDesignSystem.feedbackStyle.copyWith(
                  color: AppDesignSystem.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
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

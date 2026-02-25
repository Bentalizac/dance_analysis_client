import 'package:flutter/material.dart';

import '../../generated/api/models/job_status.dart';
import '../design_system/theme.dart';

/// Display helpers for [JobStatus] used by History UI.
extension JobStatusDisplay on JobStatus {
  /// Human-readable label for this status.
  String get displayLabel => switch (this) {
        JobStatus.pending => 'Queued',
        JobStatus.processing => 'Processing…',
        JobStatus.completed => 'Completed',
        JobStatus.failed => 'Failed',
        JobStatus.$unknown => 'Unknown',
      };

  /// Background color for the status chip.
  Color get chipColor => switch (this) {
        JobStatus.pending => AppDesignSystem.textSecondary.withValues(alpha: 0.2),
        JobStatus.processing => AppDesignSystem.accentBlue.withValues(alpha: 0.2),
        JobStatus.completed => Colors.green.withValues(alpha: 0.2),
        JobStatus.failed => AppDesignSystem.errorRed.withValues(alpha: 0.2),
        JobStatus.$unknown => AppDesignSystem.textSecondary.withValues(alpha: 0.2),
      };

  /// Foreground / text color for the status chip.
  Color get chipTextColor => switch (this) {
        JobStatus.pending => AppDesignSystem.textSecondary,
        JobStatus.processing => AppDesignSystem.accentBlue,
        JobStatus.completed => Colors.green,
        JobStatus.failed => AppDesignSystem.errorRed,
        JobStatus.$unknown => AppDesignSystem.textSecondary,
      };
}

import 'package:flutter/material.dart';
import '../../models/video_timestamp.dart';
import '../design_system.dart';

/// Dialog for adding or editing a video timestamp with a dance step label
class AddTimestampDialog extends StatefulWidget {
  const AddTimestampDialog({
    super.key,
    required this.currentPosition,
    this.existingTimestamp,
    this.maxDuration,
  });

  /// Current video playback position (used as default for new timestamps)
  final Duration currentPosition;

  /// If editing an existing timestamp, pass it here
  final VideoTimestamp? existingTimestamp;

  /// Maximum allowed duration (video length)
  final Duration? maxDuration;

  @override
  State<AddTimestampDialog> createState() => _AddTimestampDialogState();
}

class _AddTimestampDialogState extends State<AddTimestampDialog> {
  late final TextEditingController _labelController;
  late Duration _selectedTime;

  @override
  void initState() {
    super.initState();
    _labelController = TextEditingController(
      text: widget.existingTimestamp?.label ?? '',
    );
    _selectedTime =
        widget.existingTimestamp?.timestamp ?? widget.currentPosition;
  }

  @override
  void dispose() {
    _labelController.dispose();
    super.dispose();
  }

  bool get _isValid => _labelController.text.trim().isNotEmpty;

  String get _formattedTime {
    final minutes = _selectedTime.inMinutes;
    final seconds = _selectedTime.inSeconds.remainder(60);
    return '${minutes.toString().padLeft(1, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  void _submit() {
    if (!_isValid) return;

    final result = VideoTimestamp(
      id: widget.existingTimestamp?.id ?? '',
      timestamp: _selectedTime,
      label: _labelController.text.trim(),
    );

    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppDesignSystem.backgroundMedium,
      title: Text(
        widget.existingTimestamp == null ? 'Add Timestamp' : 'Edit Timestamp',
        style: const TextStyle(
          color: AppDesignSystem.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Timestamp display
            Text(
              'Timestamp',
              style: AppDesignSystem.smallTextStyle.copyWith(
                color: AppDesignSystem.textSecondary,
              ),
            ),
            const SizedBox(height: AppDesignSystem.spacingXs),
            Container(
              padding: const EdgeInsets.all(AppDesignSystem.spacingMd),
              decoration: BoxDecoration(
                color: AppDesignSystem.backgroundDark,
                borderRadius: BorderRadius.circular(AppDesignSystem.radiusXs),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.access_time,
                    color: AppDesignSystem.accentBlue,
                    size: 20,
                  ),
                  const SizedBox(width: AppDesignSystem.spacingSm),
                  Text(
                    _formattedTime,
                    style: AppDesignSystem.timestampStyle.copyWith(
                      color: AppDesignSystem.textPrimary,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppDesignSystem.spacingMd),

            // Timestamp adjustment slider (if we know max duration)
            if (widget.maxDuration != null) ...[
              Slider(
                value: _selectedTime.inSeconds.toDouble(),
                min: 0,
                max: widget.maxDuration!.inSeconds.toDouble(),
                divisions: widget.maxDuration!.inSeconds,
                activeColor: AppDesignSystem.accentBlue,
                inactiveColor: AppDesignSystem.dividerLight,
                onChanged: (value) {
                  setState(() {
                    _selectedTime = Duration(seconds: value.toInt());
                  });
                },
              ),
              const SizedBox(height: AppDesignSystem.spacingMd),
            ],

            // Step name input
            Text(
              'Dance Step Name',
              style: AppDesignSystem.smallTextStyle.copyWith(
                color: AppDesignSystem.textSecondary,
              ),
            ),
            const SizedBox(height: AppDesignSystem.spacingXs),
            TextField(
              controller: _labelController,
              autofocus: true,
              style: const TextStyle(color: AppDesignSystem.textPrimary),
              decoration: InputDecoration(
                hintText: 'e.g., Pirouette, Grand Jeté',
                hintStyle: TextStyle(
                  color: AppDesignSystem.textSecondary.withOpacity(0.5),
                ),
                filled: true,
                fillColor: AppDesignSystem.backgroundDark,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppDesignSystem.radiusXs),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppDesignSystem.spacingMd,
                  vertical: AppDesignSystem.spacingMd,
                ),
              ),
              onChanged: (_) => setState(() {}),
              onSubmitted: (_) => _submit(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'Cancel',
            style: AppDesignSystem.tabStyle.copyWith(
              color: AppDesignSystem.textSecondary,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: _isValid ? _submit : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppDesignSystem.accentBlue,
            foregroundColor: AppDesignSystem.backgroundDark,
            disabledBackgroundColor: AppDesignSystem.textDisabled,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDesignSystem.radiusXs),
            ),
          ),
          child: Text(
            widget.existingTimestamp == null ? 'Add' : 'Save',
            style: AppDesignSystem.tabStyle,
          ),
        ),
      ],
    );
  }
}

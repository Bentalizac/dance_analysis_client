import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/video_timestamp.dart';
import '../design_system/theme.dart';

/// Inline form for adding or editing video timestamps with start/end times
/// Appears in the timestamp list instead of as a dialog
class InlineTimestampForm extends StatefulWidget {
  const InlineTimestampForm({
    super.key,
    required this.currentVideoPosition,
    this.existingTimestamp,
    required this.onSave,
    required this.onCancel,
    this.maxDuration,
  });

  /// Current position of the video player (used as default for new timestamps)
  final Duration currentVideoPosition;

  /// If editing, the existing timestamp to pre-populate
  final VideoTimestamp? existingTimestamp;

  /// Callback when user saves the timestamp
  final Function(Duration startTime, Duration endTime, String label) onSave;

  /// Callback when user cancels
  final VoidCallback onCancel;

  /// Maximum duration (video length) for validation
  final Duration? maxDuration;

  @override
  State<InlineTimestampForm> createState() => _InlineTimestampFormState();
}

class _InlineTimestampFormState extends State<InlineTimestampForm> {
  late final TextEditingController _labelController;
  late final TextEditingController _startMinutesController;
  late final TextEditingController _startSecondsController;
  late final TextEditingController _endMinutesController;
  late final TextEditingController _endSecondsController;

  late Duration _startTime;
  late Duration _endTime;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();

    _labelController = TextEditingController(
      text: widget.existingTimestamp?.label ?? '',
    );

    if (widget.existingTimestamp != null) {
      _startTime = widget.existingTimestamp!.startTime;
      _endTime = widget.existingTimestamp!.endTime;
    } else {
      _startTime = widget.currentVideoPosition;
      _endTime = widget.currentVideoPosition + const Duration(seconds: 5);

      if (widget.maxDuration != null && _endTime > widget.maxDuration!) {
        _endTime = widget.maxDuration!;
      }
    }

    _startMinutesController = TextEditingController(
      text: _startTime.inMinutes.toString(),
    );
    _startSecondsController = TextEditingController(
      text: (_startTime.inSeconds % 60).toString().padLeft(2, '0'),
    );
    _endMinutesController = TextEditingController(
      text: _endTime.inMinutes.toString(),
    );
    _endSecondsController = TextEditingController(
      text: (_endTime.inSeconds % 60).toString().padLeft(2, '0'),
    );

    _startMinutesController.addListener(_updateStartTimeFromInputs);
    _startSecondsController.addListener(_updateStartTimeFromInputs);
    _endMinutesController.addListener(_updateEndTimeFromInputs);
    _endSecondsController.addListener(_updateEndTimeFromInputs);
  }

  @override
  void dispose() {
    _labelController.dispose();
    _startMinutesController.dispose();
    _startSecondsController.dispose();
    _endMinutesController.dispose();
    _endSecondsController.dispose();
    super.dispose();
  }

  void _updateStartTimeFromInputs() {
    final minutes = int.tryParse(_startMinutesController.text) ?? 0;
    final seconds = int.tryParse(_startSecondsController.text) ?? 0;
    setState(() {
      _startTime = Duration(minutes: minutes, seconds: seconds);
      _validateTimes();
    });
  }

  void _updateEndTimeFromInputs() {
    final minutes = int.tryParse(_endMinutesController.text) ?? 0;
    final seconds = int.tryParse(_endSecondsController.text) ?? 0;
    setState(() {
      _endTime = Duration(minutes: minutes, seconds: seconds);
      _validateTimes();
    });
  }

  void _validateTimes() {
    if (_endTime <= _startTime) {
      _errorMessage = 'End time must be after start time';
    } else if (widget.maxDuration != null && _endTime > widget.maxDuration!) {
      _errorMessage = 'End time exceeds video duration';
    } else if (_startTime < Duration.zero) {
      _errorMessage = 'Start time must be positive';
    } else {
      _errorMessage = null;
    }
  }

  bool get _isValid =>
      _labelController.text.trim().isNotEmpty && _errorMessage == null;

  void _handleSave() {
    if (!_isValid) return;
    widget.onSave(_startTime, _endTime, _labelController.text.trim());
  }

  void _setStartToCurrentPosition() {
    final currentPos = widget.currentVideoPosition;
    setState(() {
      _startTime = currentPos;
      _startMinutesController.text = currentPos.inMinutes.toString();
      _startSecondsController.text =
          (currentPos.inSeconds % 60).toString().padLeft(2, '0');
      _validateTimes();
    });
  }

  void _setEndToCurrentPosition() {
    final currentPos = widget.currentVideoPosition;
    setState(() {
      _endTime = currentPos;
      _endMinutesController.text = currentPos.inMinutes.toString();
      _endSecondsController.text =
          (currentPos.inSeconds % 60).toString().padLeft(2, '0');
      _validateTimes();
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppDesignSystem.spacingMd,
        vertical: AppDesignSystem.spacingSm,
      ),
      padding: const EdgeInsets.all(AppDesignSystem.spacingMd),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppDesignSystem.radiusXs),
        border: Border.all(
          color: colorScheme.primary.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Row(
            children: [
              Icon(
                widget.existingTimestamp == null
                    ? Icons.add_circle_outline
                    : Icons.edit_outlined,
                color: colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: AppDesignSystem.spacingSm),
              Text(
                widget.existingTimestamp == null
                    ? 'Add Timestamp'
                    : 'Edit Timestamp',
                style: textTheme.labelLarge?.copyWith(fontSize: 16),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: widget.onCancel,
                color: colorScheme.onSurfaceVariant,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
            ],
          ),
          const SizedBox(height: AppDesignSystem.spacingMd),

          // Start and End Time on same line
          Row(
            children: [
              Expanded(
                child: _buildTimeInput(
                  context,
                  label: 'Start Time',
                  minutesController: _startMinutesController,
                  secondsController: _startSecondsController,
                  onSetToCurrent: _setStartToCurrentPosition,
                ),
              ),
              const SizedBox(width: AppDesignSystem.spacingMd),
              Expanded(
                child: _buildTimeInput(
                  context,
                  label: 'End Time',
                  minutesController: _endMinutesController,
                  secondsController: _endSecondsController,
                  onSetToCurrent: _setEndToCurrentPosition,
                ),
              ),
            ],
          ),

          // Error message
          if (_errorMessage != null) ...[
            const SizedBox(height: AppDesignSystem.spacingSm),
            Container(
              padding: const EdgeInsets.all(AppDesignSystem.spacingSm),
              decoration: BoxDecoration(
                color: colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(AppDesignSystem.radiusXs),
                border: Border.all(
                  color: colorScheme.error.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.error_outline,
                    color: colorScheme.error,
                    size: 16,
                  ),
                  const SizedBox(width: AppDesignSystem.spacingSm),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.error,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: AppDesignSystem.spacingMd),

          // Step name input
          Text(
            'Dance Step Name',
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppDesignSystem.spacingXs),
          TextField(
            controller: _labelController,
            autofocus: widget.existingTimestamp == null,
            decoration: const InputDecoration(
              hintText: 'e.g., Pirouette, Grand Jeté',
            ),
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => _handleSave(),
          ),
          const SizedBox(height: AppDesignSystem.spacingMd),

          // Action buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: widget.onCancel,
                child: Text(
                  'Cancel',
                  style: textTheme.labelLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(width: AppDesignSystem.spacingSm),
              ElevatedButton(
                onPressed: _isValid ? _handleSave : null,
                child: Text(
                  widget.existingTimestamp == null ? 'Add' : 'Save',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimeInput(
    BuildContext context, {
    required String label,
    required TextEditingController minutesController,
    required TextEditingController secondsController,
    required VoidCallback onSetToCurrent,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppDesignSystem.spacingXs),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 50,
              child: TextField(
                controller: minutesController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium,
                decoration: const InputDecoration(hintText: '0'),
              ),
            ),
            const SizedBox(width: AppDesignSystem.spacingXs),
            Text(':', style: textTheme.titleMedium),
            const SizedBox(width: AppDesignSystem.spacingXs),
            SizedBox(
              width: 50,
              child: TextField(
                controller: secondsController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  _MaxValueInputFormatter(59),
                ],
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium,
                decoration: const InputDecoration(hintText: '00'),
              ),
            ),
            const SizedBox(width: AppDesignSystem.spacingSm),
            TextButton.icon(
              onPressed: onSetToCurrent,
              icon: const Icon(Icons.access_time, size: 14),
              label: const Text('Now'),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDesignSystem.spacingSm,
                  vertical: AppDesignSystem.spacingXs,
                ),
                textStyle: const TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Input formatter to restrict values to a maximum
class _MaxValueInputFormatter extends TextInputFormatter {
  _MaxValueInputFormatter(this.maxValue);

  final int maxValue;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    final value = int.tryParse(newValue.text);
    if (value == null || value > maxValue) {
      return oldValue;
    }

    return newValue;
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/video_timestamp.dart';
import '../design_system.dart';

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

    // Initialize label
    _labelController = TextEditingController(
      text: widget.existingTimestamp?.label ?? '',
    );

    // Initialize times
    if (widget.existingTimestamp != null) {
      _startTime = widget.existingTimestamp!.startTime;
      _endTime = widget.existingTimestamp!.endTime;
    } else {
      // For new timestamps, start at current position, end 5 seconds later
      _startTime = widget.currentVideoPosition;
      _endTime = widget.currentVideoPosition + const Duration(seconds: 5);

      // Ensure end time doesn't exceed video duration
      if (widget.maxDuration != null && _endTime > widget.maxDuration!) {
        _endTime = widget.maxDuration!;
      }
    }

    // Initialize time input controllers
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

    // Add listeners to update Duration when text changes
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
      _startSecondsController.text = (currentPos.inSeconds % 60)
          .toString()
          .padLeft(2, '0');
      _validateTimes();
    });
  }

  void _setEndToCurrentPosition() {
    final currentPos = widget.currentVideoPosition;
    setState(() {
      _endTime = currentPos;
      _endMinutesController.text = currentPos.inMinutes.toString();
      _endSecondsController.text = (currentPos.inSeconds % 60)
          .toString()
          .padLeft(2, '0');
      _validateTimes();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppDesignSystem.spacingMd,
        vertical: AppDesignSystem.spacingSm,
      ),
      padding: const EdgeInsets.all(AppDesignSystem.spacingMd),
      decoration: BoxDecoration(
        color: AppDesignSystem.backgroundDark,
        borderRadius: BorderRadius.circular(AppDesignSystem.radiusXs),
        border: Border.all(
          color: AppDesignSystem.accentBlue.withOpacity(0.3),
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
                color: AppDesignSystem.accentBlue,
                size: 20,
              ),
              const SizedBox(width: AppDesignSystem.spacingSm),
              Text(
                widget.existingTimestamp == null
                    ? 'Add Timestamp'
                    : 'Edit Timestamp',
                style: AppDesignSystem.tabStyle.copyWith(
                  color: AppDesignSystem.textPrimary,
                  fontSize: 16,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: widget.onCancel,
                color: AppDesignSystem.textSecondary,
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
                  label: 'Start Time',
                  minutesController: _startMinutesController,
                  secondsController: _startSecondsController,
                  onSetToCurrent: _setStartToCurrentPosition,
                ),
              ),
              const SizedBox(width: AppDesignSystem.spacingMd),
              Expanded(
                child: _buildTimeInput(
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
                color: AppDesignSystem.errorRed.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppDesignSystem.radiusXs),
                border: Border.all(
                  color: AppDesignSystem.errorRed.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: AppDesignSystem.errorRed,
                    size: 16,
                  ),
                  const SizedBox(width: AppDesignSystem.spacingSm),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: AppDesignSystem.smallTextStyle.copyWith(
                        color: AppDesignSystem.errorRed,
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
            style: AppDesignSystem.smallTextStyle.copyWith(
              color: AppDesignSystem.textSecondary,
            ),
          ),
          const SizedBox(height: AppDesignSystem.spacingXs),
          TextField(
            controller: _labelController,
            autofocus: widget.existingTimestamp == null,
            style: const TextStyle(color: AppDesignSystem.textPrimary),
            decoration: InputDecoration(
              hintText: 'e.g., Pirouette, Grand Jeté',
              hintStyle: TextStyle(
                color: AppDesignSystem.textSecondary.withOpacity(0.5),
              ),
              filled: true,
              fillColor: AppDesignSystem.backgroundMedium,
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
                  style: AppDesignSystem.tabStyle.copyWith(
                    color: AppDesignSystem.textSecondary,
                  ),
                ),
              ),
              const SizedBox(width: AppDesignSystem.spacingSm),
              ElevatedButton(
                onPressed: _isValid ? _handleSave : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppDesignSystem.accentBlue,
                  foregroundColor: AppDesignSystem.backgroundDark,
                  disabledBackgroundColor: AppDesignSystem.textDisabled,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      AppDesignSystem.radiusXs,
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDesignSystem.spacingLg,
                    vertical: AppDesignSystem.spacingMd,
                  ),
                ),
                child: Text(
                  widget.existingTimestamp == null ? 'Add' : 'Save',
                  style: AppDesignSystem.tabStyle,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimeInput({
    required String label,
    required TextEditingController minutesController,
    required TextEditingController secondsController,
    required VoidCallback onSetToCurrent,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppDesignSystem.smallTextStyle.copyWith(
            color: AppDesignSystem.textSecondary,
          ),
        ),
        const SizedBox(height: AppDesignSystem.spacingXs),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Minutes input
            SizedBox(
              width: 50,
              child: TextField(
                controller: minutesController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppDesignSystem.textPrimary,
                  fontSize: 14,
                ),
                decoration: InputDecoration(
                  hintText: '0',
                  hintStyle: TextStyle(
                    color: AppDesignSystem.textSecondary.withOpacity(0.5),
                  ),
                  filled: true,
                  fillColor: AppDesignSystem.backgroundMedium,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(
                      AppDesignSystem.radiusXs,
                    ),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppDesignSystem.spacingXs,
                    vertical: AppDesignSystem.spacingSm,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppDesignSystem.spacingXs),
            Text(
              ':',
              style: AppDesignSystem.timestampStyle.copyWith(
                color: AppDesignSystem.textPrimary,
              ),
            ),
            const SizedBox(width: AppDesignSystem.spacingXs),
            // Seconds input
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
                style: const TextStyle(
                  color: AppDesignSystem.textPrimary,
                  fontSize: 14,
                ),
                decoration: InputDecoration(
                  hintText: '00',
                  hintStyle: TextStyle(
                    color: AppDesignSystem.textSecondary.withOpacity(0.5),
                  ),
                  filled: true,
                  fillColor: AppDesignSystem.backgroundMedium,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(
                      AppDesignSystem.radiusXs,
                    ),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppDesignSystem.spacingXs,
                    vertical: AppDesignSystem.spacingSm,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppDesignSystem.spacingSm),
            // Use Current button
            TextButton.icon(
              onPressed: onSetToCurrent,
              icon: const Icon(Icons.access_time, size: 14),
              label: const Text('Now'),
              style: TextButton.styleFrom(
                foregroundColor: AppDesignSystem.accentBlue,
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

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../generated/api/models/dance_response.dart';
import '../../../../shared/design_system/theme.dart';
import '../../../../shared/widgets/dance_style_dropdown.dart';
import '../../../dances/presentation/controllers/dances_controller.dart';
import '../../../dances/presentation/controllers/dances_state.dart';

/// Dialog for creating a new routine within a group.
class CreateRoutineDialog extends StatefulWidget {
  const CreateRoutineDialog({super.key, required this.onSubmit});

  /// Called with (title, danceId). Returns true on success.
  final Future<bool> Function(String title, String danceId) onSubmit;

  @override
  State<CreateRoutineDialog> createState() => _CreateRoutineDialogState();
}

class _CreateRoutineDialogState extends State<CreateRoutineDialog> {
  final _titleController = TextEditingController();
  DanceResponse? _selectedDance;
  bool _isSubmitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DancesController>().loadDances();
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      setState(() => _error = 'Routine title is required.');
      return;
    }
    if (_selectedDance == null) {
      setState(() => _error = 'Please select a dance style.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    final success = await widget.onSubmit(title, _selectedDance!.id);

    if (!mounted) return;

    if (success) {
      Navigator.of(context).pop();
    } else {
      setState(() {
        _isSubmitting = false;
        _error = 'Failed to create routine.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return AlertDialog(
      title: const Text('Create Routine'),
      content: Consumer<DancesController>(
        builder: (context, dances, _) {
          final dancesState = dances.state;

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _titleController,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  hintText: 'e.g. Waltz Competition Routine',
                ),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: AppDesignSystem.spacingMd),
              if (dancesState.status == DancesStatus.initial ||
                  dancesState.status == DancesStatus.loading)
                const LinearProgressIndicator()
              else if (dancesState.status == DancesStatus.error)
                Text(
                  dancesState.errorMessage ?? 'Failed to load dance styles.',
                  style: textTheme.bodySmall?.copyWith(color: colorScheme.error),
                )
              else
                DanceStyleDropdown(
                  dances: dancesState.dances,
                  value: _selectedDance,
                  onChanged: (v) => setState(() => _selectedDance = v),
                ),
              if (_error != null) ...[
                const SizedBox(height: AppDesignSystem.spacingSm),
                Text(
                  _error!,
                  style: textTheme.bodySmall?.copyWith(color: colorScheme.error),
                ),
              ],
            ],
          );
        },
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
          child: Text(
            'Cancel',
            style: textTheme.labelLarge?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _submit,
          child: _isSubmitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Create'),
        ),
      ],
    );
  }
}

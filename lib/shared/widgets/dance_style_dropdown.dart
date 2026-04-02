import 'package:flutter/material.dart';

import '../../generated/api/models/dance_response.dart';
import '../extensions/dance_style_extensions.dart';

/// A [DropdownButtonFormField] that groups [DanceResponse] items by category
/// (Standard, Latin, American Smooth, American Rhythm).
class DanceStyleDropdown extends StatelessWidget {
  const DanceStyleDropdown({
    super.key,
    required this.dances,
    required this.value,
    required this.onChanged,
  });

  final List<DanceResponse> dances;
  final DanceResponse? value;
  final ValueChanged<DanceResponse?> onChanged;

  List<DropdownMenuItem<DanceResponse>> _buildItems(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    // Group dances by category, preserving enum order.
    final grouped = <DanceCategory, List<DanceResponse>>{};
    for (final dance in dances) {
      grouped.putIfAbsent(dance.style.category, () => []).add(dance);
    }

    final items = <DropdownMenuItem<DanceResponse>>[];
    for (final category in DanceCategory.values) {
      final categoryDances = grouped[category];
      if (categoryDances == null || categoryDances.isEmpty) continue;

      // Section header — disabled so it cannot be selected.
      items.add(
        DropdownMenuItem<DanceResponse>(
          enabled: false,
          child: Text(
            category.displayName,
            style: textTheme.labelSmall?.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
            ),
          ),
        ),
      );

      for (final dance in categoryDances) {
        items.add(
          DropdownMenuItem<DanceResponse>(
            value: dance,
            child: Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Text(dance.style.displayName),
            ),
          ),
        );
      }
    }
    return items;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DropdownButtonFormField<DanceResponse>(
      initialValue: value,
      decoration: const InputDecoration(labelText: 'Dance Style'),
      dropdownColor: colorScheme.surface,
      items: _buildItems(context),
      onChanged: onChanged,
    );
  }
}

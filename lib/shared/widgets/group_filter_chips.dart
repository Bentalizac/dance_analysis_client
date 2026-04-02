import 'package:flutter/material.dart';

/// Horizontal scrollable row of choice chips for filtering by group.
class GroupFilterChips extends StatelessWidget {
  const GroupFilterChips({
    super.key,
    required this.groups,
    required this.selectedIndex,
    this.onSelected,
  });

  final List<String> groups;
  final int selectedIndex;
  final ValueChanged<int>? onSelected;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(groups.length, (index) {
          final selected = index == selectedIndex;
          return Padding(
            padding: EdgeInsets.only(right: index == groups.length - 1 ? 0 : 8),
            child: ChoiceChip(
              label: Text(groups[index]),
              selected: selected,
              onSelected: (_) => onSelected?.call(index),
              labelStyle: TextStyle(
                color: selected ? colorScheme.onPrimary : colorScheme.onSurface,
                fontWeight: FontWeight.w500,
              ),
              selectedColor: colorScheme.primary,
              backgroundColor: colorScheme.surfaceContainerHighest,
              side: BorderSide(color: colorScheme.outlineVariant),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          );
        }),
      ),
    );
  }
}

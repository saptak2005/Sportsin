import 'package:flutter/material.dart';

/// A reusable multi-selection chip component
class MultiSelectChipField extends StatelessWidget {
  final List<String> options;
  final List<String> selectedValues;
  final ValueChanged<List<String>> onSelectionChanged;
  final Color? selectedColor;
  final Color? checkmarkColor;
  final bool allowMultiple;
  final bool useToStringForLabel;

  const MultiSelectChipField({
    super.key,
    required this.options,
    required this.selectedValues,
    required this.onSelectionChanged,
    this.selectedColor,
    this.checkmarkColor,
    this.allowMultiple = true,
    this.useToStringForLabel = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: Theme.of(context).colorScheme.outline,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((option) {
            final label = useToStringForLabel
                ? option.toString().split('.').last
                : option;
            final isSelected = selectedValues.contains(option);
            return FilterChip(
              label: Text(label),
              selected: isSelected,
              onSelected: (selected) {
                if (allowMultiple) {
                  final newSelection = List<String>.from(selectedValues);
                  if (selected) {
                    newSelection.add(option);
                  } else {
                    newSelection.remove(option);
                  }
                  onSelectionChanged(newSelection);
                } else {
                  onSelectionChanged(selected ? [option] : []);
                }
              },
              selectedColor: selectedColor ??
                  Theme.of(context).colorScheme.primaryContainer,
              checkmarkColor:
                  checkmarkColor ?? Theme.of(context).colorScheme.primary,
            );
          }).toList(),
        ),
      ),
    );
  }
}

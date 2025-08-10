import 'package:flutter/material.dart';
import 'package:sportsin/config/theme/app_colors.dart';

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
        color: AppColors.darkSurface,
        border: Border.all(
          color: const Color(0xFF30363D),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((option) {
            final label = useToStringForLabel
                ? option.toString().split('.').last
                : option;
            final isSelected = selectedValues.contains(option);
            return FilterChip(
              label: Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.white,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  fontSize: 14,
                ),
              ),
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
              backgroundColor: Colors.grey[900],
              selectedColor: selectedColor ?? AppColors.linkedInBlue,
              checkmarkColor: checkmarkColor ?? Colors.white,
              side: BorderSide(
                color: isSelected 
                    ? AppColors.linkedInBlue 
                    : const Color(0xFF30363D),
                width: 1,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

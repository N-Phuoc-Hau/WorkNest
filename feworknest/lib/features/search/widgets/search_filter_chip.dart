import 'package:flutter/material.dart';

class SearchFilterChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool isSelected;

  const SearchFilterChip({
    super.key,
    required this.label,
    required this.onTap,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onTap(),
      selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
      checkmarkColor: Theme.of(context).primaryColor,
      labelStyle: TextStyle(
        color: isSelected ? Theme.of(context).primaryColor : Colors.black87,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      backgroundColor: Colors.grey[200],
      elevation: 1,
      pressElevation: 2,
    );
  }
} 
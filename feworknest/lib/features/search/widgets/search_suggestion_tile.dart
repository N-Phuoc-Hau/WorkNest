import 'package:flutter/material.dart';

class SearchSuggestionTile extends StatelessWidget {
  final String suggestion;
  final VoidCallback onTap;

  const SearchSuggestionTile({
    super.key,
    required this.suggestion,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const Icon(Icons.search, color: Colors.grey),
        title: Text(
          suggestion,
          style: const TextStyle(fontSize: 16),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
} 
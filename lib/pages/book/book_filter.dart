import 'package:flutter/material.dart';

class BookFilter extends StatelessWidget {
  final List<String> filters;
  final String selectedFilter;
  final ValueChanged<String> onFilterChanged;

  const BookFilter({
    super.key,
    required this.filters,
    required this.selectedFilter,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Filtrer par catégorie',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: filters.map((filter) {
              final isSelected = filter == selectedFilter;
              return FilterChip(
                label: Text(filter),
                selected: isSelected,
                onSelected: (selected) {
                  Navigator.pop(context);
                  onFilterChanged(filter);
                },
                backgroundColor: Colors.grey[100],
                selectedColor: const Color(0xFF1976D2).withOpacity(0.2),
                labelStyle: TextStyle(
                  color: isSelected ? const Color(0xFF1976D2) : Colors.grey[700],
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(
                    color: isSelected ? const Color(0xFF1976D2) : Colors.grey[300]!,
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
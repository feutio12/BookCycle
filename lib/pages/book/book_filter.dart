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
    return SingleChildScrollView(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 60,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Padding(
              padding: EdgeInsets.only(left: 8),
              child: Text(
                'Filtrer par catégorie',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1976D2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: filters.map((filter) {
                final isSelected = filter == selectedFilter;
                return FilterChip(
                  label: Text(
                    filter,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: isSelected ? Colors.white : const Color(0xFF1976D2),
                    ),
                  ),
                  selected: isSelected,
                  onSelected: (selected) {
                    Navigator.pop(context);
                    onFilterChanged(filter);
                  },
                  backgroundColor: Colors.grey[50],
                  selectedColor: const Color(0xFF1976D2),
                  checkmarkColor: Colors.white,
                  showCheckmark: true,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: isSelected ? const Color(0xFF1976D2) : Colors.grey[300]!,
                      width: isSelected ? 0 : 1,
                    ),
                  ),
                  elevation: isSelected ? 2 : 0,
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[100],
                  foregroundColor: Colors.grey[700],
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: const Text(
                  'Fermer',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
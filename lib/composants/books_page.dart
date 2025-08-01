import 'package:flutter/material.dart';
import 'book_card.dart';

class BooksPage extends StatelessWidget {
  final List<Map<String, dynamic>> books;
  final Function(String) onLikePressed;
  final String selectedFilter;
  final Function(String) onFilterChanged;
  final List<String> filters;
  final ColorScheme colorScheme;
  final TextTheme textTheme;

  const BooksPage({
    super.key,
    required this.books,
    required this.onLikePressed,
    required this.selectedFilter,
    required this.onFilterChanged,
    required this.filters,
    required this.colorScheme,
    required this.textTheme,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // En-tête avec titre et filtres
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Découvrez des livres',
                  style: textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: filters.map((filter) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: FilterChip(
                          label: Text(filter),
                          selected: selectedFilter == filter,
                          onSelected: (bool selected) {
                            onFilterChanged(filter);
                          },
                          selectedColor: colorScheme.primaryContainer,
                          checkmarkColor: colorScheme.onPrimaryContainer,
                          labelStyle: TextStyle(
                            color: selectedFilter == filter
                                ? colorScheme.onPrimaryContainer
                                : null,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Affichage du nombre de résultats
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '${books.length} livre${books.length > 1 ? 's' : ''} trouvé${books.length > 1 ? 's' : ''}',
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),

        // Liste des livres
        Expanded(
          child: books.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: books.length,
            itemBuilder: (context, index) {
              final book = books[index];
              return BookCard(
                book: book,
                colorScheme: colorScheme,
                textTheme: textTheme,
                onLikePressed: onLikePressed,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.book_outlined,
            size: 48,
            color: colorScheme.onSurface.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'Aucun livre trouvé',
            style: textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => onFilterChanged('Tous'),
            child: const Text('Réinitialiser les filtres'),
          ),
        ],
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:bookcycle/pages/book/books_page.dart';

class Header extends StatelessWidget {
  final String name;

  const Header({super.key, required this.name});

  String _getWelcomeMessage() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Une belle journée de lecture commence!';
    } else if (hour < 18) {
      return 'Profitez de votre après-midi littéraire!';
    } else {
      return 'Bonne soirée de découvertes livresques!';
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1976D2),
              Color(0xFF42A5F5),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.only(left: 20, top: 70, right: 20, bottom: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Bienvenue${name.isNotEmpty ? ', $name' : ''}',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _getWelcomeMessage(),
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class BookList extends StatelessWidget {
  final List<Map<String, dynamic>> books;
  final Function(String) onLikePressed;
  final Function(Map<String, dynamic>) onBookPressed;
  final String selectedFilter;
  final Function(String) onFilterChanged;
  final List<String> filters;
  final ColorScheme colorScheme;
  final TextTheme textTheme;
  final String currentUserId;
  final bool isLoading;
  final ScrollController scrollController;
  final Function(String) onDeleteBook;
  final Function(Map<String, dynamic>) onEditBook;
  final Function(String, String, String) onContactPublisher; // Nouveau callback

  const BookList({
    super.key,
    required this.books,
    required this.onLikePressed,
    required this.onBookPressed,
    required this.selectedFilter,
    required this.onFilterChanged,
    required this.filters,
    required this.colorScheme,
    required this.textTheme,
    required this.currentUserId,
    required this.isLoading,
    required this.scrollController,
    required this.onDeleteBook,
    required this.onEditBook,
    required this.onContactPublisher, // Nouveau paramètre
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return _buildLoadingIndicator();
    }

    if (books.isEmpty) {
      return _buildEmptyState(selectedFilter);
    }

    return BooksPage(
      books: books,
      onLikePressed: onLikePressed,
      onBookPressed: onBookPressed,
      selectedFilter: selectedFilter,
      onFilterChanged: onFilterChanged,
      filters: filters,
      colorScheme: colorScheme,
      textTheme: textTheme,
      currentUserId: currentUserId,
      onDeleteBook: onDeleteBook,
      onEditBook: onEditBook,
      onContactPublisher: onContactPublisher, // Passez le nouveau callback
    );
  }

  Widget _buildLoadingIndicator() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1976D2)),
            strokeWidth: 4,
          ),
          const SizedBox(height: 16),
          Text(
            'Chargement des livres...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String selectedFilter) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(24),
        margin: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.menu_book,
              size: 80,
              color: const Color(0xFF1976D2).withOpacity(0.5),
            ),
            const SizedBox(height: 20),
            const Text(
              'Aucun livre trouvé',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1976D2),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              selectedFilter == 'Tous'
                  ? 'Soyez le premier à ajouter un livre!'
                  : 'Aucun livre dans la catégorie "$selectedFilter"',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF757575),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onFilterPressed;

  const SearchBar({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.onFilterPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: controller,
                onChanged: onChanged,
                decoration: InputDecoration(
                  hintText: 'Rechercher un livre ou un auteur...',
                  hintStyle: TextStyle(color: Colors.grey[600]),
                  prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1976D2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.filter_list, color: Colors.white),
              onPressed: onFilterPressed,
            ),
          ),
        ],
      ),
    );
  }
}
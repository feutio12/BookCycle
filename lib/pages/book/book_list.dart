import 'package:flutter/material.dart';
import 'package:bookcycle/composants/books_page.dart';

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
    return Container(
      padding: const EdgeInsets.only(left: 24, top: 70, right: 24, bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bienvenue${name.isNotEmpty ? ', $name' : ''}',
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _getWelcomeMessage(),
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
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
    );
  }

  Widget _buildLoadingIndicator() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 60,
            height: 60,
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(const Color(0xFF1976D2).withOpacity(0.8)),
              strokeWidth: 4,
              backgroundColor: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Chargement des livres...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String selectedFilter) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(28),
        margin: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withOpacity(0.1),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: const Color(0xFF1976D2).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.menu_book_rounded,
                size: 50,
                color: const Color(0xFF1976D2).withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Aucun livre trouvé',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1976D2),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              selectedFilter == 'Tous'
                  ? 'Soyez le premier à ajouter un livre!'
                  : 'Aucun livre dans la catégorie "$selectedFilter"',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF757575),
                height: 1.5,
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
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: controller,
                onChanged: onChanged,
                decoration: InputDecoration(
                  hintText: 'Rechercher un livre ou un auteur...',
                  hintStyle: TextStyle(color: Colors.grey[600], fontSize: 15),
                  prefixIcon: Icon(Icons.search_rounded, color: Colors.grey[600]),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                ),
                style: const TextStyle(fontSize: 15),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF1976D2),
                  Color(0xFF42A5F5),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1976D2).withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(Icons.filter_list_rounded, color: Colors.white, size: 24),
              onPressed: onFilterPressed,
            ),
          ),
        ],
      ),
    );
  }
}
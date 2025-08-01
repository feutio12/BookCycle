import 'package:bookcycle/pages/book_detail_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:bookcycle/composants/books_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Liste complète de livres simulée
  final List<Map<String, dynamic>> _allBooks = [
    {
      'id': '1',
      'title': 'Le Petit Prince',
      'author': 'Antoine de Saint-Exupéry',
      'image': 'assets/images/book1.jpg',
      'likes': 124,
      'isLiked': false,
      'description': 'Un conte poétique et philosophique pour enfants et adultes.',
      'category': 'Classique',
      'rating': 4.8,
      'isPopular': true,
      'isRecent': false,
    },
    {
      'id': '2',
      'title': '1984',
      'author': 'George Orwell',
      'image': 'assets/images/book2.jpg',
      'likes': 89,
      'isLiked': true,
      'description': 'Une dystopie sur les dangers du totalitarisme.',
      'category': 'Science-fiction',
      'rating': 4.7,
      'isPopular': true,
      'isRecent': false,
    },
    {
      'id': '3',
      'title': 'L\'Étranger',
      'author': 'Albert Camus',
      'image': 'assets/images/book3.jpg',
      'likes': 76,
      'isLiked': false,
      'description': 'Un roman existentialiste sur l\'absurdité de la condition humaine.',
      'category': 'Philosophie',
      'rating': 4.5,
      'isPopular': false,
      'isRecent': true,
    },
    {
      'id': '4',
      'title': 'Harry Potter à l\'école des sorciers',
      'author': 'J.K. Rowling',
      'image': 'assets/images/book4.png',
      'likes': 215,
      'isLiked': false,
      'description': 'Le premier tome de la saga fantastique culte.',
      'category': 'Fantasy',
      'rating': 4.9,
      'isPopular': true,
      'isRecent': true,
    },
    {
      'id': '5',
      'title': 'Orgueil et Préjugés',
      'author': 'Jane Austen',
      'image': 'assets/images/book5.jpg',
      'likes': 142,
      'isLiked': false,
      'description': 'Un classique de la romance anglaise du XIXe siècle.',
      'category': 'Romance',
      'rating': 4.6,
      'isPopular': true,
      'isRecent': false,
    },
    {
      'id': '6',
      'title': 'Dune',
      'author': 'Frank Herbert',
      'image': 'assets/images/book6.png',
      'likes': 388,
      'isLiked': false,
      'description': 'Une épopée de science-fiction dans un univers complexe.',
      'category': 'Science-fiction',
      'rating': 4.7,
      'isPopular': false,
      'isRecent': true,
    },
  ];

  // Variables pour le filtrage
  List<Map<String, dynamic>> _filteredBooks = [];
  String _selectedFilter = 'Tous';
  final List<String> _filters = [
    'Tous',
    'Populaires',
    'Récents',
    'Science-fiction',
    'Romance',
    'Fantasy',
    'Classique',
    'Philosophie',
    'Littérature'
  ];

  @override
  void initState() {
    super.initState();
    _filteredBooks = _allBooks;
  }

  // Fonction pour filtrer les livres
  void _filterBooks(String filter) {
    setState(() {
      _selectedFilter = filter;

      switch (filter) {
        case 'Tous':
          _filteredBooks = _allBooks;
          break;
        case 'Populaires':
          _filteredBooks = _allBooks.where((book) => book['isPopular']).toList();
          break;
        case 'Récents':
          _filteredBooks = _allBooks.where((book) => book['isRecent']).toList();
          break;
        default:
          _filteredBooks = _allBooks.where((book) => book['category'] == filter).toList();
      }
    });
  }

  // Fonction pour liker/unliker un livre
  void _toggleLike(String bookId) {
    setState(() {
      final bookIndex = _allBooks.indexWhere((book) => book['id'] == bookId);
      if (bookIndex != -1) {
        _allBooks[bookIndex]['isLiked'] = !_allBooks[bookIndex]['isLiked'];
        _allBooks[bookIndex]['likes'] += _allBooks[bookIndex]['isLiked'] ? 1 : -1;

        // Mettre à jour la liste filtrée
        _filterBooks(_selectedFilter);

        // Afficher un feedback
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _allBooks[bookIndex]['isLiked']
                  ? 'Ajouté à vos favoris'
                  : 'Retiré de vos favoris',
            ),
            duration: const Duration(seconds: 1),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('BookCycle'),
      ),
      body: BooksPage(
        books: _filteredBooks,
        onLikePressed: _toggleLike,
        selectedFilter: _selectedFilter,
        onFilterChanged: _filterBooks,
        filters: _filters,
        colorScheme: colorScheme,
        textTheme: textTheme,
      ),
    );
  }
}
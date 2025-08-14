import 'package:bookcycle/composants/books_page.dart';
import 'package:bookcycle/pages/auth/loginpage.dart';
import 'package:bookcycle/pages/book/add_book_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Acceuilpage extends StatefulWidget {
  const Acceuilpage({super.key});

  @override
  State<Acceuilpage> createState() => _AcceuilpageState();
}

class _AcceuilpageState extends State<Acceuilpage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  static const List<String> _filters = [
    'Tous',
    'Populaires',
    'Récents',
    'Science-fiction',
    'Romance',
    'Fantasy',
    'Classique',
    'Philosophie',
    'Littérature',
  ];

  List<Map<String, dynamic>> _allBooks = [];
  List<Map<String, dynamic>> _filteredBooks = [];
  String _selectedFilter = 'Tous';
  bool _isLoading = true;
  bool _hasPostedAsGuest = false;

  @override
  void initState() {
    super.initState();
    _checkGuestPostingStatus();
    _fetchBooks();
  }

  Future<void> _checkGuestPostingStatus() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _hasPostedAsGuest = prefs.getBool('hasPostedAsGuest') ?? false;
    });
  }

  Future<void> _fetchBooks() async {
    try {
      final snapshot = await _firestore.collection('books').get();
      final books = snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'title': data['title'] ?? '',
          'author': data['author'] ?? '',
          'imageUrl': data['imageUrl'] ?? '',
          'description': data['description'] ?? '',
          'category': data['category'] ?? '',
          'price': data['price'] ?? 0,
          'pages': data['pages'] ?? 0,
          'likes': data['likes'] ?? 0,
          'rating': data['rating'] ?? 0.0,
          'isPopular': data['isPopular'] ?? false,
          'createdAt': data['createdAt']?.toDate() ?? DateTime.now(),
          'isLiked': false,
          'isGuestBook': data['userId'] == null,
          'userId': data['userId'] ?? '',
        };
      }).toList();

      if (mounted) {
        setState(() {
          _allBooks = books;
          _filterBooks(_selectedFilter);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Erreur de chargement: $e');
        setState(() => _isLoading = false);
      }
    }
  }

  void _filterBooks(String filter) {
    setState(() {
      _selectedFilter = filter;
      _filteredBooks = _applyFilter(_allBooks, filter);
    });
  }

  List<Map<String, dynamic>> _applyFilter(List<Map<String, dynamic>> books, String filter) {
    switch (filter) {
      case 'Populaires':
        return books.where((book) => book['isPopular'] as bool).toList();
      case 'Récents':
        return books.where((book) {
          final createdAt = book['createdAt'] as DateTime;
          return createdAt.isAfter(DateTime.now().subtract(const Duration(days: 30)));
        }).toList();
      case 'Tous':
        return List.from(books);
      default:
        return books.where((book) => book['category'] == filter).toList();
    }
  }

  Future<void> _toggleLike(String bookId) async {
    try {
      final bookIndex = _allBooks.indexWhere((book) => book['id'] == bookId);
      if (bookIndex == -1) return;

      final isLiked = !(_allBooks[bookIndex]['isLiked'] as bool);
      final newLikes = (_allBooks[bookIndex]['likes'] as int) + (isLiked ? 1 : -1);

      await _firestore.collection('books').doc(bookId).update({'likes': newLikes});

      if (mounted) {
        setState(() {
          _allBooks[bookIndex]['isLiked'] = isLiked;
          _allBooks[bookIndex]['likes'] = newLikes;
          _filterBooks(_selectedFilter);
        });
        _showSuccessSnackBar(isLiked ? 'Ajouté à vos favoris' : 'Retiré de vos favoris');
      }
    } catch (e) {
      if (mounted) _showErrorSnackBar('Erreur: $e');
    }
  }

  Future<void> _navigateToAddBook() async {
    final user = _auth.currentUser;
    final isGuest = user == null;

    // Vérification pour les invités
    if (isGuest) {
      final prefs = await SharedPreferences.getInstance();
      final hasPosted = prefs.getBool('hasPostedAsGuest') ?? false;

      if (hasPosted) {
        _showGuestLimitSnackBar();
        return;
      }

      final guestBooks = _allBooks.where((book) => book['isGuestBook'] == true).length;
      if (guestBooks >= 1) {
        await prefs.setBool('hasPostedAsGuest', true);
        _showGuestLimitSnackBar();
        return;
      }
    }

    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => AddBookPage(isGuest: isGuest),
      ),
    );

    if (result == true && mounted) {
      await _fetchBooks();
      if (isGuest) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('hasPostedAsGuest', true);
      }
    }
  }

  void _navigateToLogin() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _showGuestLimitSnackBar() {
    final scaffold = ScaffoldMessenger.of(context);
    scaffold.showSnackBar(
      SnackBar(
        content: const Text('Limite atteinte. Connectez-vous pour publier plus de livres'),
        action: SnackBarAction(
          label: 'Se connecter',
          onPressed: () {
            scaffold.hideCurrentSnackBar();
            _navigateToLogin();
          },
        ),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _showLoginRequiredSnackBar() {
    final scaffold = ScaffoldMessenger.of(context);
    scaffold.showSnackBar(
      SnackBar(
        content: const Text('Connectez-vous pour publier des livres'),
        action: SnackBarAction(
          label: 'Se connecter',
          onPressed: () {
            scaffold.hideCurrentSnackBar();
            _navigateToLogin();
          },
        ),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    return Scaffold(
      appBar: AppBar(
        title: Text('Bienvenue ${user?.displayName ?? ''}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _navigateToAddBook,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchBooks,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : BooksPage(
        books: _filteredBooks,
        onLikePressed: _toggleLike,
        selectedFilter: _selectedFilter,
        onFilterChanged: _filterBooks,
        filters: _filters,
        colorScheme: Theme.of(context).colorScheme,
        textTheme: Theme.of(context).textTheme,
        currentUserId: user?.uid ?? '',
      ),
    );
  }
}
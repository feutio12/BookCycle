import 'package:bookcycle/composants/books_page.dart';
import 'package:bookcycle/pages/auth/loginpage.dart';
import 'package:bookcycle/pages/book/add_book_page.dart';
import 'package:bookcycle/pages/pages%20rincipales/chatpage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../book/book_detail_page.dart';

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
  bool _isFirstTime = true;

  @override
  void initState() {
    super.initState();
    _checkFirstTime();
    _checkGuestPostingStatus();
    _fetchBooks();
  }

  Future<void> _checkFirstTime() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isFirstTime = prefs.getBool('isFirstTime') ?? true;
    });

    if (_isFirstTime) {
      await prefs.setBool('isFirstTime', false);
    }
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
      final books = await Future.wait(snapshot.docs.map((doc) async {
        final data = doc.data();
        final userId = data['userId'] ?? '';
        String publisherName = 'Utilisateur inconnu';

        // Récupérer le nom du publicateur depuis Firestore
        if (userId.isNotEmpty) {
          try {
            final userDoc = await _firestore.collection('users').doc(userId).get();
            if (userDoc.exists) {
              publisherName = userDoc.data()?['displayName'] ??
                  userDoc.data()?['name'] ??
                  userDoc.data()?['email']?.split('@').first ??
                  'Utilisateur';
            }
          } catch (e) {
            print('Erreur lors de la récupération du publicateur: $e');
          }
        }

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
          'userId': userId,
          'condition': data['condition'] ?? 'Bon état',
          'type': data['type'] ?? 'Échange',
          'location': data['location'] ?? 'Non spécifié',
          'publisherName': publisherName, // Ajout du nom du publicateur
        };
      }));

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
    final user = _auth.currentUser;
    if (user == null) {
      _showLoginRequiredSnackBar('pour aimer un livre');
      return;
    }

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

  void _navigateToBookDetails(Map<String, dynamic> book) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => BookDetailPage(
          book: book,
          publisherId: book['userId'] ?? '',
          publisherName: book['publisherName'] ?? 'Utilisateur inconnu',
          bookId: book['id'] ?? '',
        ),
      ),
    );
  }

  Future<void> _navigateToAddBook() async {
    final user = _auth.currentUser;
    if (user == null) {
      _showLoginRequiredSnackBar('pour ajouter un livre');
      return;
    }

    final isGuest = user.isAnonymous;

    if (isGuest) {
      final prefs = await SharedPreferences.getInstance();
      final hasPosted = prefs.getBool('hasPostedAsGuest') ?? false;

      final guestBooksCount = _allBooks.where((book) => book['isGuestBook'] == true).length;
      if (guestBooksCount >= 1) {
        await prefs.setBool('hasPostedAsGuest', true);
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
        setState(() {
          _hasPostedAsGuest = true;
        });
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
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red[700],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF2E7D32),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _showLoginRequiredSnackBar(String action) {
    final scaffold = ScaffoldMessenger.of(context);
    scaffold.showSnackBar(
      SnackBar(
        content: Text('Connectez-vous $action'),
        backgroundColor: const Color(0xFF1976D2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        action: SnackBarAction(
          label: 'Se connecter',
          textColor: Colors.white,
          onPressed: () {
            scaffold.hideCurrentSnackBar();
            _navigateToLogin();
          },
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;

    return Theme(
      data: ThemeData(
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF1976D2), // Bleu principal
          surface: Colors.white,
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onSurface: Color(0xFF212121),
          onBackground: Color(0xFF212121),
          brightness: Brightness.light,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1976D2),
          elevation: 4,
          iconTheme: IconThemeData(color: Colors.white),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1976D2),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            textStyle: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
        ),
        textTheme: const TextTheme(
          titleLarge: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          headlineSmall: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1976D2),
          ),
          bodyLarge: TextStyle(
            fontSize: 16,
            color: Color(0xFF424242),
          ),
        ),
      ),
      child: Scaffold(
        appBar: AppBar(
          title: RichText(
            text: TextSpan(
              text: 'BIENVENU ',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              children: [
                TextSpan(
                  text: user?.displayName ?? '',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFC8E6C9), // Vert clair pour le nom
                  ),
                ),
              ],
            ),
          ),
          backgroundColor: const Color(0xFF1976D2),
          elevation: 4,
          actions: [
            IconButton(
              icon: const Icon(Icons.add_comment_rounded, size: 28),
              onPressed: _navigateToAddBook,
              tooltip: 'Ajouter un livre',
            ),
            IconButton(
              icon: const Icon(Icons.refresh, size: 28),
              onPressed: _fetchBooks,
              tooltip: 'Actualiser',
            ),
          ],
        ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFFF5F9FF),
                Color(0xFFE8F5E9),
              ],
            ),
          ),
          child: _isLoading
              ? Center(
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
          )
              : _filteredBooks.isEmpty
              ? Center(
            child: Container(
              padding: const EdgeInsets.all(24),
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
                    _selectedFilter == 'Tous'
                        ? 'Soyez le premier à ajouter un livre!'
                        : 'Aucun livre dans la catégorie "$_selectedFilter"',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color(0xFF757575),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: _navigateToAddBook,
                    icon: const Icon(Icons.add),
                    label: const Text('Ajouter un livre'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1976D2),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
              : BooksPage(
            books: _filteredBooks,
            onLikePressed: _toggleLike,
            onBookPressed: _navigateToBookDetails,
            selectedFilter: _selectedFilter,
            onFilterChanged: _filterBooks,
            filters: _filters,
            colorScheme: Theme.of(context).colorScheme,
            textTheme: Theme.of(context).textTheme,
            currentUserId: user?.uid ?? '',
          ),
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart' hide SearchBar;
import 'package:bookcycle/composants/books_page.dart';
import 'package:bookcycle/pages/auth/loginpage.dart';
import 'package:bookcycle/pages/book/add_book_page.dart';
import 'package:bookcycle/pages/pages%20rincipales/chatpage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../book/book_detail_page.dart';
import '../book/book_filter.dart';
import '../book/book_list.dart';

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
  final ScrollController _scrollController = ScrollController();
  bool _showSearchBar = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _checkFirstTime();
    _checkGuestPostingStatus();
    _fetchBooks();
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.offset > 100 && !_showSearchBar) {
      setState(() => _showSearchBar = true);
    } else if (_scrollController.offset <= 100 && _showSearchBar) {
      setState(() => _showSearchBar = false);
    }
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
          'publisherName': publisherName,
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
      if (_searchController.text.isNotEmpty) {
        _filteredBooks = _applyFilter(_allBooks, filter)
            .where((book) => book['title'].toLowerCase().contains(_searchController.text.toLowerCase()) ||
            book['author'].toLowerCase().contains(_searchController.text.toLowerCase()))
            .toList();
      } else {
        _filteredBooks = _applyFilter(_allBooks, filter);
      }
    });
  }

  void _searchBooks(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredBooks = _applyFilter(_allBooks, _selectedFilter);
      } else {
        _filteredBooks = _applyFilter(_allBooks, _selectedFilter)
            .where((book) => book['title'].toLowerCase().contains(query.toLowerCase()) ||
            book['author'].toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 4,
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF2E7D32),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        duration: const Duration(seconds: 1),
        elevation: 4,
        margin: const EdgeInsets.all(16),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        action: SnackBarAction(
          label: 'Se connecter',
          textColor: Colors.white,
          onPressed: () {
            scaffold.hideCurrentSnackBar();
            _navigateToLogin();
          },
        ),
        duration: const Duration(seconds: 3),
        elevation: 4,
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    final name = user?.displayName ?? '';

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: const Color(0xFFF5F9FF),
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F9FF),
        body: NestedScrollView(
          controller: _scrollController,
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverAppBar(
                expandedHeight: 200.0,
                floating: false,
                pinned: true,
                snap: false,
                backgroundColor: Colors.transparent,
                elevation: 0,
                flexibleSpace: LayoutBuilder(
                  builder: (context, constraints) {
                    return Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            const Color(0xFF1976D2).withOpacity(0.9),
                            const Color(0xFF42A5F5).withOpacity(0.8),
                          ],
                        ),
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(constraints.maxHeight > 120 ? 30 : 0),
                          bottomRight: Radius.circular(constraints.maxHeight > 120 ? 30 : 0),
                        ),
                      ),
                      child: FlexibleSpaceBar(
                        collapseMode: CollapseMode.pin,
                        background: Header(name: name),
                      ),
                    );
                  },
                ),
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(70),
                  child: Container(
                    transform: Matrix4.translationValues(0, 15, 0),
                    child: SearchBar(
                      controller: _searchController,
                      onChanged: _searchBooks,
                      onFilterPressed: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (context) => BookFilter(
                            filters: _filters,
                            selectedFilter: _selectedFilter,
                            onFilterChanged: _filterBooks,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ];
          },
          body: Container(
            decoration: const BoxDecoration(
              color: Color(0xFFF5F9FF),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(30),
                topRight: Radius.circular(30),
              ),
            ),
            child: BookList(
              books: _filteredBooks,
              onLikePressed: _toggleLike,
              onBookPressed: _navigateToBookDetails,
              selectedFilter: _selectedFilter,
              onFilterChanged: _filterBooks,
              filters: _filters,
              colorScheme: Theme.of(context).colorScheme,
              textTheme: Theme.of(context).textTheme,
              currentUserId: user?.uid ?? '',
              isLoading: _isLoading,
              scrollController: _scrollController,
            ),
          ),
        ),
        floatingActionButton: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1976D2).withOpacity(0.4),
                blurRadius: 10,
                spreadRadius: 2,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: FloatingActionButton(
            onPressed: _navigateToAddBook,
            backgroundColor: const Color(0xFF1976D2),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            elevation: 0,
            child: const Icon(Icons.add, size: 28),
          ),
        ),
      ),
    );
  }
}
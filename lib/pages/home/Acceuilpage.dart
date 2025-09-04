import 'package:flutter/material.dart' hide SearchBar;
import 'package:bookcycle/pages/book/books_page.dart';
import 'package:bookcycle/pages/auth/loginpage.dart';
import 'package:bookcycle/pages/book/add_book_page.dart';
import 'package:bookcycle/pages/chats/chatpage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../book/book_detail_page.dart';
import '../book/book_filter.dart';
import '../book/book_list.dart';
import '../chats/chat_service.dart';

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
  bool _isFirstTime = true;
  final ScrollController _scrollController = ScrollController();
  bool _showSearchBar = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _checkFirstTime();
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

  Future<void> _fetchBooks() async {
    try {
      final snapshot = await _firestore.collection('books').get();
      final user = _auth.currentUser;
      final userEmail = user?.email;

      final books = await Future.wait(snapshot.docs.map((doc) async {
        final data = doc.data();
        final publisherEmail = data['publisherEmail'] ?? '';
        String publisherName = 'Utilisateur inconnu';

        // Récupérer le nom de l'utilisateur
        if (publisherEmail.isNotEmpty) {
          try {
            final userQuery = await _firestore.collection('users')
                .where('email', isEqualTo: publisherEmail)
                .limit(1)
                .get();

            if (userQuery.docs.isNotEmpty) {
              final userData = userQuery.docs.first.data();
              publisherName = userData['displayName'] ??
                  userData['name'] ??
                  userData['email']?.split('@').first ??
                  'Utilisateur';
            }
          } catch (e) {
            print('Erreur lors de la récupération du publicateur: $e');
          }
        }

        // Récupérer les likes
        final likedBy = List<String>.from(data['likedBy'] ?? []);
        final isLiked = userEmail != null && likedBy.contains(userEmail);

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
          'isLiked': isLiked,
          'publisherEmail': publisherEmail, // Email du publieur
          'condition': data['condition'] ?? 'Bon état',
          'type': data['type'] ?? 'Échange',
          'location': data['location'] ?? 'Non spécifié',
          'publisherName': publisherName,
          'likedBy': likedBy,
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

      final userEmail = user.email;
      final currentLikedBy = List<String>.from(_allBooks[bookIndex]['likedBy'] ?? []);
      final isCurrentlyLiked = currentLikedBy.contains(userEmail);

      // Déterminer le nouvel état
      final isLiked = !isCurrentlyLiked;

      // Mettre à jour la liste likedBy
      final newLikedBy = List<String>.from(currentLikedBy);
      if (isLiked) {
        newLikedBy.add(userEmail!);
      } else {
        newLikedBy.remove(userEmail);
      }

      final newLikes = newLikedBy.length;

      // Mettre à jour Firestore
      await _firestore.collection('books').doc(bookId).update({
        'likes': newLikes,
        'likedBy': newLikedBy,
      });

      if (mounted) {
        setState(() {
          _allBooks[bookIndex]['isLiked'] = isLiked;
          _allBooks[bookIndex]['likes'] = newLikes;
          _allBooks[bookIndex]['likedBy'] = newLikedBy;
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
          publisherEmail: book['publisherEmail'] ?? '',
          publisherName: book['publisherName'] ?? 'Utilisateur inconnu',
          bookId: book['id'] ?? '', publisherId: '',
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

    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => AddBookPage(book: {},),
      ),
    );

    if (result == true && mounted) {
      await _fetchBooks();
    }
  }

  void _navigateToLogin() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
    );
  }

  // Ajoutez ces fonctions dans votre _AcceuilpageState

  Future<void> _handleDeleteBook(String bookId) async {
    final user = _auth.currentUser;
    if (user == null) {
      _showLoginRequiredSnackBar('pour supprimer un livre');
      return;
    }

    try {
      // Récupérer le livre pour vérifier la propriété
      final bookDoc = await _firestore.collection('books').doc(bookId).get();
      if (!bookDoc.exists) {
        _showErrorSnackBar('Livre non trouvé');
        return;
      }

      final bookData = bookDoc.data() as Map<String, dynamic>;
      final publisherEmail = bookData['publisherEmail'] ?? '';

      // Vérifier que l'utilisateur est le propriétaire
      if (publisherEmail != user.email) {
        _showErrorSnackBar('Vous ne pouvez pas supprimer ce livre');
        return;
      }

      // Confirmation de suppression
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Confirmer la suppression'),
          content: const Text('Êtes-vous sûr de vouloir supprimer ce livre? Cette action est irréversible.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );

      if (confirmed == true) {
        await _firestore.collection('books').doc(bookId).delete();
        _showSuccessSnackBar('Livre supprimé avec succès');
        await _fetchBooks(); // Recharger la liste
      }
    } catch (e) {
      _showErrorSnackBar('Erreur lors de la suppression: $e');
    }

  }

  Future<void> _handleEditBook(Map<String, dynamic> book) async {
    final user = _auth.currentUser;
    if (user == null) {
      _showLoginRequiredSnackBar('pour modifier un livre');
      return;
    }

    // Vérifier que l'utilisateur est le propriétaire
    final publisherEmail = book['publisherEmail'] ?? '';
    if (publisherEmail != user.email) {
      _showErrorSnackBar('Vous ne pouvez pas modifier ce livre');
      return;
    }

    // Naviguer vers la page d'édition
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => AddBookPage(book: book),
      ),
    );

    if (result == true && mounted) {
      await _fetchBooks(); // Recharger après modification
    }
  }

  Future<void> _handleContactPublisher(String publisherEmail, String publisherName, String bookTitle) async {
    final user = _auth.currentUser;
    if (user == null) {
      _showLoginRequiredSnackBar('pour contacter un publicateur');
      return;
    }

    try {
      // Vérifier qu'on ne se contacte pas soi-même
      if (publisherEmail == user.email) {
        _showErrorSnackBar('Vous ne pouvez pas vous contacter vous-même');
        return;
      }

      // Générer l'ID de chat
      final chatId = ChatService.generateChatId(user.uid, publisherEmail);

      // Créer le chat si nécessaire
      await ChatService.createChatIfNeeded(
        chatId: chatId,
        otherUserId: publisherEmail,
        otherUserName: publisherName,
      );

      // Envoyer le message initial directement
      final initialMessage = "Bonjour, je suis intéressé par votre livre \"$bookTitle\"";

      await ChatService.sendMessage(
        chatId: chatId,
        content: initialMessage,
        otherUserId: publisherEmail,
        otherUserName: publisherName,
      );

      // Naviguer vers la page de chat
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatPage(
            chatId: chatId,
            otherUserId: publisherEmail,
            otherUserName: publisherName,
            initialMessage: "", // Maintenant vide car le message est déjà envoyé
          ),
        ),
      );

      // Mettre à jour le compteur de messages non lus pour le publicateur
      await _updateUnreadCountForPublisher(chatId, publisherEmail);

    } catch (e) {
      _showErrorSnackBar('Erreur lors de la création du chat: $e');
    }
  }

  Future<void> _updateUnreadCountForPublisher(String chatId, String publisherEmail) async {
    try {
      // Mettre à jour le compteur de messages non lus pour le publicateur
      await FirebaseFirestore.instance
          .collection('users')
          .doc(publisherEmail)
          .collection('chats')
          .doc(chatId)
          .update({
        'unreadCount': FieldValue.increment(1),
        'lastMessageTime': FieldValue.serverTimestamp(),
      });

      // Mettre à jour également le document chat principal
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(chatId)
          .update({
        'unreadCount': FieldValue.increment(1),
      });

    } catch (e) {
      print('Erreur lors de la mise à jour du compteur de non-lus: $e');
    }
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
    final name = user?.displayName ?? '';

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F9FF),
        body: NestedScrollView(
          controller: _scrollController,
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverAppBar(
                expandedHeight: 180.0,
                floating: false,
                pinned: true,
                snap: false,
                backgroundColor: const Color(0xFF1976D2),
                elevation: 4,
                flexibleSpace: FlexibleSpaceBar(
                  collapseMode: CollapseMode.pin,
                  background: Header(name: name),
                ),
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(60),
                  child: SearchBar(
                    controller: _searchController,
                    onChanged: _searchBooks,
                    onFilterPressed: () {
                      showModalBottomSheet(
                        context: context,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                        ),
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
            ];
          },
          body: BookList(
            books: _filteredBooks,
            onLikePressed: _toggleLike,
            onBookPressed: _navigateToBookDetails,
            selectedFilter: _selectedFilter,
            onFilterChanged: _filterBooks,
            filters: _filters,
            colorScheme: Theme.of(context).colorScheme,
            textTheme: Theme.of(context).textTheme,
            currentUserId: user?.email ?? '', // Utiliser l'email comme ID
            isLoading: _isLoading,
            scrollController: _scrollController,
            onDeleteBook: _handleDeleteBook, // Callback pour suppression
            onEditBook: _handleEditBook, // Callback pour modification
            onContactPublisher: _handleContactPublisher,
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _navigateToAddBook,
          backgroundColor: const Color(0xFF1976D2),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: const Icon(Icons.add, size: 28),
        ),
      ),
    );
  }
}
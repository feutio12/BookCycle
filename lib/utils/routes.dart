import 'package:bookcycle/pages/home/homepage.dart';
import 'package:bookcycle/pages/home/Acceuilpage.dart';
import 'package:flutter/material.dart';
import 'package:bookcycle/pages/book/book_detail_page.dart';
import 'package:bookcycle/pages/book/add_book_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../pages/onboarding/animation.dart';
import '../pages/auth/loginpage.dart';
import '../pages/auth/registerpage.dart';
import '../pages/enchere/add_enchere.dart';
import '../pages/chats/chats_list_page.dart';
import '../pages/profile/profilpage.dart';
import '../pages/chats/chatpage.dart';

class AppRoutes {
  // Noms de routes constants
  static const String splash = '/';
  static const String home = '/home';
  static const String login = '/login';
  static const String register = '/register';
  static const String acceuil = '/acceuil';
  static const String bookDetail = '/book-detail';
  static const String addBook = '/add-book';
  static const String addEnchere = '/add-enchere';
  static const String profile = '/profile';
  static const String adminStats = '/admin-stats';
  static const String exchange = '/exchange';
  static const String chats = '/chats';
  static const String chatPage = '/chat-page';

  // Référence Firestore
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Générateur de routes
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return MaterialPageRoute(builder: (_) => const SplashAnimation());
      case home:
        return MaterialPageRoute(builder: (_) => const Homepage());
      case login:
        return MaterialPageRoute(builder: (_) => const LoginPage());
      case register:
        return MaterialPageRoute(builder: (_) => const RegisterPage());
      case acceuil:
        return MaterialPageRoute(builder: (_) => const Acceuilpage());
      case bookDetail:
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (_) => BookDetailPage(
            bookId: args['bookId'],
            book: args['book'],
            publisherId: args['publisherId'],
            publisherName: args['publisherName'], publisherEmail: null,
          ),
        );
      case addBook:
        return MaterialPageRoute(builder: (_) => const AddBookPage(book: {},));
      case addEnchere:
        return MaterialPageRoute(builder: (_) => const AddEncherePage(isGuest: false));
      case profile:
        return MaterialPageRoute(builder: (_) => ProfilePage(user: FirebaseAuth.instance.currentUser));
      case chats:
        return MaterialPageRoute(builder: (_) => const DiscussionsListPage());
      case chatPage:
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (_) => ChatPage(
            chatId: args['chatId'],
            otherUserId: args['otherUserId'],
            otherUserName: args['otherUserName'],
            initialMessage: args['initialMessage'] ?? '',
          ),
        );
      case exchange:
        final exchangeData = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => const DiscussionsListPage(),
        );
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('Aucune route définie pour ${settings.name}'),
            ),
          ),
        );
    }
  }

  // Vérifie si l'utilisateur actuel est admin
  static Future<bool> isCurrentUserAdmin() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return false;

      final doc = await _firestore.collection('users').doc(user.uid).get();
      return doc.exists && doc.data()?['isAdmin'] == true;
    } catch (e) {
      print('Error checking admin status: $e');
      return false;
    }
  }

  // Middleware de protection de route pour admin
  static Future<bool> protectAdminRoute(BuildContext context) async {
    final isAdmin = await isCurrentUserAdmin();
    if (!isAdmin) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Action réservée aux administrateurs'),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }
    return true;
  }

  // Vérifie si l'utilisateur est connecté
  static bool isUserLoggedIn() {
    return FirebaseAuth.instance.currentUser != null;
  }

  // Redirige vers login si non connecté
  static void requireLogin(BuildContext context) {
    if (!isUserLoggedIn()) {
      Navigator.pushNamed(context, login);
    }
  }

  // Navigation vers la page de détail du livre
  static void navigateToBookDetail(BuildContext context, {
    required String bookId,
    required Map<String, dynamic> book,
    required String publisherId,
    required String publisherName,
  }) {
    Navigator.pushNamed(
      context,
      bookDetail,
      arguments: {
        'bookId': bookId,
        'book': book,
        'publisherId': publisherId,
        'publisherName': publisherName,
      },
    );
  }

  // Navigation vers la page de chat
  static void navigateToChatPage(BuildContext context, {
    required String chatId,
    required String otherUserId,
    required String otherUserName,
    String? initialMessage,
  }) {
    Navigator.pushNamed(
      context,
      chatPage,
      arguments: {
        'chatId': chatId,
        'otherUserId': otherUserId,
        'otherUserName': otherUserName,
        'initialMessage': initialMessage,
      },
    );
  }

  // Navigation vers la liste des discussions
  static void navigateToChatsList(BuildContext context) {
    Navigator.pushNamed(context, chats);
  }

  // Méthode de déconnexion globale
  static Future<void> logout(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.login,
              (route) => false
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la déconnexion: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
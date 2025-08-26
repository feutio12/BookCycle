import 'package:bookcycle/pages/homepage.dart';
import 'package:bookcycle/pages/pages%20rincipales/Acceuilpage.dart';
import 'package:flutter/material.dart';
import 'package:bookcycle/pages/book/book_detail_page.dart';
import 'package:bookcycle/pages/book/add_book_page.dart';
import 'package:bookcycle/pages/admin/stats_analyse.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../pages/animation.dart';
import '../pages/auth/loginpage.dart';
import '../pages/auth/registerpage.dart';
import '../pages/enchere/add_enchere.dart';
import '../pages/chats/chats_list_page.dart';
import '../pages/pages rincipales/profilpage.dart';
import '../pages/pages rincipales/chatpage.dart'; // Import ajouté

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
  static const String chatPage = '/chat-page'; // Nouvelle route ajoutée

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
      case adminStats:
        return MaterialPageRoute(builder: (_) => const StatsAnalysisPage());
      case bookDetail:
        final bookId = settings.arguments as String;
        return MaterialPageRoute(
          builder: (_) => BookDetailPage(
            bookId: bookId,
            book: {},
            publisherId: '',
            publisherName: '',
          ),
        );
      case addBook:
        return MaterialPageRoute(builder: (_) => const AddBookPage(isGuest: true));
      case addEnchere:
        return MaterialPageRoute(builder: (_) => const AddEncherePage(isGuest: false));
      case profile:
        return MaterialPageRoute(builder: (_) => ProfilePage(user: FirebaseAuth.instance.currentUser));
      case chats:
        return MaterialPageRoute(builder: (_) => const DiscussionsListPage(discussions: [],));
      case chatPage:
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (_) => ChatPage(
            chatId: args['chatId'],
            otherUserId: args['otherUserId'],
            otherUserName: args['otherUserName'],
            initialMessage: '',
          ),
        );
      case exchange:
        final exchangeData = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => const DiscussionsListPage(discussions: [],),
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

  // Navigation vers la page de chat
  static void navigateToChatPage(BuildContext context, {
    required String chatId,
    required String otherUserId,
    required String otherUserName,
  }) {
    Navigator.pushNamed(
      context,
      chatPage,
      arguments: {
        'chatId': chatId,
        'otherUserId': otherUserId,
        'otherUserName': otherUserName,
      },
    );
  }
}
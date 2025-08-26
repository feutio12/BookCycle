import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:bookcycle/pages/pages%20rincipales/profilpage.dart';
import 'package:bookcycle/pages/pages%20rincipales/chatpage.dart';
import 'package:bookcycle/pages/pages%20rincipales/searchpage.dart';
import '../models/chats.dart';
import '../widgets/app_drawer.dart';
import 'auth/loginpage.dart';
import 'chats/chats_list_page.dart';
import 'pages rincipales/Acceuilpage.dart';
import 'pages rincipales/Encherepage.dart'; // Déplacé ici pour éviter l'import circulaire

class Homepage extends StatelessWidget {
  final Map<String, dynamic>? userData;

  const Homepage({super.key, this.userData});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'BookCycle',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 2;
  User? currentUser;

  final List<ChatDiscussion> discussions = [
    ChatDiscussion(
      chatId: "1",
      otherUserId: "2",
      otherUserName: "Jean Dupont",
      lastMessage: "Bonjour, le livre est-il disponible?",
      lastMessageTime: DateTime.now().subtract(const Duration(minutes: 5)),
      unreadCount: 2,
      participants: [],
      lastMessageSenderId: '',
    ),
    ChatDiscussion(
      chatId: "2",
      otherUserId: "3",
      otherUserName: "Marie Martin",
      lastMessage: "Je suis intéressée par votre livre",
      lastMessageTime: DateTime.now().subtract(const Duration(hours: 2)),
      unreadCount: 0,
      participants: [],
      lastMessageSenderId: '',
    ),
  ];

  late List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _initializeScreens();
    _getCurrentUser();
  }

  void _initializeScreens() {
    _screens = [
      SearchPage(),
      DiscussionsListPage(discussions: discussions),
      Acceuilpage(), // Retirer const
      AuctionPage(),
      ProfilePage(), // Retirer const
    ];
  }

  void _navigateToLogin() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => LoginPage()), // Retirer const
    );
  }

  Future<void> _getCurrentUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        currentUser = user;
        _initializeScreens(); // Réinitialiser les écrans
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(),
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blue[800],
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.grey.shade200,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Search',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.message),
            label: 'Chat',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.gavel_rounded),
            label: 'Enchères',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
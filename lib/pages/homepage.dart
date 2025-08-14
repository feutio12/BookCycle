import 'package:bookcycle/pages/pages%20rincipales/Encherepage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:bookcycle/pages/pages%20rincipales/profilpage.dart';
import 'package:bookcycle/pages/pages%20rincipales/chatpage.dart';
import 'package:bookcycle/pages/pages%20rincipales/searchpage.dart';
import 'auth/loginpage.dart';
import 'pages rincipales/Acceuilpage.dart';

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
  int _currentIndex = 2; // Index par défaut sur Home
  User? currentUser; // Add this to store the current user

  // Liste fictive de discussions
  final List<ChatDiscussion> discussions = [
    ChatDiscussion(
      chatId: "1",
      otherUserId: "2",
      otherUserName: "Jean Dupont",
      lastMessage: "Bonjour, le livre est-il disponible?",
      lastMessageTime: DateTime.now().subtract(const Duration(minutes: 5)),
      unreadCount: 2,
    ),
    ChatDiscussion(
      chatId: "2",
      otherUserId: "3",
      otherUserName: "Marie Martin",
      lastMessage: "Je suis intéressée par votre livre",
      lastMessageTime: DateTime.now().subtract(const Duration(hours: 2)),
    ),
  ];

  late final List<Widget> _screens;

  get user => null;

  @override
  void initState() {
    super.initState();

    // Initialize with empty screens first
    _screens = [
      SearchPage(),
      DiscussionsListPage(discussions: discussions),
      const Acceuilpage(),
      AuctionPage(),
      BookCycleApp(),
      const Center(child: CircularProgressIndicator()), // Temporary placeholder
    ];

    // Get the current user
    _getCurrentUser();
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

  void _showLoginRequiredSnackBar() {
    final scaffold = ScaffoldMessenger.of(context);
    scaffold.showSnackBar(
      SnackBar(
        content: const Text('Connectez-vous pour ajouter plus de livres'),
        action: SnackBarAction(
          label: 'Se connecter',
          onPressed: () {
            scaffold.hideCurrentSnackBar();
            _navigateToLogin();
          },
        ),
      ),
    );
  }

  Future<void> _getCurrentUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        currentUser = user;
        // Update screens with the proper ProfilePage
        _screens = [
          SearchPage(),
          DiscussionsListPage(discussions: discussions),
          const Acceuilpage(),
          AuctionPage(),
          BookCycleApp(), // Now passing the required user parameter
        ];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
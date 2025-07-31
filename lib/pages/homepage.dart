// homepage.dart
import 'package:flutter/material.dart';
import 'package:bookcycle/pages/chatpage.dart';
import 'searchpage.dart';

class Homepage extends StatelessWidget {
  const Homepage({super.key});

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

  @override
  void initState() {
    super.initState();
    // Maintenant on peut initialiser _screens car discussions est disponible
    _screens = [
      SearchPage(),
      DiscussionsListPage(discussions: discussions), // discussions est accessible ici
      const Center(child: Text('Page d\'accueil')),
      const Center(child: Text('Vente de livres')),
      const Center(child: Text('Votre profil')),
    ];
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
            icon: Icon(Icons.monetization_on),
            label: 'Vente',
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
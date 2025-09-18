import 'package:animated_notch_bottom_bar/animated_notch_bottom_bar/animated_notch_bottom_bar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:bookcycle/pages/profile/profilpage.dart';
import '../../widgets/app_drawer.dart';
import '../chats/chats_list_page.dart';
import '../recherche/searchpage.dart';
import 'Acceuilpage.dart';
import '../enchere/Encherepage.dart';

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
  late PageController _pageController;
  final _controller = NotchBottomBarController(index: 2);
  User? currentUser;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(),
      body: SizedBox.expand(
        child: PageView(
          controller: _pageController,
          physics: NeverScrollableScrollPhysics(),
          onPageChanged: (index) {
            setState(() => _currentIndex = index);
            _controller.index = index;
          },
          children: <Widget>[
            SearchPage(),
            const DiscussionsListPage(),
            Acceuilpage(),
            AuctionPage(),
            ProfilePage(),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        // Supprimer tous les marges et padding autour de la barre
        margin: EdgeInsets.zero,
        padding: EdgeInsets.zero,
        child: Row(
          children: [
            Spacer(),
            AnimatedNotchBottomBar(
              notchBottomBarController: _controller,
              color: Colors.grey.shade300,
              showLabel: true,
              removeMargins: true,
              notchColor: Color(0xFF1976D2),
              itemLabelStyle: TextStyle(color: Color(0xFF1976D2)),
              bottomBarItems: [
                BottomBarItem(
                  inActiveItem: Image.asset(
                    'assets/images/search_vide.png',
                    color: Color(0xFF1976D2),
                    width: 24,
                    height: 24,
                  ),
                  activeItem: Image.asset(
                    'assets/images/search.png',
                    color: Colors.white,
                    width: 24,
                    height: 24,
                  ),
                  itemLabel: 'Recherche',
                ),
                BottomBarItem(
                  inActiveItem: Image.asset(
                    'assets/images/chatting_vide.png',
                    color: Color(0xFF1976D2),
                    width: 24,
                    height: 24,
                  ),
                  activeItem: Image.asset(
                    'assets/images/chatting.png',
                    color: Colors.white,
                    width: 24,
                    height: 24,
                  ),
                  itemLabel: 'Messages',
                ),
                BottomBarItem(
                  inActiveItem: Image.asset(
                    'assets/images/home_vide.png',
                    color: Color(0xFF1976D2),
                    width: 24,
                    height: 24,
                  ),
                  activeItem: Image.asset(
                    'assets/images/home.png',
                    color: Colors.white,
                    width: 24,
                    height: 24,
                  ),
                  itemLabel: 'Accueil',
                ),
                BottomBarItem(
                  inActiveItem: Image.asset(
                    'assets/images/auction.vide.png',
                    color: Color(0xFF1976D2),
                    width: 24,
                    height: 24,
                  ),
                  activeItem: Image.asset(
                    'assets/images/auction.png',
                    color: Colors.white,
                    width: 24,
                    height: 24,
                  ),
                  itemLabel: 'Enchère',
                ),
                BottomBarItem(
                  inActiveItem: Image.asset(
                    'assets/images/user_vide.png',
                    color: Color(0xFF1976D2),
                    width: 24,
                    height: 24,
                  ),
                  activeItem: Image.asset(
                    'assets/images/user.png',
                    color: Colors.white,
                    width: 24,
                    height: 24,
                  ),
                  itemLabel: 'Profil',
                ),
              ],
              onTap: (index) {
                setState(() {
                  _currentIndex = index;
                });
                _pageController.jumpToPage(index);
              },
              kIconSize: 20,
              kBottomRadius: 0,
              shadowElevation: 0,
              // Étendre la barre sur toute la largeur
              bottomBarWidth: MediaQuery.of(context).size.width,
            ),
          ],
        ),
      ),
    );
  }
}
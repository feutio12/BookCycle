// home_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'side_menu.dart';
import 'dashboard_screen.dart';
import 'color_constants.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final User? user = FirebaseAuth.instance.currentUser;
  int _selectedIndex = 0;
  bool _isDrawerOpen = false;

  // Pages correspondant aux éléments du menu
  final List<Widget> _pages = [
    DashboardScreen(),
    Container(child: Center(child: Text("Livres"))),
    Container(child: Center(child: Text("Utilisateurs"))),
    Container(child: Center(child: Text("Échanges"))),
    Container(child: Center(child: Text("Statistiques"))),
    Container(child: Center(child: Text("Rapports"))),
    Container(child: Center(child: Text("Paramètres"))),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: secondaryColor,
        leading: IconButton(
          icon: Icon(Icons.menu, color: Colors.white),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
        title: Text(
          "BookCycle Admin",
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.notifications, color: Colors.white70),
            onPressed: () {},
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.0),
            child: CircleAvatar(
              backgroundColor: primaryColor,
              child: Text(
                user?.email?.substring(0, 1).toUpperCase() ?? "A",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
      drawer: SideMenu(
        onItemSelected: _onItemTapped,
        selectedIndex: _selectedIndex,
      ),
      body: Row(
        children: [
          if (MediaQuery.of(context).size.width >= 900)
            Container(
              width: 250,
              color: secondaryColor,
              child: SideMenu(
                onItemSelected: _onItemTapped,
                selectedIndex: _selectedIndex,
                isDesktop: true,
              ),
            ),
          Expanded(
            child: _pages[_selectedIndex],
          ),
        ],
      ),
    );
  }
}
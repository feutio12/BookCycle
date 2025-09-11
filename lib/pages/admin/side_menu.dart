// side_menu.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'color_constants.dart';

class SideMenu extends StatelessWidget {
  final Function(int) onItemSelected;
  final int selectedIndex;
  final bool isDesktop;

  const SideMenu({
    Key? key,
    required this.onItemSelected,
    required this.selectedIndex,
    this.isDesktop = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;

    return Container(
      color: secondaryColor,
      width: isDesktop ? null : 250,
      child: ListView(
        children: [
          if (!isDesktop) DrawerHeader(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundColor: primaryColor,
                  radius: 30,
                  child: Text(
                    user?.email?.substring(0, 1).toUpperCase() ?? "A",
                    style: TextStyle(
                      fontSize: 24,
                      color: Colors.white,
                    ),
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  user?.email ?? "Admin",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          _buildMenuItem(
            context,
            index: 0,
            icon: Icons.dashboard,
            title: "Tableau de bord",
          ),
          _buildMenuItem(
            context,
            index: 1,
            icon: Icons.book,
            title: "Livres",
          ),
          _buildMenuItem(
            context,
            index: 2,
            icon: Icons.people,
            title: "Utilisateurs",
          ),
          _buildMenuItem(
            context,
            index: 3,
            icon: Icons.swap_horiz,
            title: "Échanges",
          ),
          _buildMenuItem(
            context,
            index: 4,
            icon: Icons.bar_chart,
            title: "Statistiques",
          ),
          _buildMenuItem(
            context,
            index: 5,
            icon: Icons.description,
            title: "Rapports",
          ),
          Divider(color: Colors.white24),
          _buildMenuItem(
            context,
            index: 6,
            icon: Icons.settings,
            title: "Paramètres",
          ),
          ListTile(
            leading: Icon(Icons.logout, color: Colors.white70),
            title: Text("Déconnexion", style: TextStyle(color: Colors.white70)),
            onTap: () {
              FirebaseAuth.instance.signOut();
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(BuildContext context, {
    required int index,
    required IconData icon,
    required String title,
  }) {
    final bool isSelected = selectedIndex == index;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isSelected ? primaryColor.withOpacity(0.2) : Colors.transparent,
        borderRadius: BorderRadius.circular(defaultBorderRadius),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isSelected ? primaryColor : Colors.white70,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white70,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        onTap: () {
          onItemSelected(index);
          if (!isDesktop) {
            Navigator.pop(context);
          }
        },
      ),
    );
  }
}
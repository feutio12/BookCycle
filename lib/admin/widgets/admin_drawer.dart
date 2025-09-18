import 'package:flutter/material.dart';
import 'package:bookcycle/admin/pages/admin_dashboard.dart';
import 'package:bookcycle/admin/pages/admin_users_page.dart';
import 'package:bookcycle/admin/pages/admin_books_page.dart';
import 'package:bookcycle/admin/pages/admin_auctions_page.dart';
import 'package:bookcycle/admin/pages/admin_chats_page.dart';
import 'package:bookcycle/admin/pages/admin_settings_page.dart';
import 'package:bookcycle/admin/services/admin_auth_service.dart';

class AdminDrawer extends StatelessWidget {
  final AdminAuthService _authService = AdminAuthService();

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Colors.blue,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.admin_panel_settings, size: 48, color: Colors.white),
                SizedBox(height: 16),
                Text(
                  'BookCycle Admin',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: Icon(Icons.dashboard),
            title: Text('Tableau de bord'),
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => AdminDashboard()),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.people),
            title: Text('Utilisateurs'),
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => AdminUsersPage()),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.book),
            title: Text('Livres'),
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => AdminBooksPage()),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.gavel),
            title: Text('Enchères'),
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => AdminAuctionsPage()),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.chat),
            title: Text('Conversations'),
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => AdminChatsPage()),
              );
            },
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.settings),
            title: Text('Paramètres'),
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => AdminSettingsPage()),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.exit_to_app),
            title: Text('Déconnexion'),
            onTap: () async {
              await _authService.signOut();
            },
          ),
        ],
      ),
    );
  }
}
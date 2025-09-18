import 'package:flutter/material.dart';
import 'package:bookcycle/admin/widgets/admin_drawer.dart';
import 'package:bookcycle/admin/services/admin_auth_service.dart';

class AdminSettingsPage extends StatefulWidget {
  @override
  _AdminSettingsPageState createState() => _AdminSettingsPageState();
}

class _AdminSettingsPageState extends State<AdminSettingsPage> {
  final AdminAuthService _authService = AdminAuthService();
  bool _notificationsEnabled = true;
  bool _darkModeEnabled = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Paramètres administrateur'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      drawer: AdminDrawer(),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Card(
              child: ListTile(
                leading: Icon(Icons.person),
                title: Text('Profil administrateur'),
                subtitle: Text('Modifier les informations de votre compte'),
                trailing: Icon(Icons.arrow_forward_ios),
                onTap: () {
                  // Naviguer vers la page de profil
                },
              ),
            ),
            SizedBox(height: 16),
            Card(
              child: Column(
                children: [
                  ListTile(
                    title: Text('Préférences'),
                    leading: Icon(Icons.settings),
                  ),
                  SwitchListTile(
                    title: Text('Notifications'),
                    value: _notificationsEnabled,
                    onChanged: (value) {
                      setState(() {
                        _notificationsEnabled = value;
                      });
                    },
                    secondary: Icon(Icons.notifications),
                  ),
                  SwitchListTile(
                    title: Text('Mode sombre'),
                    value: _darkModeEnabled,
                    onChanged: (value) {
                      setState(() {
                        _darkModeEnabled = value;
                      });
                    },
                    secondary: Icon(Icons.dark_mode),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),
            Card(
              child: Column(
                children: [
                  ListTile(
                    title: Text('Sécurité'),
                    leading: Icon(Icons.security),
                  ),
                  ListTile(
                    title: Text('Changer le mot de passe'),
                    trailing: Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      _showChangePasswordDialog(context);
                    },
                  ),
                  ListTile(
                    title: Text('Journal de connexion'),
                    trailing: Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      // Voir le journal de connexion
                    },
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),
            Card(
              child: Column(
                children: [
                  ListTile(
                    title: Text('À propos'),
                    leading: Icon(Icons.info),
                  ),
                  ListTile(
                    title: Text('Version'),
                    subtitle: Text('1.0.0'),
                  ),
                  ListTile(
                    title: Text('Contact du support'),
                    subtitle: Text('support@bookcycle.com'),
                    onTap: () {
                      // Contacter le support
                    },
                  ),
                ],
              ),
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                _authService.signOut();
              },
              child: Text('Déconnexion'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Changer le mot de passe'),
          content: Text('Fonctionnalité à implémenter.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }
}
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../utils/auth_service.dart';
import '../utils/routes.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    return Drawer(
      child: FutureBuilder<bool>(
        future: authService.isAdmin(),
        builder: (context, snapshot) {
          final isAdmin = snapshot.data ?? false;

          return ListView(
            padding: EdgeInsets.zero,
            children: [
              const DrawerHeader(
                decoration: BoxDecoration(
                  color: Colors.blue,
                ),
                child: Text('BookCycle Menu'),
              ),
              ListTile(
                leading: const Icon(Icons.home),
                title: const Text('Accueil'),
                onTap: () {
                  Navigator.pushNamed(context, AppRoutes.home);
                },
              ),
              if (isAdmin)
                ListTile(
                  leading: const Icon(Icons.analytics),
                  title: const Text('Statistiques Admin'),
                  onTap: () {
                    Navigator.pushNamed(context, AppRoutes.adminStats);
                  },
                ),
              ListTile(
                leading: const Icon(Icons.person),
                title: const Text('Profil'),
                onTap: () {
                  Navigator.pushNamed(context, AppRoutes.profile);
                },
              ),
              ListTile(
                leading: const Icon(Icons.exit_to_app),
                title: const Text('Déconnexion'),
                onTap: () async {
                  await authService.signOut();
                  Navigator.pushReplacementNamed(context, AppRoutes.login);
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
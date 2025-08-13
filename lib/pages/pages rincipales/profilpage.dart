import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

void main() {
  runApp(const BookCycleApp());
}

class BookCycleApp extends StatelessWidget {
  const BookCycleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BookCycle',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2E7D32),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: const ProfilePage(),
    );
  }
}

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  // Données utilisateur simulées
  Map<String, dynamic> userData = {
    'name': 'Alex Dubois',
    'email': 'alex.dubois@bookcycle.com',
    'avatar': 'assets/images/ccc.jpg',
    'memberSince': 'Membre depuis Janvier 2023',
    'booksShared': 24,
    'booksReceived': 18,
    'rating': 4.7,
    'bio': 'Passionné de littérature contemporaine et de science-fiction. Échangeons nos coups de cœur !',
  };

  bool _isLoading = false;

  Future<void> _showLogoutDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Déconnexion'),
          content: const SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Voulez-vous vraiment vous déconnecter ?'),
                SizedBox(height: 8),
                Text('Vous devrez vous reconnecter pour accéder à votre compte.'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Annuler'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text(
                'Déconnexion',
                style: TextStyle(color: Colors.red),
              ),
              onPressed: () async {
                Navigator.of(context).pop();
                setState(() {
                  _isLoading = true;
                });

                // Simulation de délai pour la déconnexion
                await Future.delayed(const Duration(seconds: 1));

                setState(() {
                  _isLoading = false;
                });

                if (!mounted) return;

                // Afficher un message de confirmation
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Vous avez été déconnecté avec succès.'),
                    duration: Duration(seconds: 2),
                  ),
                );

                // Ici vous ajouteriez la logique de navigation vers l'écran de connexion
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200.0,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      colorScheme.primary,
                      colorScheme.primaryContainer,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: Colors.white,
                        child: ClipOval(
                          child: Image.asset(
                            userData['avatar'],
                            width: 75,
                            height: 75,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        userData['name'],
                        style: textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        userData['memberSince'],
                        style: textTheme.bodySmall?.copyWith(
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            pinned: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: _showLogoutDialog,
                tooltip: 'Déconnexion',
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Section Bio
                  Text(
                    'À propos',
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    userData['bio'],
                    style: textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 24),

                  // Stats
                  Text(
                    'Votre activité',
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatCard(
                        context,
                        'Partagés',
                        userData['booksShared'].toString(),
                        Icons.upload,
                      ),
                      _buildStatCard(
                        context,
                        'Reçus',
                        userData['booksReceived'].toString(),
                        Icons.download,
                      ),
                      _buildStatCard(
                        context,
                        'Note',
                        userData['rating'].toString(),
                        Icons.star,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Paramètres
                  Text(
                    'Paramètres',
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildSettingItem(
                    context,
                    'Modifier le profil',
                    Icons.edit,
                        () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Redirection vers l\'édition du profil'),
                        ),
                      );
                    },
                  ),
                  _buildSettingItem(
                    context,
                    'Préférences de notification',
                    Icons.notifications,
                        () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Redirection vers les paramètres de notification'),
                        ),
                      );
                    },
                  ),
                  _buildSettingItem(
                    context,
                    'Confidentialité',
                    Icons.privacy_tip,
                        () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Redirection vers les paramètres de confidentialité'),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),

                  // Bouton de déconnexion
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: _isLoading
                          ? const CupertinoActivityIndicator()
                          : const Icon(Icons.logout),
                      label: Text(
                        _isLoading ? 'Déconnexion en cours...' : 'Déconnexion',
                        style: const TextStyle(fontSize: 16),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.errorContainer,
                        foregroundColor: colorScheme.onErrorContainer,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _isLoading ? null : _showLogoutDialog,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      BuildContext context, String title, String value, IconData icon) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, size: 24, color: colorScheme.primary),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingItem(
      BuildContext context, String title, IconData icon, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right),
      contentPadding: EdgeInsets.zero,
      onTap: onTap,
    );
  }
}
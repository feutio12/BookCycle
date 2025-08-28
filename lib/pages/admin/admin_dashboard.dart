import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:bookcycle/pages/auth/loginpage.dart';
import 'package:bookcycle/composants/common_components.dart';
import 'package:bookcycle/composants/common_utils.dart';

import 'AdminAuctionsManagement.dart';
import 'AdminReports.dart';
import 'admin_users_management.dart';
import 'admin_books_management.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  int _selectedIndex = 0;
  Map<String, dynamic> _stats = {};

  static final List<Widget> _widgetOptions = [
    const DashboardHome(),
    const AdminUsersManagement(),
    const AdminBooksManagement(),
    const AdminAuctionsManagement(),
    const AdminReports(),
  ];

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      // Récupérer les statistiques
      final usersCount = await _firestore.collection('users').count().get();
      final booksCount = await _firestore.collection('books').count().get();
      final auctionsCount = await _firestore.collection('encheres').count().get();
      final activeAuctions = await _firestore.collection('encheres')
          .where('dateFin', isGreaterThan: DateTime.now())
          .count()
          .get();

      setState(() {
        _stats = {
          'users': usersCount.count,
          'books': booksCount.count,
          'auctions': auctionsCount.count,
          'activeAuctions': activeAuctions.count,
        };
      });
    } catch (e) {
      // Gérer l'erreur localement
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur de chargement des statistiques: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _signOut() async {
    try {
      await _auth.signOut();
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    } catch (e) {
      // Gérer l'erreur localement
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur de déconnexion: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tableau de bord Admin'),
        backgroundColor: Colors.blue, // Utiliser une couleur standard
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _signOut,
            tooltip: 'Déconnexion',
          ),
        ],
      ),
      body: Row(
        children: [
          // Sidebar
          NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (int index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            labelType: NavigationRailLabelType.all,
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.dashboard),
                label: Text('Dashboard'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.people),
                label: Text('Utilisateurs'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.book),
                label: Text('Livres'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.gavel),
                label: Text('Enchères'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.report),
                label: Text('Rapports'),
              ),
            ],
          ),
          const VerticalDivider(thickness: 1, width: 1),
          // Main content
          Expanded(
            child: _widgetOptions.elementAt(_selectedIndex),
          ),
        ],
      ),
    );
  }
}

class DashboardHome extends StatelessWidget {
  const DashboardHome({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.findAncestorStateOfType<_AdminDashboardState>();
    final stats = state?._stats ?? {};

    return SingleChildScrollView( // Ajouter SingleChildScrollView pour éviter l'overflow
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Vue d\'ensemble',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          // Statistics Cards - Utiliser GridView avec shrinkWrap
          GridView.count(
            shrinkWrap: true, // Important pour éviter l'overflow
            physics: const NeverScrollableScrollPhysics(), // Désactiver le scroll interne
            crossAxisCount: 2,
            childAspectRatio: 1.5,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            children: [
              _StatCard(
                title: 'Utilisateurs',
                value: stats['users']?.toString() ?? '0',
                icon: Icons.people,
                color: Colors.blue,
              ),
              _StatCard(
                title: 'Livres',
                value: stats['books']?.toString() ?? '0',
                icon: Icons.book,
                color: Colors.green,
              ),
              _StatCard(
                title: 'Enchères totales',
                value: stats['auctions']?.toString() ?? '0',
                icon: Icons.gavel,
                color: Colors.orange,
              ),
              _StatCard(
                title: 'Enchères actives',
                value: stats['activeAuctions']?.toString() ?? '0',
                icon: Icons.timer,
                color: Colors.purple,
              ),
            ],
          ),
          const SizedBox(height: 30),
          // Quick Actions
          const Text(
            'Actions rapides',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              ActionChip(
                avatar: const Icon(Icons.person_add, size: 18),
                label: const Text('Créer utilisateur'),
                onPressed: () {},
              ),
              ActionChip(
                avatar: const Icon(Icons.book_online, size: 18),
                label: const Text('Vérifier livres'),
                onPressed: () {},
              ),
              ActionChip(
                avatar: const Icon(Icons.warning, size: 18),
                label: const Text('Signalisations'),
                onPressed: () {},
              ),
              ActionChip(
                avatar: const Icon(Icons.settings, size: 18),
                label: const Text('Paramètres'),
                onPressed: () {},
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 30, color: color),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}
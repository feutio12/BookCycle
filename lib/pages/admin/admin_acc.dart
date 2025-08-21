import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminAccountPage extends StatelessWidget {
  const AdminAccountPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final statsRef = FirebaseFirestore.instance.collection('stats').doc('platform');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tableau de bord BookCycle'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => FirebaseAuth.instance.signOut(),
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: statsRef.snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final stats = snapshot.data!.data() as Map<String, dynamic>;

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Connecté en tant que: ${user?.email ?? 'Admin BookCycle'}',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 20),
                GridView.count(
                  shrinkWrap: true,
                  crossAxisCount: 2,
                  childAspectRatio: 1.5,
                  children: [
                    _StatCard(
                      title: 'Livres échangés',
                      value: stats['totalExchanges']?.toString() ?? '0',
                      icon: Icons.book,
                    ),
                    _StatCard(
                      title: 'Utilisateurs actifs',
                      value: stats['activeUsers']?.toString() ?? '0',
                      icon: Icons.people,
                    ),
                    _StatCard(
                      title: 'Nouveaux livres',
                      value: stats['newBooksThisWeek']?.toString() ?? '0',
                      icon: Icons.library_add,
                    ),
                    _StatCard(
                      title: 'Litiges ouverts',
                      value: stats['openDisputes']?.toString() ?? '0',
                      icon: Icons.warning,
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 30, color: Theme.of(context).primaryColor),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            Text(title, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:bookcycle/admin/widgets/admin_drawer.dart';
import 'package:bookcycle/admin/widgets/stats_card.dart';
import 'package:bookcycle/admin/services/admin_service.dart';

class AdminDashboard extends StatefulWidget {
  @override
  _AdminDashboardState createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final AdminService _adminService = AdminService();
  Map<String, dynamic> _stats = {};

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final stats = await _adminService.getStats();
    setState(() {
      _stats = stats;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tableau de bord administrateur'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      drawer: AdminDrawer(),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Aperçu général',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              childAspectRatio: 1.5,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: [
                StatsCard(
                  title: 'Utilisateurs',
                  value: _stats['totalUsers']?.toString() ?? '0',
                  icon: Icons.people,
                  color: Colors.blue,
                ),
                StatsCard(
                  title: 'Livres',
                  value: _stats['totalBooks']?.toString() ?? '0',
                  icon: Icons.book,
                  color: Colors.green,
                ),
                StatsCard(
                  title: 'Enchères actives',
                  value: _stats['activeAuctions']?.toString() ?? '0',
                  icon: Icons.gavel,
                  color: Colors.orange,
                ),
                StatsCard(
                  title: 'Transactions',
                  value: _stats['totalTransactions']?.toString() ?? '0',
                  icon: Icons.attach_money,
                  color: Colors.purple,
                ),
              ],
            ),
            SizedBox(height: 24),
            Text(
              'Activité récente',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      ListTile(
                        leading: Icon(Icons.person_add),
                        title: Text('Nouvel utilisateur inscrit'),
                        subtitle: Text('Il y a 2 heures'),
                      ),
                      Divider(),
                      ListTile(
                        leading: Icon(Icons.book),
                        title: Text('Nouveau livre ajouté'),
                        subtitle: Text('Il y a 4 heures'),
                      ),
                      Divider(),
                      ListTile(
                        leading: Icon(Icons.gavel),
                        title: Text('Enchère terminée'),
                        subtitle: Text('Il y a 6 heures'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:syncfusion_flutter_core/theme.dart';
import 'gestion_user.dart';
import 'gestion_litige.dart';
import 'stats_analyse.dart';

class AdminAccountPage extends StatelessWidget {
  const AdminAccountPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final statsRef = FirebaseFirestore.instance.collection('stats').doc('platform');

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Tableau de Bord BookCycle',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => FirebaseAuth.instance.signOut(),
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                color: Colors.deepPurple,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.white,
                    child: Text(
                      user?.email?[0].toUpperCase() ?? 'A',
                      style: const TextStyle(
                        color: Colors.deepPurple,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    user?.email ?? 'Admin BookCycle',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.dashboard, color: Colors.deepPurple),
              title: const Text('Tableau de bord'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.people, color: Colors.deepPurple),
              title: const Text('Gestion des membres'),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const UserManagementPage()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.warning, color: Colors.deepPurple),
              title: const Text('Gestion des litiges'),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const DisputePage()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.analytics, color: Colors.deepPurple),
              title: const Text('Analytics & Statistiques'),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const StatsAnalysisPage()));
              },
            ),
          ],
        ),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: statsRef.snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final stats = snapshot.data!.data() as Map<String, dynamic>? ?? {};

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Aperçu de la plateforme',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                GridView.count(
                  shrinkWrap: true,
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.2,
                  children: [
                    _StatCard(
                      title: 'Livres échangés',
                      value: stats['totalExchanges']?.toString() ?? '0',
                      icon: Icons.book,
                      color: Colors.blue,
                    ),
                    _StatCard(
                      title: 'Utilisateurs actifs',
                      value: stats['activeUsers']?.toString() ?? '0',
                      icon: Icons.people,
                      color: Colors.green,
                    ),
                    _StatCard(
                      title: 'Nouveaux livres',
                      value: stats['newBooksThisWeek']?.toString() ?? '0',
                      icon: Icons.library_add,
                      color: Colors.orange,
                    ),
                    _StatCard(
                      title: 'Litiges ouverts',
                      value: stats['openDisputes']?.toString() ?? '0',
                      icon: Icons.warning,
                      color: Colors.red,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Text('Activité récente',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                Expanded(
                  child: _buildRecentActivityChart(),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildRecentActivityChart() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('exchanges')
          .orderBy('createdAt', descending: true)
          .limit(7)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final exchanges = snapshot.data!.docs;
        final data = exchanges.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return {'day': DateFormat('E').format(data['createdAt'].toDate()), 'exchanges': 1};
        }).toList();

        // Compter les échanges par jour
        final Map<String, int> dayCounts = {};
        for (var item in data) {
          final day = item['day'] as String;
          dayCounts[day] = (dayCounts[day] ?? 0) + 1;
        }

        final chartData = dayCounts.entries.map((e) => ChartData(e.key, e.value.toDouble())).toList();

        return SfCartesianChart(
          margin: const EdgeInsets.all(0),
          plotAreaBorderWidth: 0,
          primaryXAxis: CategoryAxis(
            labelRotation: -45,
            majorGridLines: const MajorGridLines(width: 0),
          ),
          primaryYAxis: NumericAxis(
            majorGridLines: const MajorGridLines(width: 0),
            majorTickLines: const MajorTickLines(size: 0),
          ),
          series: <CartesianSeries>[ // Changé ici: utilisation de CartesianSeries au lieu de ChartSeries
            ColumnSeries<ChartData, String>(
              dataSource: chartData,
              xValueMapper: (ChartData data, _) => data.x,
              yValueMapper: (ChartData data, _) => data.y,
              color: Colors.deepPurple,
              borderRadius: BorderRadius.circular(5),
              width: 0.6,
            )
          ],
        );
      },
    );
  }
}

class ChartData {
  final String x;
  final double y;

  ChartData(this.x, this.y);
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 24, color: color),
            ),
            const SizedBox(height: 12),
            Text(value,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(title,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
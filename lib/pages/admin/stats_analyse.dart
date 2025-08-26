import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:intl/intl.dart';

class StatsAnalysisPage extends StatefulWidget {
  const StatsAnalysisPage({super.key});

  @override
  State<StatsAnalysisPage> createState() => _StatsAnalysisPageState();
}

class _StatsAnalysisPageState extends State<StatsAnalysisPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  int _selectedTab = 0;
  final DateFormat _dateFormat = DateFormat('dd/MM');

  @override
  Widget build(BuildContext context) {
    if (FirebaseAuth.instance.currentUser?.email != 'admin@gmail.com') {
      return Scaffold(
        appBar: AppBar(title: const Text('Accès refusé')),
        body: const Center(
          child: Text('Accès réservé à l\'administrateur'),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics BookCycle'),
      ),
      body: Column(
        children: [
          TabBar(
            onTap: (index) => setState(() => _selectedTab = index),
            tabs: const [
              Tab(text: 'Échanges'),
              Tab(text: 'Utilisateurs'),
              Tab(text: 'Livres'),
            ],
          ),
          Expanded(
            child: IndexedStack(
              index: _selectedTab,
              children: [
                _buildExchangeStats(),
                _buildUserStats(),
                _buildBookStats(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ... (le reste du code reste inchangé jusqu'à _buildExchangeStats)

  Widget _buildExchangeStats() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('exchanges')
          .orderBy('createdAt', descending: true)
          .limit(100)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        final exchangesByDay = <String, int>{};
        final now = DateTime.now();

        for (int i = 6; i >= 0; i--) {
          final date = now.subtract(Duration(days: i));
          exchangesByDay[_dateFormat.format(date)] = 0;
        }

        for (final doc in snapshot.data!.docs) {
          final date = (doc['createdAt'] as Timestamp).toDate();
          final dateStr = _dateFormat.format(date);
          if (exchangesByDay.containsKey(dateStr)) {
            exchangesByDay[dateStr] = exchangesByDay[dateStr]! + 1;
          }
        }

        final successfulExchanges = snapshot.data!.docs.where((e) => e['status'] == 'completed').length;
        final totalExchanges = snapshot.data!.docs.length;

        return SingleChildScrollView(
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('Performance des échanges',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              SizedBox(
                height: 300,
                child: SfCartesianChart(
                  primaryXAxis: CategoryAxis(),
                  series: <ColumnSeries<MapEntry<String, int>, String>>[ // Changé ici
                    ColumnSeries<MapEntry<String, int>, String>(
                      dataSource: exchangesByDay.entries.toList(),
                      xValueMapper: (entry, _) => entry.key,
                      yValueMapper: (entry, _) => entry.value,
                      color: Colors.blue,
                    )
                  ],
                ),
              ),
              _buildStatTile('Total échanges', totalExchanges.toString()),
              _buildStatTile('Échanges réussis', '$successfulExchanges (${(successfulExchanges/totalExchanges*100).toStringAsFixed(1)}%)'),
              _buildStatTile('Taux de réussite', '${(successfulExchanges/totalExchanges*100).toStringAsFixed(1)}%'),
            ],
          ),
        );
      },
    );
  }

  Widget _buildUserStats() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        final users = snapshot.data!.docs;
        final activeUsers = users.where((u) => u['isActive'] == true).length;
        final newThisWeek = users.where((u) {
          final joinDate = (u['joinDate'] as Timestamp).toDate();
          return joinDate.isAfter(DateTime.now().subtract(const Duration(days: 7)));
        }).length;

        final booksPerUser = <int>[];
        for (final user in users) {
          booksPerUser.add(user['sharedBooksCount'] ?? 0);
        }
        booksPerUser.sort();
        final medianBooks = booksPerUser.isEmpty ? 0 : booksPerUser[booksPerUser.length ~/ 2];

        return SingleChildScrollView(
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('Statistiques utilisateurs',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              SizedBox(
                height: 200,
                child: SfCartesianChart(
                  primaryXAxis: CategoryAxis(),
                  series: <BarSeries<MapEntry<String, int>, String>>[ // Changé ici
                    BarSeries<MapEntry<String, int>, String>(
                      dataSource: [
                        MapEntry('Actifs', activeUsers),
                        MapEntry('Nouveaux', newThisWeek),
                      ],
                      xValueMapper: (entry, _) => entry.key,
                      yValueMapper: (entry, _) => entry.value,
                      color: Colors.green,
                    )
                  ],
                ),
              ),
              _buildStatTile('Total utilisateurs', users.length.toString()),
              _buildStatTile('Utilisateurs actifs', '$activeUsers (${(activeUsers/users.length*100).toStringAsFixed(1)}%)'),
              _buildStatTile('Nouveaux cette semaine', newThisWeek.toString()),
              _buildStatTile('Moyenne livres partagés', medianBooks.toString()),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBookStats() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('books').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        final books = snapshot.data!.docs;
        final availableBooks = books.where((b) => b['status'] == 'available').length;
        final popularCategories = <String, int>{};

        for (final book in books) {
          final category = book['category'] ?? 'Non catégorisé';
          popularCategories[category] = (popularCategories[category] ?? 0) + 1;
        }

        final sortedCategories = popularCategories.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        final topCategories = sortedCategories.take(3).toList();

        // Correction pour le fold
        final totalExchanges = books.fold<int>(0, (sum, book) => sum + ((book['exchangeCount'] as num?)?.toInt() ?? 0));
        final avgExchanges = books.isEmpty ? 0 : totalExchanges / books.length;

        return SingleChildScrollView(
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('Statistiques livres',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              SizedBox(
                height: 200,
                child: SfCircularChart(
                  series: <PieSeries<MapEntry<String, int>, String>>[
                    PieSeries<MapEntry<String, int>, String>(
                      dataSource: topCategories,
                      xValueMapper: (entry, _) => entry.key,
                      yValueMapper: (entry, _) => entry.value,
                      dataLabelSettings: const DataLabelSettings(isVisible: true),
                    )
                  ],
                ),
              ),
              _buildStatTile('Total livres', books.length.toString()),
              _buildStatTile('Disponibles', '$availableBooks (${(availableBooks/books.length*100).toStringAsFixed(1)}%)'),
              ...topCategories.map((e) =>
                  _buildStatTile('Catégorie ${e.key}', e.value.toString())),
              _buildStatTile('Moyenne d\'échanges', avgExchanges.toStringAsFixed(1)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatTile(String title, String value) {
    return ListTile(
      title: Text(title),
      trailing: Text(value,
          style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }
}
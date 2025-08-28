import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:intl/intl.dart';

class AdminReports extends StatefulWidget {
  const AdminReports({super.key});

  @override
  State<AdminReports> createState() => _AdminReportsState();
}

class _AdminReportsState extends State<AdminReports> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  DateTimeRange _dateRange = DateTimeRange(
    start: DateTime.now().subtract(const Duration(days: 30)),
    end: DateTime.now(),
  );
  String _reportType = 'ventes';

  final List<String> _reportTypes = [
    'ventes',
    'utilisateurs',
    'enchères',
    'livres'
  ];

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _dateRange,
    );

    if (picked != null) {
      setState(() => _dateRange = picked);
    }
  }

  Widget _buildSalesReport() {
    return FutureBuilder<QuerySnapshot>(
      future: _firestore
          .collection('transactions')
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(_dateRange.start))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(_dateRange.end))
          .get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final transactions = snapshot.data!.docs;
        final totalSales = transactions.fold<double>(0, (sum, doc) {
          final data = doc.data() as Map<String, dynamic>;
          return sum + (data['montant'] ?? 0.0);
        });

        final dailySales = _groupSalesByDay(transactions);

        return SingleChildScrollView(
          child: Column(
            children: [
              _buildSummaryCard('Ventes totales', '${totalSales.toStringAsFixed(2)} fcfa'),
              const SizedBox(height: 20),
              SizedBox(
                height: 300,
                child: SfCartesianChart(
                  title: const ChartTitle(text: 'Ventes par jour'),
                  primaryXAxis: CategoryAxis(),
                  series: <CartesianSeries>[
                    ColumnSeries<Map<String, dynamic>, String>(
                      dataSource: dailySales,
                      xValueMapper: (data, _) => data['day'],
                      yValueMapper: (data, _) => data['amount'],
                      dataLabelSettings: const DataLabelSettings(isVisible: true),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  List<Map<String, dynamic>> _groupSalesByDay(List<QueryDocumentSnapshot> transactions) {
    final Map<String, double> dailyTotals = {};

    for (final transaction in transactions) {
      final data = transaction.data() as Map<String, dynamic>;
      final date = (data['date'] as Timestamp).toDate();
      final dayKey = DateFormat('dd/MM').format(date);
      final amount = data['montant'] ?? 0.0;

      dailyTotals.update(dayKey, (value) => value + amount, ifAbsent: () => amount);
    }

    return dailyTotals.entries.map((entry) {
      return {'day': entry.key, 'amount': entry.value};
    }).toList();
  }

  Widget _buildUsersReport() {
    return FutureBuilder<QuerySnapshot>(
      future: _firestore
          .collection('users')
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(_dateRange.start))
          .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(_dateRange.end))
          .get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final users = snapshot.data!.docs;
        final userStats = _calculateUserStats(users);

        return SingleChildScrollView(
          child: Column(
            children: [
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  _buildSummaryCard('Nouveaux utilisateurs', users.length.toString()),
                  _buildSummaryCard('Utilisateurs actifs', userStats['active'].toString()),
                  _buildSummaryCard('Administrateurs', userStats['admins'].toString()),
                ],
              ),
              const SizedBox(height: 20),
              _buildUserRegistrationChart(users),
            ],
          ),
        );
      },
    );
  }

  Map<String, int> _calculateUserStats(List<QueryDocumentSnapshot> users) {
    int activeUsers = 0;
    int admins = 0;

    for (final user in users) {
      final data = user.data() as Map<String, dynamic>;
      if (data['isActive'] == true) activeUsers++;
      if (data['role'] == 'admin') admins++;
    }

    return {'active': activeUsers, 'admins': admins};
  }

  Widget _buildUserRegistrationChart(List<QueryDocumentSnapshot> users) {
    final monthlyRegistrations = _groupRegistrationsByMonth(users);

    return SingleChildScrollView(
      child: SizedBox(
        height: 300,
        child: SfCartesianChart(
          title: const ChartTitle(text: 'Inscriptions par mois'),
          primaryXAxis: CategoryAxis(),
          series: <CartesianSeries>[
            LineSeries<Map<String, dynamic>, String>(
              dataSource: monthlyRegistrations,
              xValueMapper: (data, _) => data['month'],
              yValueMapper: (data, _) => data['count'],
              markerSettings: const MarkerSettings(isVisible: true),
              dataLabelSettings: const DataLabelSettings(isVisible: true),
            ),
          ],
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _groupRegistrationsByMonth(List<QueryDocumentSnapshot> users) {
    final Map<String, int> monthlyCounts = {};

    for (final user in users) {
      final data = user.data() as Map<String, dynamic>;
      final date = (data['createdAt'] as Timestamp).toDate();
      final monthKey = DateFormat('MMM yyyy').format(date);

      monthlyCounts.update(monthKey, (value) => value + 1, ifAbsent: () => 1);
    }

    return monthlyCounts.entries.map((entry) {
      return {'month': entry.key, 'count': entry.value};
    }).toList();
  }

  Widget _buildSummaryCard(String title, String value) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(title, style: const TextStyle(fontSize: 14, color: Colors.grey)),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentReport() {
    switch (_reportType) {
      case 'ventes':
        return _buildSalesReport();
      case 'utilisateurs':
        return _buildUsersReport();
      case 'enchères':
        return _buildAuctionsReport();
      case 'livres':
        return _buildBooksReport();
      default:
        return const Center(child: Text('Rapport non disponible'));
    }
  }

  Widget _buildAuctionsReport() {
    return FutureBuilder<QuerySnapshot>(
      future: _firestore.collection('encheres').get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final auctions = snapshot.data!.docs;
        final auctionStats = _calculateAuctionStats(auctions);

        return SingleChildScrollView(
          child: Column(
            children: [
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  _buildSummaryCard('Enchères totales', auctions.length.toString()),
                  _buildSummaryCard('Enchères actives', auctionStats['active'].toString()),
                  _buildSummaryCard('Enchères terminées', auctionStats['completed'].toString()),
                  _buildSummaryCard('Enchères annulées', auctionStats['cancelled'].toString()),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Map<String, int> _calculateAuctionStats(List<QueryDocumentSnapshot> auctions) {
    int active = 0;
    int completed = 0;
    int cancelled = 0;

    for (final auction in auctions) {
      final data = auction.data() as Map<String, dynamic>;
      final status = data['status']?.toString().toLowerCase() ?? '';

      if (status.contains('annul')) {
        cancelled++;
      } else if (status.contains('termine') || status.contains('complete')) {
        completed++;
      } else {
        active++;
      }
    }

    return {'active': active, 'completed': completed, 'cancelled': cancelled};
  }

  Widget _buildBooksReport() {
    return FutureBuilder<QuerySnapshot>(
      future: _firestore.collection('books').get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final books = snapshot.data!.docs;
        final bookStats = _calculateBookStats(books);

        return SingleChildScrollView(
          child: Column(
            children: [
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  _buildSummaryCard('Livres total', books.length.toString()),
                  _buildSummaryCard('Livres disponibles', bookStats['available'].toString()),
                  _buildSummaryCard('Livres vendus', bookStats['sold'].toString()),
                  _buildSummaryCard('Livres réservés', bookStats['reserved'].toString()),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Map<String, int> _calculateBookStats(List<QueryDocumentSnapshot> books) {
    int available = 0;
    int sold = 0;
    int reserved = 0;

    for (final book in books) {
      final data = book.data() as Map<String, dynamic>;
      final status = data['status']?.toString().toLowerCase() ?? '';

      if (status.contains('vendu')) {
        sold++;
      } else if (status.contains('reserv')) {
        reserved++;
      } else {
        available++;
      }
    }

    return {'available': available, 'sold': sold, 'reserved': reserved};
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Rapports et Statistiques',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
      
            // Contrôles de rapport
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _reportType,
                    items: _reportTypes.map((type) {
                      return DropdownMenuItem(
                        value: type,
                        child: Text(type.capitalize()),
                      );
                    }).toList(),
                    onChanged: (value) => setState(() => _reportType = value!),
                    decoration: const InputDecoration(
                      labelText: 'Type de rapport',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _selectDateRange,
                  child: const Text('Choisir la période'),
                ),
              ],
            ),
            const SizedBox(height: 16),
      
            Text(
              'Période: ${DateFormat('dd/MM/yyyy').format(_dateRange.start)} - ${DateFormat('dd/MM/yyyy').format(_dateRange.end)}',
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 16),
      
            // Contenu du rapport
            Expanded(
              child: SingleChildScrollView(
                child: _buildCurrentReport(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
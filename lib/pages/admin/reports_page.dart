import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../composants/common_components.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  DateTimeRange _dateRange = DateTimeRange(
    start: DateTime.now().subtract(const Duration(days: 30)),
    end: DateTime.now(),
  );
  String _selectedReportType = 'users';
  bool _isLoading = false;

  final Map<String, String> _reportTypes = {
    'users': 'Utilisateurs',
    'books': 'Livres',
    'exchanges': 'Échanges',
    'reports': 'Signalements',
  };

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Rapports et statistiques', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          _buildFilters(),
          const SizedBox(height: 24),
          _isLoading ? const Center(child: LoadingIndicator()) : _buildReportContent(),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            DropdownButton<String>(
              value: _selectedReportType,
              items: _reportTypes.entries.map((entry) =>
                  DropdownMenuItem(value: entry.key, child: Text(entry.value))
              ).toList(),
              onChanged: (value) => setState(() => _selectedReportType = value!),
            ),
            const SizedBox(width: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.calendar_today),
              label: Text('${DateFormat('dd/MM/yy').format(_dateRange.start)} - ${DateFormat('dd/MM/yy').format(_dateRange.end)}'),
              onPressed: _selectDateRange,
            ),
            const SizedBox(width: 16),
            ElevatedButton(
              onPressed: _generateReport,
              child: const Text('Générer le rapport'),
            ),
          ],
        ),
      ),
    );
  }

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

  void _generateReport() {
    setState(() => _isLoading = true);
    Future.delayed(const Duration(seconds: 2), () => setState(() => _isLoading = false));
  }

  Widget _buildReportContent() {
    switch (_selectedReportType) {
      case 'users':
        return _buildUserReport();
      case 'books':
        return _buildBookReport();
      case 'exchanges':
        return _buildExchangeReport();
      case 'reports':
        return _buildReportsReport();
      default:
        return const Center(child: Text('Sélectionnez un type de rapport'));
    }
  }

  Widget _buildUserReport() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const LoadingIndicator();

        final users = snapshot.data!.docs;
        final newUsers = users.where((user) {
          final date = (user['createdAt'] as Timestamp).toDate();
          return date.isAfter(_dateRange.start) && date.isBefore(_dateRange.end);
        }).length;

        return Column(
          children: [
            _buildStatCard('Nouveaux utilisateurs', newUsers.toString(), Icons.person_add),
            const SizedBox(height: 24),
            Expanded(child: _buildUsersTable(users)),
          ],
        );
      },
    );
  }

  Widget _buildBookReport() {
    return const Center(child: Text('Rapport livres - En développement'));
  }

  Widget _buildExchangeReport() {
    return const Center(child: Text('Rapport échanges - En développement'));
  }

  Widget _buildReportsReport() {
    return const Center(child: Text('Rapport signalements - En développement'));
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(children: [
          Icon(icon, size: 40, color: AppColors.primaryBlue),
          const SizedBox(width: 16),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            Text(title, style: TextStyle(color: Colors.grey[600])),
          ]),
        ]),
      ),
    );
  }

  Widget _buildUsersTable(List<QueryDocumentSnapshot> users) {
    return DataTable(
      columns: const [
        DataColumn(label: Text('Nom')),
        DataColumn(label: Text('Email')),
        DataColumn(label: Text('Inscription')),
        DataColumn(label: Text('Statut')),
      ],
      rows: users.map((user) {
        final data = user.data() as Map<String, dynamic>;
        return DataRow(cells: [
          DataCell(Text(data['name'] ?? '')),
          DataCell(Text(data['email'] ?? '')),
          DataCell(Text(DateFormat('dd/MM/yy').format((data['createdAt'] as Timestamp).toDate()))),
          DataCell(Chip(
            label: Text(data['isActive'] == true ? 'Actif' : 'Inactif', style: const TextStyle(color: Colors.white)),
            backgroundColor: data['isActive'] == true ? Colors.green : Colors.grey,
          )),
        ]);
      }).toList(),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class DisputePage extends StatefulWidget {
  const DisputePage({super.key});

  @override
  State<DisputePage> createState() => _DisputePageState();
}

class _DisputePageState extends State<DisputePage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  int _selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des litiges',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          TabBar(
            onTap: (index) => setState(() => _selectedTab = index),
            labelColor: Colors.deepPurple,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.deepPurple,
            tabs: const [
              Tab(text: 'Litiges ouverts'),
              Tab(text: 'Litiges résolus'),
              Tab(text: 'Statistiques'),
            ],
          ),
          Expanded(
            child: IndexedStack(
              index: _selectedTab,
              children: [
                _buildOpenDisputes(),
                _buildResolvedDisputes(),
                _buildDisputeStats(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOpenDisputes() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('disputes')
          .where('resolved', isEqualTo: false)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Erreur de chargement'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('Aucun litige ouvert'));
        }

        return ListView.builder(
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final dispute = snapshot.data!.docs[index];
            final data = dispute.data() as Map<String, dynamic>;

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ExpansionTile(
                leading: Icon(Icons.warning, color: Colors.orange[700]),
                title: Text('Litige #${dispute.id.substring(0, 5)}',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('Livre: ${data['bookTitle']}'),
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.category, size: 16, color: Colors.grey[600]),
                            const SizedBox(width: 8),
                            Text('Type: ${data['type']}'),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                            const SizedBox(width: 8),
                            Text('Créé le: ${DateFormat('dd/MM/yyyy').format(data['createdAt'].toDate())}'),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Text('Description:', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(data['description']),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            OutlinedButton(
                              onPressed: () => _resolveDispute(dispute.id, false),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red,
                                side: const BorderSide(color: Colors.red),
                              ),
                              child: const Text('Rejeter'),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton(
                              onPressed: () => _resolveDispute(dispute.id, true),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.deepPurple,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Résoudre'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildResolvedDisputes() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('disputes')
          .where('resolved', isEqualTo: true)
          .orderBy('resolvedAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Erreur de chargement'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('Aucun litige résolu'));
        }

        return ListView.builder(
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final dispute = snapshot.data!.docs[index];
            final data = dispute.data() as Map<String, dynamic>;

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: Icon(
                  data['resolutionStatus'] == 'resolved' ? Icons.check_circle : Icons.cancel,
                  color: data['resolutionStatus'] == 'resolved' ? Colors.green : Colors.red,
                ),
                title: Text('Litige #${dispute.id.substring(0, 5)}',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Livre: ${data['bookTitle']}'),
                    Text('Résolu le: ${DateFormat('dd/MM/yyyy').format(data['resolvedAt'].toDate())}'),
                  ],
                ),
                trailing: Chip(
                  label: Text(
                    data['resolutionStatus'] == 'resolved' ? 'Résolu' : 'Rejeté',
                    style: const TextStyle(color: Colors.white),
                  ),
                  backgroundColor: data['resolutionStatus'] == 'resolved' ? Colors.green : Colors.red,
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDisputeStats() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('disputes').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        final disputes = snapshot.data!.docs;
        final openDisputes = disputes.where((d) => !d['resolved']).length;
        final resolvedDisputes = disputes.where((d) => d['resolved'] && d['resolutionStatus'] == 'resolved').length;
        final rejectedDisputes = disputes.where((d) => d['resolved'] && d['resolutionStatus'] == 'rejected').length;

        final typeCounts = <String, int>{};
        for (final dispute in disputes) {
          final type = dispute['type'] ?? 'Non spécifié';
          typeCounts[type] = (typeCounts[type] ?? 0) + 1;
        }

        final chartData = typeCounts.entries.map((e) => ChartData(e.key, e.value.toDouble())).toList();

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Statistiques des litiges',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      title: 'Ouverts',
                      value: openDisputes.toString(),
                      color: Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _StatCard(
                      title: 'Résolus',
                      value: resolvedDisputes.toString(),
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _StatCard(
                      title: 'Rejetés',
                      value: rejectedDisputes.toString(),
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text('Répartition par type',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              SizedBox(
                height: 300,
                child: SfCircularChart(
                  legend: const Legend(
                    isVisible: true,
                    position: LegendPosition.bottom,
                    overflowMode: LegendItemOverflowMode.wrap,
                  ),
                  series: <CircularSeries>[
                    PieSeries<ChartData, String>(
                      dataSource: chartData,
                      xValueMapper: (ChartData data, _) => data.x,
                      yValueMapper: (ChartData data, _) => data.y,
                      dataLabelSettings: const DataLabelSettings(isVisible: true),
                    )
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _resolveDispute(String disputeId, bool resolved) async {
    await _firestore.collection('disputes').doc(disputeId).update({
      'resolved': true,
      'resolutionStatus': resolved ? 'resolved' : 'rejected',
      'resolvedAt': DateTime.now(),
    });
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
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
          children: [
            Text(value,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 8),
            Text(title,
                style: const TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
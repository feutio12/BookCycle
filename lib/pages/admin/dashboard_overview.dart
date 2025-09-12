import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import '../../composants/common_components.dart';
import 'user_management_page.dart'; // Ajouté
import 'book_management_page.dart'; // Ajouté
import 'auction_management_page.dart'; // Ajouté

class DashboardOverview extends StatelessWidget {
  const DashboardOverview({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Tableau de bord', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          _buildStatisticsRow(),
          const SizedBox(height: 32),
          Expanded(child: _buildActivitySection(context)), // Passer le contexte
        ],
      ),
    );
  }

  Widget _buildStatisticsRow() {
    return StreamBuilder(
      stream: FirebaseFirestore.instance.collection('stats').doc('overview').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingIndicator();
        }

        final stats = snapshot.data?.data() ?? {};
        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            _buildStatCard('Utilisateurs', Icons.people, stats['totalUsers'] ?? 0, AppColors.primaryBlue),
            _buildStatCard('Livres', Icons.book, stats['totalBooks'] ?? 0, AppColors.accentGreen),
            _buildStatCard('Échanges', Icons.swap_horiz, stats['totalExchanges'] ?? 0, AppColors.warningOrange),
            _buildStatCard('Enchères actives', Icons.gavel, stats['activeAuctions'] ?? 0, Colors.purple),
            _buildStatCard('Signalements', Icons.warning, stats['reports'] ?? 0, AppColors.errorRed),
            _buildStatCard('Revenus', Icons.attach_money, stats['revenue'] ?? 0, Colors.teal),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(String title, IconData icon, int count, Color color) {
    return Container(
      width: 200,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 24, color: color),
              ),
              const SizedBox(height: 16),
              Text(
                count.toString(),
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActivitySection(BuildContext context) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 2, child: _buildRecentUsers(context)),
            const SizedBox(width: 24),
            Expanded(flex: 3, child: _buildBooksChart()),
          ],
        ),
        const SizedBox(height: 24),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 2, child: _buildRecentBooks(context)),
            const SizedBox(width: 24),
            Expanded(flex: 2, child: _buildRecentAuctions(context)),
          ],
        ),
      ],
    );
  }

  Widget _buildRecentUsers(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('Utilisateurs récents', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.arrow_forward, size: 20),
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => UserManagementPage())),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('users')
                    .orderBy('createdAt', descending: true).limit(5).snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) return const LoadingIndicator();
                  if (snapshot.hasError) return ErrorMessage(message: 'Erreur: ${snapshot.error}');

                  return ListView.builder(
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (context, index) {
                      final user = snapshot.data!.docs[index];
                      final data = user.data() as Map<String, dynamic>;
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppColors.primaryBlue,
                          child: Text(data['name']?[0] ?? 'U', style: const TextStyle(color: Colors.white)),
                        ),
                        title: Text(data['name'] ?? 'Utilisateur', style: const TextStyle(fontWeight: FontWeight.w500)),
                        subtitle: Text(data['email'] ?? ''),
                        trailing: Text(DateFormat('dd/MM').format((data['createdAt'] as Timestamp).toDate())),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBooksChart() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Statistiques des livres', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('books').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const LoadingIndicator();
                if (snapshot.hasError) return ErrorMessage(message: 'Erreur: ${snapshot.error}');

                final books = snapshot.data!.docs;
                final statusCount = {
                  'available': 0,
                  'pending': 0,
                  'exchanged': 0,
                  'reported': 0,
                };

                for (var book in books) {
                  final data = book.data() as Map<String, dynamic>;
                  final status = data['status'] ?? 'available';
                  if (statusCount.containsKey(status)) {
                    statusCount[status] = statusCount[status]! + 1;
                  }
                }

                final chartData = [
                  ChartData('Disponibles', statusCount['available']!, Colors.green),
                  ChartData('En attente', statusCount['pending']!, Colors.orange),
                  ChartData('Échangés', statusCount['exchanged']!, Colors.blue),
                  ChartData('Signalés', statusCount['reported']!, Colors.red),
                ];

                return SizedBox(
                  height: 250,
                  child: SfCircularChart(
                    legend: Legend(isVisible: true, position: LegendPosition.bottom),
                    series: <CircularSeries>[
                      DoughnutSeries<ChartData, String>(
                        dataSource: chartData,
                        xValueMapper: (ChartData data, _) => data.x,
                        yValueMapper: (ChartData data, _) => data.y,
                        pointColorMapper: (ChartData data, _) => data.color,
                        dataLabelSettings: const DataLabelSettings(isVisible: true),
                      )
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentBooks(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('Livres récents', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.arrow_forward, size: 20),
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => BookManagementPage())),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('books')
                    .orderBy('createdAt', descending: true).limit(5).snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) return const LoadingIndicator();
                  if (snapshot.hasError) return ErrorMessage(message: 'Erreur: ${snapshot.error}');

                  return ListView.builder(
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (context, index) {
                      final book = snapshot.data!.docs[index];
                      final data = book.data() as Map<String, dynamic>;
                      return ListTile(
                        leading: const Icon(Icons.book, color: AppColors.primaryBlue),
                        title: Text(data['title'] ?? 'Sans titre', style: const TextStyle(fontWeight: FontWeight.w500)),
                        subtitle: Text(data['author'] ?? 'Auteur inconnu'),
                        trailing: _buildStatusChip(data['status']),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentAuctions(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('Enchères récentes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.arrow_forward, size: 20),
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AuctionManagementPage())),
                ),
              ],
            ),
            const SizedBox(height: 16),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('encheres')
                  .orderBy('dateCreation', descending: true).limit(5).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const LoadingIndicator();
                if (snapshot.hasError) return ErrorMessage(message: 'Erreur: ${snapshot.error}');

                return ListView.builder(
                  shrinkWrap: true,
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final auction = snapshot.data!.docs[index];
                    final data = auction.data() as Map<String, dynamic>;
                    return ListTile(
                      leading: const Icon(Icons.gavel, color: Colors.purple),
                      title: Text(data['titre'] ?? 'Sans titre', style: const TextStyle(fontWeight: FontWeight.w500)),
                      subtitle: Text('${data['prixActuel'] ?? 0} €'),
                      trailing: _buildAuctionStatusChip(data['statut']),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String? status) {
    final color = status == 'available' ? Colors.green :
    status == 'pending' ? Colors.orange :
    status == 'exchanged' ? Colors.blue :
    status == 'reported' ? Colors.red : Colors.grey;

    return Chip(
      label: Text(
        status == 'available' ? 'Disponible' :
        status == 'pending' ? 'En attente' :
        status == 'exchanged' ? 'Échangé' :
        status == 'reported' ? 'Signalé' : 'Inconnu',
        style: const TextStyle(color: Colors.white, fontSize: 10),
      ),
      backgroundColor: color,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    );
  }

  Widget _buildAuctionStatusChip(String? status) {
    final color = status == 'active' ? Colors.green :
    status == 'ended' ? Colors.blue :
    status == 'cancelled' ? Colors.red : Colors.grey;

    return Chip(
      label: Text(
        status == 'active' ? 'Active' :
        status == 'ended' ? 'Terminée' :
        status == 'cancelled' ? 'Annulée' : 'Inconnue',
        style: const TextStyle(color: Colors.white, fontSize: 10),
      ),
      backgroundColor: color,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    );
  }
}

class ChartData {
  final String x;
  final int y;
  final Color color;

  ChartData(this.x, this.y, this.color);
}
// dashboard_screen.dart
import 'package:bookcycle/pages/admin/responsive.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

import '../book/book_list.dart';
import 'color_constants.dart';
import 'mini_information_card.dart';

class DashboardScreen extends StatefulWidget {
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  int totalBooks = 0;
  int totalUsers = 0;
  int monthlyExchanges = 0;
  double revenue = 0.0;

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    // Charger les statistiques depuis Firebase
    try {
      // Nombre total de livres
      var booksSnapshot = await _firestore.collection('books').get();
      setState(() => totalBooks = booksSnapshot.size);

      // Nombre total d'utilisateurs
      var usersSnapshot = await _firestore.collection('users').get();
      setState(() => totalUsers = usersSnapshot.size);

      // Échanges ce mois-ci (exemple)
      var now = DateTime.now();
      var firstDayOfMonth = DateTime(now.year, now.month, 1);
      var exchangesSnapshot = await _firestore
          .collection('exchanges')
          .where('date', isGreaterThanOrEqualTo: firstDayOfMonth)
          .get();
      setState(() => monthlyExchanges = exchangesSnapshot.size);

      // Revenus (exemple)
      setState(() => revenue = 2450.0);
    } catch (e) {
      print("Erreur lors du chargement des statistiques: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Tableau de bord",
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 8),
            Text(
              "Vue d'ensemble de votre plateforme",
              style: TextStyle(
                color: Palette.textSecondary,
              ),
            ),
            SizedBox(height: defaultPadding),
            MiniInformation(
              totalBooks: totalBooks,
              totalUsers: totalUsers,
              monthlyExchanges: monthlyExchanges,
              revenue: revenue,
            ),
            SizedBox(height: defaultPadding),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 5,
                  child: Column(
                    children: [
                      StatisticsChart(),
                      SizedBox(height: defaultPadding),
                      RecentActivities(),
                      SizedBox(height: defaultPadding),
                      RecentUsers(),
                    ],
                  ),
                ),
                if (!Responsive.isMobile(context))
                  SizedBox(width: defaultPadding),
                if (!Responsive.isMobile(context))
                  Expanded(
                    flex: 2,
                    child: Container(
                      padding: EdgeInsets.all(defaultPadding),
                      decoration: BoxDecoration(
                        color: secondaryColor,
                        borderRadius: BorderRadius.circular(defaultBorderRadius),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Actions rapides",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 16),
                          _buildQuickAction(
                              Icons.add_circle,
                              "Ajouter un livre",
                                  () {}
                          ),
                          _buildQuickAction(
                              Icons.people,
                              "Gérer les utilisateurs",
                                  () {}
                          ),
                          _buildQuickAction(
                              Icons.report,
                              "Voir les rapports",
                                  () {}
                          ),
                          _buildQuickAction(
                              Icons.settings,
                              "Paramètres",
                                  () {}
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAction(IconData icon, String text, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: greenColor),
      title: Text(text, style: TextStyle(color: Colors.white70)),
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
    );
  }
}

// Widgets temporaires (à implémenter)
class StatisticsChart extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(defaultPadding),
      decoration: BoxDecoration(
        color: secondaryColor,
        borderRadius: BorderRadius.circular(defaultBorderRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Statistiques",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 16),
          Container(
            height: 200,
            child: Center(
              child: Text(
                "Graphique des statistiques",
                style: TextStyle(color: Colors.white70),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class RecentActivities extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(defaultPadding),
      decoration: BoxDecoration(
        color: secondaryColor,
        borderRadius: BorderRadius.circular(defaultBorderRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Activités récentes",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 16),
          ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: 3,
            itemBuilder: (context, index) => ListTile(
              leading: CircleAvatar(
                backgroundColor: primaryColor.withOpacity(0.2),
                child: Icon(Icons.swap_horiz, color: primaryColor, size: 20),
              ),
              title: Text(
                "Échange #${1000 + index}",
                style: TextStyle(color: Colors.white),
              ),
              subtitle: Text(
                "Il y a ${index + 1} heures",
                style: TextStyle(color: Colors.white54),
              ),
              trailing: Chip(
                label: Text(
                  "Terminé",
                  style: TextStyle(fontSize: 12, color: Colors.white),
                ),
                backgroundColor: successColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class RecentUsers extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(defaultPadding),
      decoration: BoxDecoration(
        color: secondaryColor,
        borderRadius: BorderRadius.circular(defaultBorderRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Utilisateurs récents",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 16),
          ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: 3,
            itemBuilder: (context, index) => ListTile(
              leading: CircleAvatar(
                backgroundColor: primaryColor.withOpacity(0.2),
                child: Icon(Icons.person, color: primaryColor, size: 20),
              ),
              title: Text(
                "Utilisateur ${index + 1}",
                style: TextStyle(color: Colors.white),
              ),
              subtitle: Text(
                "user${index + 1}@example.com",
                style: TextStyle(color: Colors.white54),
              ),
              trailing: Text(
                "Hier",
                style: TextStyle(color: Colors.white54),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
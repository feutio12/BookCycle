import 'package:cloud_firestore/cloud_firestore.dart';

class AdminFirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Méthodes pour les utilisateurs
  Future<int?> getTotalUsers() async {
    final snapshot = await _firestore.collection('users').count().get();
    return snapshot.count;
  }

  Future<int?> getActiveUsers() async {
    final snapshot = await _firestore
        .collection('users')
        .where('isActive', isEqualTo: true)
        .count()
        .get();
    return snapshot.count;
  }

  // Méthodes pour les livres
  Future<int?> getTotalBooks() async {
    final snapshot = await _firestore.collection('books').count().get();
    return snapshot.count;
  }

  Future<int?> getAvailableBooks() async {
    final snapshot = await _firestore
        .collection('books')
        .where('status', isEqualTo: 'available')
        .count()
        .get();
    return snapshot.count;
  }

  // Méthodes pour les enchères
  Future<int?> getTotalAuctions() async {
    final snapshot = await _firestore.collection('auctions').count().get();
    return snapshot.count;
  }

  Future<int?> getActiveAuctions() async {
    final snapshot = await _firestore
        .collection('auctions')
        .where('status', isEqualTo: 'active')
        .count()
        .get();
    return snapshot.count;
  }

  // Méthodes pour les transactions
  Future<int?> getTotalTransactions() async {
    final snapshot = await _firestore.collection('transactions').count().get();
    return snapshot.count;
  }

  Future<double> getTotalRevenue() async {
    final snapshot = await _firestore.collection('transactions').get();
    double total = 0;
    for (var doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      total += (data['amount'] ?? 0).toDouble();
    }
    return total;
  }

  // Méthode pour générer des rapports
  Future<Map<String, dynamic>> generateReport(DateTime startDate, DateTime endDate) async {
    // Implémentation pour générer un rapport personnalisé
    return {
      'newUsers': 0,
      'booksAdded': 0,
      'auctionsCreated': 0,
      'transactionsCompleted': 0,
      'revenue': 0.0,
    };
  }
}
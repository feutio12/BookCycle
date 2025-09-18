import 'package:cloud_firestore/cloud_firestore.dart';

class AdminService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Récupérer les statistiques générales
  Future<Map<String, dynamic>> getStats() async {
    final totalUsers = (await _firestore.collection('users').count().get()).count;
    final totalBooks = (await _firestore.collection('books').count().get()).count;
    final activeAuctions = (await _firestore.collection('encheres')
        .where('status', isEqualTo: 'active').count().get()).count;
    final totalTransactions = (await _firestore.collection('transactions').count().get()).count;

    return {
      'totalUsers': totalUsers,
      'totalBooks': totalBooks,
      'activeAuctions': activeAuctions,
      'totalTransactions': totalTransactions,
    };
  }

  // Gestion des utilisateurs
  Stream<QuerySnapshot> getUsers() {
    return _firestore.collection('users').snapshots();
  }

  Future<void> updateUserStatus(String userId, bool isActive) async {
    await _firestore.collection('users').doc(userId).update({
      'isActive': isActive,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Gestion des livres
  Stream<QuerySnapshot> getBooks() {
    return _firestore.collection('books').snapshots();
  }

  Future<void> updateBookStatus(String bookId, String status) async {
    await _firestore.collection('books').doc(bookId).update({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Gestion des enchères
  Stream<QuerySnapshot> getAuctions() {
    return _firestore.collection('auctions').snapshots();
  }

  Future<void> cancelAuction(String auctionId) async {
    await _firestore.collection('auctions').doc(auctionId).update({
      'status': 'cancelled',
      'cancelledAt': FieldValue.serverTimestamp(),
    });
  }

  // Gestion des conversations
  Stream<QuerySnapshot> getChats() {
    return _firestore.collection('chats').snapshots();
  }

  Future<void> deleteChat(String chatId) async {
    await _firestore.collection('chats').doc(chatId).delete();
  }
}
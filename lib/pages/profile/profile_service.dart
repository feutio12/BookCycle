import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Récupérer les données utilisateur
  Future<Map<String, dynamic>?> getUserData(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      return doc.exists ? doc.data() : null;
    } catch (e) {
      throw Exception('Erreur lors de la récupération des données utilisateur: $e');
    }
  }

  // Créer un document utilisateur par défaut
  Future<void> createUserDocument(String userId, Map<String, dynamic> userData) async {
    try {
      await _firestore.collection('users').doc(userId).set(userData);
    } catch (e) {
      throw Exception('Erreur lors de la création du document utilisateur: $e');
    }
  }

  // Mettre à jour le profil utilisateur
  Future<void> updateUserProfile(String userId, String name, String bio) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'name': name,
        'bio': bio,
        'profileCompleted': true,
      });
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour du profil: $e');
    }
  }

  // Mettre à jour les préférences utilisateur
  Future<void> updateUserPreferences(
      String userId,
      bool notifications,
      bool emailUpdates,
      String privacy,
      String theme
      ) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'preferences': {
          'notifications': notifications,
          'emailUpdates': emailUpdates,
          'privacy': privacy,
          'theme': theme
        }
      });
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour des préférences: $e');
    }
  }

  // Compter le nombre de livres publiés par l'utilisateur
  Future<int> getUserBooksCount(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('books')
          .where('userId', isEqualTo: userId)
          .get();

      return querySnapshot.size;
    } catch (e) {
      throw Exception('Erreur lors du comptage des livres: $e');
    }
  }

  // Compter le nombre d'enchères de l'utilisateur
  Future<int> getUserAuctionsCount(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('auctions')
          .where('userId', isEqualTo: userId)
          .get();

      return querySnapshot.size;
    } catch (e) {
      throw Exception('Erreur lors du comptage des enchères: $e');
    }
  }

  // Récupérer les livres publiés par l'utilisateur
  Future<List<Map<String, dynamic>>> getUserBooks(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('books')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(5)
          .get();

      return querySnapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des livres: $e');
    }
  }

  // Récupérer les enchères de l'utilisateur
  Future<List<Map<String, dynamic>>> getUserAuctions(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('auctions')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(5)
          .get();

      return querySnapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des enchères: $e');
    }
  }
}
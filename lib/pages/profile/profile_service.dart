import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Récupérer les données utilisateur avec les statistiques actualisées
  Future<Map<String, dynamic>?> getUserData(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (!doc.exists) return null;

      // Récupérer les données de base
      Map<String, dynamic> userData = doc.data()!;

      // Calculer les statistiques en temps réel
      final booksCount = await getUserBooksCount(userId);
      final auctionsCount = await getUserAuctionsCount(userId);

      // Mettre à jour les statistiques
      userData['stats'] = {
        'booksAdded': booksCount,
        'auctionsCreated': auctionsCount,
        'auctionsWon': userData['stats']?['auctionsWon'] ?? 0,
        'rating': userData['stats']?['rating'] ?? 0,
      };

      return userData;
    } catch (e) {
      throw Exception('Erreur lors de la récupération des données utilisateur: $e');
    }
  }

  // Créer un document utilisateur par défaut avec des statistiques initialisées
  Future<void> createUserDocument(String userId, Map<String, dynamic> userData) async {
    try {
      final completeUserData = {
        ...userData,
        'stats': {
          'booksAdded': 0,
          'auctionsCreated': 0,
          'auctionsWon': 0,
          'rating': 0,
        },
        'createdAt': FieldValue.serverTimestamp(),
        'lastUpdated': FieldValue.serverTimestamp(),
        'profileCompleted': false,
      };

      await _firestore.collection('users').doc(userId).set(completeUserData);
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
        'lastUpdated': FieldValue.serverTimestamp(),
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
        },
        'lastUpdated': FieldValue.serverTimestamp(),
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
      print('Erreur lors du comptage des livres: $e');
      return 0;
    }
  }

  // Compter le nombre d'enchères créées par l'utilisateur
  Future<int> getUserAuctionsCount(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('auctions')
          .where('userId', isEqualTo: userId)
          .get();

      return querySnapshot.size;
    } catch (e) {
      print('Erreur lors du comptage des enchères: $e');
      return 0;
    }
  }

  // Compter le nombre d'enchères gagnées par l'utilisateur
  Future<int> getUserAuctionsWonCount(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('auctions')
          .where('winnerId', isEqualTo: userId)
          .get();

      return querySnapshot.size;
    } catch (e) {
      print('Erreur lors du comptage des enchères gagnées: $e');
      return 0;
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

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
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

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des enchères: $e');
    }
  }

  // Méthode pour mettre à jour les statistiques de l'utilisateur
  Future<void> updateUserStats(String userId) async {
    try {
      final booksCount = await getUserBooksCount(userId);
      final auctionsCount = await getUserAuctionsCount(userId);
      final auctionsWonCount = await getUserAuctionsWonCount(userId);

      await _firestore.collection('users').doc(userId).update({
        'stats.booksAdded': booksCount,
        'stats.auctionsCreated': auctionsCount,
        'stats.auctionsWon': auctionsWonCount,
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Erreur lors de la mise à jour des statistiques: $e');
    }
  }
}
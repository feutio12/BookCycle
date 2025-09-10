import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfileService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Map<String, Map<String, dynamic>> _cache = {};
  final StreamController<Map<String, dynamic>> _statsController =
  StreamController<Map<String, dynamic>>.broadcast();

  // Stream pour les mises à jour en temps réel des statistiques
  Stream<Map<String, dynamic>> get statsStream => _statsController.stream;

  // Obtenir les données utilisateur avec statistiques
  Future<Map<String, dynamic>> getUserData(String userId) async {
    try {
      // Vérifier le cache
      if (_cache.containsKey(userId)) {
        return _cache[userId]!;
      }

      // Récupérer les données utilisateur
      final userDoc = await _firestore.collection('users').doc(userId).get();

      if (!userDoc.exists) {
        throw Exception('Utilisateur non trouvé');
      }

      Map<String, dynamic> userData = userDoc.data()!;

      // Calculer les statistiques en parallèle
      final stats = await _calculateUserStats(userId);
      userData['stats'] = stats;

      // Mettre en cache
      _cache[userId] = userData;

      return userData;
    } catch (e) {
      print('Erreur getUserData: $e');
      rethrow;
    }
  }

  // Calculer les statistiques utilisateur
  Future<Map<String, dynamic>> _calculateUserStats(String userId) async {
    try {
      final results = await Future.wait([
        _countUserBooks(userId),
        _countUserAuctions(userId),
        _countWonAuctions(userId),
        _countActiveAuctions(userId),
      ]);

      final stats = {
        'booksPublished': results[0],
        'auctionsCreated': results[1],
        'auctionsWon': results[2],
        'activeAuctions': results[4],
        'rating': await _calculateUserRating(userId),
        'lastUpdated': FieldValue.serverTimestamp(),
      };

      // Mettre à jour Firestore
      await _firestore.collection('users').doc(userId).update({
        'stats': stats,
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      // Émettre les nouvelles stats
      _statsController.add(stats);

      return stats;
    } catch (e) {
      print('Erreur _calculateUserStats: $e');
      return {
        'booksPublished': 0,
        'auctionsCreated': 0,
        'auctionsWon': 0,
        'activeBooks': 0,
        'activeAuctions': 0,
        'rating': 0.0,
      };
    }
  }

  // Compter les livres publiés par l'utilisateur
  Future<int> _countUserBooks(String userId) async {
    try {
      final query = await _firestore
          .collection('books')
          .where('userId', isEqualTo: userId)
          .get();
      return query.size;
    } catch (e) {
      print('Erreur _countUserBooks: $e');
      return 0;
    }
  }

  // Compter les enchères créées par l'utilisateur
  Future<int> _countUserAuctions(String userId) async {
    try {
      final query = await _firestore
          .collection('encheres')
          .where('createurId', isEqualTo: userId)
          .get();
      return query.size;
    } catch (e) {
      print('Erreur _countUserAuctions: $e');
      return 0;
    }
  }

  // Compter les enchères gagnées par l'utilisateur
  Future<int> _countWonAuctions(String userId) async {
    try {
      final query = await _firestore
          .collection('encheres')
          .where('winnerId', isEqualTo: userId)
          .where('statut', isEqualTo: 'completed')
          .get();
      return query.size;
    } catch (e) {
      print('Erreur _countWonAuctions: $e');
      return 0;
    }
  }

  // Compter les enchères actives
  Future<int> _countActiveAuctions(String createurId) async {
    try {
      final query = await _firestore
          .collection('encheres')
          .where('createurId', isEqualTo: createurId)
          .where('statut', isEqualTo: 'active')
          .get();
      return query.size;
    } catch (e) {
      print('Erreur _countActiveAuctions: $e');
      return 0;
    }
  }

  // Calculer la note moyenne de l'utilisateur
  Future<double> _calculateUserRating(String userId) async {
    try {
      final reviews = await _firestore
          .collection('reviews')
          .where('targetUserId', isEqualTo: userId)
          .get();

      if (reviews.size == 0) return 0.0;

      final totalRating = reviews.docs.fold(0.0, (sum, doc) {
        return sum + (doc.data()['rating'] as num).toDouble();
      });

      return totalRating / reviews.size;
    } catch (e) {
      print('Erreur _calculateUserRating: $e');
      return 0.0;
    }
  }

  // Stream des statistiques en temps réel
  Stream<Map<String, dynamic>> getUserStatsStream(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .snapshots()
        .asyncMap((snapshot) async {
      if (!snapshot.exists) {
        return await _calculateUserStats(userId);
      }

      final data = snapshot.data()!;
      return data['stats'] as Map<String, dynamic>? ?? await _calculateUserStats(userId);
    });
  }

  // Rafraîchir manuellement les statistiques
  Future<void> refreshUserStats(String userId) async {
    try {
      _cache.remove(userId); // Vider le cache
      await _calculateUserStats(userId);
    } catch (e) {
      print('Erreur refreshUserStats: $e');
    }
  }

  // Mettre à jour le profil utilisateur
  Future<void> updateUserProfile({
    required String userId,
    required String name,
    required String bio,
    String? photoUrl,
  }) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'name': name,
        'bio': bio,
        if (photoUrl != null) 'photoUrl': photoUrl,
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      _cache.remove(userId); // Invalider le cache
    } catch (e) {
      print('Erreur updateUserProfile: $e');
      rethrow;
    }
  }

  // Mettre à jour les préférences
  Future<void> updateUserPreferences({
    required String userId,
    required Map<String, dynamic> preferences,
  }) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'preferences': preferences,
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      _cache.remove(userId);
    } catch (e) {
      print('Erreur updateUserPreferences: $e');
      rethrow;
    }
  }

  // Vider le cache
  void clearCache(String userId) {
    _cache.remove(userId);
  }

  // Nettoyer
  void dispose() {
    _statsController.close();
  }
}
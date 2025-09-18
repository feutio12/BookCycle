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

      // Vérifier si les statistiques sont à jour (moins de 5 minutes)
      final lastUpdated = userData['stats']?['lastUpdated'] as Timestamp?;
      final now = DateTime.now();
      final shouldRefresh = lastUpdated == null ||
          now.difference(lastUpdated.toDate()).inMinutes > 5;

      Map<String, dynamic> stats;
      if (shouldRefresh) {
        // Calculer les nouvelles statistiques
        stats = await _calculateUserStats(userId);
      } else {
        // Utiliser les statistiques existantes
        stats = userData['stats'] as Map<String, dynamic>? ?? {};
      }

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
        _calculateUserRating(userId),
      ]);

      final stats = {
        'booksPublished': results[0],
        'auctionsCreated': results[1],
        'auctionsWon': results[2],
        'activeAuctions': results[3],
        'rating': results[4],
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
        'activeAuctions': 0,
        'rating': 0.0,
        'lastUpdated': FieldValue.serverTimestamp(),
      };
    }
  }

  // Compter les livres publiés par l'utilisateur - VERSION AMÉLIORÉE
  Future<int?> _countUserBooks(String userId) async {
    try {
      // Utiliser count() pour optimiser la requête (moins de données transférées)
      final query = _firestore
          .collection('books')
          .where('userId', isEqualTo: userId)
          .where('isActive', isEqualTo: true); // Ajouter un filtre pour les livres actifs

      final aggregateQuery = query.count();
      final snapshot = await aggregateQuery.get();

      return snapshot.count;
    } catch (e) {
      print('Erreur _countUserBooks: $e');

      // Fallback: utiliser l'ancienne méthode si count() n'est pas supporté
      try {
        final query = await _firestore
            .collection('books')
            .where('userId', isEqualTo: userId)
            .where('isActive', isEqualTo: true)
            .get();
        return query.size;
      } catch (e2) {
        print('Fallback _countUserBooks aussi en erreur: $e2');
        return 0;
      }
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

      return double.parse((totalRating / reviews.size).toStringAsFixed(1));
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
      final stats = data['stats'] as Map<String, dynamic>?;

      // Vérifier si les statistiques sont fraîches (moins de 5 minutes)
      final lastUpdated = stats?['lastUpdated'] as Timestamp?;
      final now = DateTime.now();

      if (lastUpdated == null || now.difference(lastUpdated.toDate()).inMinutes > 5) {
        return await _calculateUserStats(userId);
      }

      return stats ?? await _calculateUserStats(userId);
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

  // Méthode spécifique pour gérer la publication d'un nouveau livre
  Future<void> handleNewBookPublished(String userId) async {
    try {
      // Invalider le cache et recalculer les stats
      _cache.remove(userId);
      await _calculateUserStats(userId);
    } catch (e) {
      print('Erreur handleNewBookPublished: $e');
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
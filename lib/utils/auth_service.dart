import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Vérification du statut admin
  Future<bool> isAdmin() async {
    final user = _auth.currentUser;
    if (user == null) return false;

    try {
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      return userDoc.exists && userDoc['email'] == 'admin@admin.com'; // Utilisez un email complet
    } catch (e) {
      return false;
    }
  }

  // Méthode de déconnexion complète
  Future<void> signOut() async {
    try {
      // Déconnexion de Firebase Auth
      await _auth.signOut();

      // Nettoyage supplémentaire pour s'assurer que la déconnexion est complète
      await Future.delayed(const Duration(milliseconds: 500));

      // Vérification que l'utilisateur est bien déconnecté
      if (_auth.currentUser != null) {
        throw Exception("Échec de la déconnexion complète");
      }

    } catch (e) {
      print("Erreur lors de la déconnexion: $e");
      // Relancer l'exception pour que l'UI puisse la gérer
      rethrow;
    }
  }

  // Méthode pour forcer une déconnexion complète (en cas de problèmes)
  Future<void> forceSignOut() async {
    try {
      // Réinitialiser l'instance Firebase Auth
      await _auth.signOut();

      // Attendre que les changements prennent effet
      await Future.delayed(const Duration(seconds: 1));

    } catch (e) {
      print("Erreur lors de la déconnexion forcée: $e");
      rethrow;
    }
  }

  // Vérifier si l'utilisateur est déconnecté
  bool isUserSignedOut() {
    return _auth.currentUser == null;
  }

  static bool isUserLoggedIn() {
    return FirebaseAuth.instance.currentUser != null;
  }

}
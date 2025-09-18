// admin_auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<String?> signInWithEmailAndPassword(String email, String password) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
          email: email,
          password: password
      );

      // Vérifier si l'utilisateur est admin
      final isAdmin = await checkIfAdmin(userCredential.user!.uid);

      if (!isAdmin) {
        await _auth.signOut();
        return "Accès réservé aux administrateurs";
      }

      return null;
    } on FirebaseAuthException catch (e) {
      return e.message;
    }
  }

  Future<bool> checkIfAdmin(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        return userData['role'] == 'admin';
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}
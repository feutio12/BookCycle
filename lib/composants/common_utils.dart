import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';

import '../pages/auth/loginpage.dart';
import 'common_components.dart';

class AppUtils {
  // Convertir une image en base64
  static Future<String?> convertImageToBase64(File? imageFile) async {
    if (imageFile == null) return null;

    try {
      final bytes = await imageFile.readAsBytes();
      return base64Encode(bytes);
    } catch (e) {
      throw Exception('Erreur de conversion: ${e.toString()}');
    }
  }

  // Choisir une image depuis la galerie
  static Future<File?> pickImage() async {
    try {
      final pickedFile = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 70,
      );

      if (pickedFile != null) {
        final file = File(pickedFile.path);
        if (await file.length() > 1048576) {
          throw Exception('L\'image est trop grande (max 1MB)');
        }
        return file;
      }
      return null;
    } catch (e) {
      throw Exception('Erreur: ${e.toString()}');
    }
  }

  // Afficher un snackbar d'erreur
  static void showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.errorRed,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // Afficher un snackbar de succès
  static void showSuccessSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.successGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // Afficher un message demandant la connexion
  static void showLoginRequiredSnackBar(BuildContext context, String action) {
    final scaffold = ScaffoldMessenger.of(context);
    scaffold.showSnackBar(
      SnackBar(
        content: Text('Connectez-vous $action'),
        backgroundColor: AppColors.primaryBlue,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        action: SnackBarAction(
          label: 'Se connecter',
          textColor: Colors.white,
          onPressed: () {
            scaffold.hideCurrentSnackBar();
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const LoginPage()),
            );
          },
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // Récupérer le nom de l'utilisateur depuis Firestore
  static Future<String> getUserName(String userId) async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (userDoc.exists) {
        return userDoc.data()?['displayName'] ??
            userDoc.data()?['name'] ??
            userDoc.data()?['email']?.split('@').first ??
            'Utilisateur';
      }
      return 'Utilisateur inconnu';
    } catch (e) {
      return 'Utilisateur inconnu';
    }
  }
}
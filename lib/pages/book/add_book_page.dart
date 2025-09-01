import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:bookcycle/pages/home/homepage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../composants/common_components.dart';
import '../../composants/common_utils.dart';

class AddBookPage extends StatefulWidget {
  const AddBookPage({super.key,});

  @override
  State<AddBookPage> createState() => _AddBookPageState();
}

class _AddBookPageState extends State<AddBookPage> {
  final _formKey = GlobalKey<FormState>();
  final _controllers = {
    'title': TextEditingController(),
    'author': TextEditingController(),
    'description': TextEditingController(),
    'price': TextEditingController(),
    'pages': TextEditingController(),
    'rating': TextEditingController(),
  };

  File? _imageFile;
  String? _selectedCategory;
  bool _isLoading = false;
  String? _uploadError;

  static const _categories = [
    'Science-fiction', 'Romance', 'Fantasy',
    'Classique', 'Philosophie', 'Littérature', 'autres'
  ];

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _controllers.values.forEach((controller) => controller.dispose());
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final file = await AppUtils.pickImage();
      if (file != null) {
        setState(() {
          _imageFile = file;
          _uploadError = null;
        });
      }
    } catch (e) {
      AppUtils.showErrorSnackBar(context, e.toString());
    }
  }

  Future<String?> _convertImageToBase64() async {
    return await AppUtils.convertImageToBase64(_imageFile);
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    if (_imageFile == null) {
      AppUtils.showErrorSnackBar(context, 'Veuillez ajouter une image');
      return;
    }
    if (_selectedCategory == null) {
      AppUtils.showErrorSnackBar(context, 'Veuillez sélectionner une catégorie');
      return;
    }


    setState(() => _isLoading = true);

    try {
      final imageBase64 = await _convertImageToBase64();
      if (imageBase64 == null) return;

      final bookData = await _prepareBookData(imageBase64);
      await _saveBookToFirestore(bookData);

      _showSuccessMessageAndRedirect();
    } catch (e) {
      _showErrorMessage(e);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<Map<String, dynamic>> _prepareBookData(String imageBase64) async {
    String publisherName = 'Anonyme';

      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        publisherName = user.displayName ?? 'Anonyme';

        // Si l'utilisateur n'a pas de nom défini, essayez de récupérer depuis Firestore
        if (publisherName == 'Anonyme') {
          try {
            final userDoc = await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .get();

            if (userDoc.exists && userDoc.data() != null) {
              final userData = userDoc.data()!;
              publisherName = userData['name'] ?? userData['username'] ?? 'Anonyme';
            }
          } catch (e) {
            print('Erreur lors de la récupération du nom: $e');
          }
        }

    }

    final bookData = {
      'pages': int.tryParse(_controllers['pages']!.text) ?? 100,
      'price': int.tryParse(_controllers['price']!.text) ?? 100,
      'rating': int.tryParse(_controllers['rating']!.text) ?? 100,
      'title': _controllers['title']!.text.trim().isEmpty ? "100" : _controllers['title']!.text.trim(),
      'author': _controllers['author']!.text.trim().isEmpty ? "100" : _controllers['author']!.text.trim(),
      'category': _selectedCategory ?? "100",
      'createdAt': FieldValue.serverTimestamp(),
      'description': _controllers['description']!.text.trim().isEmpty
          ? "200" : _controllers['description']!.text.trim(),
      'imageUrl': imageBase64.isEmpty ? "100" : imageBase64,
      'isPopular': false,
      'likes': 0,
      'publisherName': publisherName,
    };


    return bookData;
  }

  Future<void> _saveBookToFirestore(Map<String, dynamic> bookData) async {
    // Ajouter le livre à la collection principale
    final bookRef = await FirebaseFirestore.instance.collection('books')
        .add(bookData)
        .timeout(const Duration(seconds: 10));

    // Mettre à jour les stats de l'utilisateur
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid)
          .update({
        'stats.booksAdded': FieldValue.increment(1)
      });

      // Ajouter le livre à la sous-collection de l'utilisateur
      await FirebaseFirestore.instance.collection('users').doc(user.uid)
          .collection('books').doc(bookRef.id).set({
        'addedAt': FieldValue.serverTimestamp(),
        'title': bookData['title'],
        'status': 'available'
      });
    }
  }

  void _showSuccessMessageAndRedirect() {
    AppUtils.showSuccessSnackBar(context, 'Livre ajouté avec succès');

    // Redirection vers la page d'accueil
    Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const Homepage()),
            (route) => false
    );
  }

  void _showErrorMessage(dynamic error) {
    String message = 'Erreur inconnue';
    if (error is FirebaseException) {
      message = 'Erreur Firestore: ${error.message}';
    } else if (error is TimeoutException) {
      message = 'Timeout - Vérifiez votre connexion';
    } else {
      message = 'Erreur: ${error.toString()}';
    }
    AppUtils.showErrorSnackBar(context, message);
  }

  Widget _buildFormField(String label, String key, {bool isNumber = false, required int maxLines}) {
    return FormTextField(
      controller: _controllers[key]!,
      label: label,
      isNumber: isNumber,
      validator: (value) {
        if (value == null || value.isEmpty) return 'Ce champ est requis';
        if (isNumber && int.tryParse(value) == null) return 'Entrez un nombre valide';
        if (key == 'rating') {
          final rating = int.tryParse(value);
          if (rating == null || rating < 0 || rating > 100) {
            return 'Entrez une note entre 0 et 100';
          }
        }
        return null;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.backgroundColor,
        body: LoadingIndicator(message: 'Publication en cours...'),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajouter un livre'),
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
      ),
      backgroundColor: AppColors.backgroundColor,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              ImagePickerWidget(
                imageFile: _imageFile,
                onTap: _pickImage,
                errorMessage: _uploadError,
              ),
              const SizedBox(height: 24),
              _buildFormField('Titre du livre', 'title', maxLines: 3),
              const SizedBox(height: 16),
              _buildFormField('Auteur', 'author', maxLines: 3),
              const SizedBox(height: 16),
              _buildFormField('Description', 'description', maxLines: 3),
              const SizedBox(height: 16),
              _buildFormField('Prix (fcfa)', 'price', isNumber: true, maxLines: 3),
              const SizedBox(height: 16),
              _buildFormField('Nombre de pages', 'pages', isNumber: true, maxLines: 3),
              const SizedBox(height: 16),
              _buildFormField('Note (0-100)', 'rating', isNumber: true, maxLines: 3),
              const SizedBox(height: 16),

              // Category dropdown
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: InputDecoration(
                  labelText: 'Catégorie',
                  labelStyle: const TextStyle(color: AppColors.primaryBlue),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppColors.primaryBlue.withOpacity(0.5)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: AppColors.primaryBlue, width: 2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                items: _categories.map((String category) {
                  return DropdownMenuItem<String>(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedCategory = newValue;
                  });
                },
                validator: (value) {
                  if (value == null) return 'Veuillez sélectionner une catégorie';
                  return null;
                },
              ),

              const SizedBox(height: 32),
              PrimaryButton(
                text: 'PUBLIER LE LIVRE',
                onPressed: _submitForm,
                isLoading: _isLoading,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
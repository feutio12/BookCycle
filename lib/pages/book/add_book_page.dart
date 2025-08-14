import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:bookcycle/pages/homepage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AddBookPage extends StatefulWidget {
  final bool isGuest;
  const AddBookPage({super.key, required this.isGuest});

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

  final _picker = ImagePicker();
  File? _imageFile;
  String? _selectedCategory;
  bool _isLoading = false;
  String? _uploadError;
  bool _hasPostedAsGuest = false;

  static const _categories = [
    'Science-fiction', 'Romance', 'Fantasy',
    'Classique', 'Philosophie', 'Littérature'
  ];

  @override
  void initState() {
    super.initState();
    _checkGuestPostingStatus();
  }

  Future<void> _checkGuestPostingStatus() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _hasPostedAsGuest = prefs.getBool('hasPostedAsGuest') ?? false;
    });
  }

  @override
  void dispose() {
    _controllers.values.forEach((controller) => controller.dispose());
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 70,
      );

      if (pickedFile != null) {
        final file = File(pickedFile.path);
        if (await file.length() > 1048576) {
          _showError('L\'image est trop grande (max 1MB)');
          return;
        }

        setState(() {
          _imageFile = file;
          _uploadError = null;
        });
      }
    } catch (e) {
      _showError('Erreur: ${e.toString()}');
    }
  }

  Future<String?> _convertImageToBase64() async {
    if (_imageFile == null) return null;

    try {
      final bytes = await _imageFile!.readAsBytes();
      return base64Encode(bytes);
    } catch (e) {
      setState(() => _uploadError = 'Erreur de conversion: ${e.toString()}');
      return null;
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    if (_imageFile == null) return _showError('Veuillez ajouter une image');
    if (_selectedCategory == null) return _showError('Veuillez sélectionner une catégorie');

    // Vérification pour les invités
    if (widget.isGuest && _hasPostedAsGuest) {
      return _showError('Connectez-vous pour ajouter plus de livres');
    }

    setState(() => _isLoading = true);

    try {
      final imageBase64 = await _convertImageToBase64();
      if (imageBase64 == null) return;

      final bookData = await _prepareBookData(imageBase64);
      await _saveBookToFirestore(bookData);

      if (widget.isGuest) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('hasPostedAsGuest', true);
      }

      _showSuccessMessageAndRedirect();
    } catch (e) {
      _showErrorMessage(e);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<Map<String, dynamic>> _prepareBookData(String imageBase64) async {
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
    };

    if (!widget.isGuest) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        bookData['userId'] = user.uid;
        bookData['publisherName'] = user.displayName ?? 'Anonyme';
      }
    }
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const Homepage()),
      );
    }

    return bookData;
  }

  Future<void> _saveBookToFirestore(Map<String, dynamic> bookData) async {
    await FirebaseFirestore.instance.collection('books')
        .add(bookData)
        .timeout(const Duration(seconds: 10));
  }

  void _showSuccessMessageAndRedirect() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Livre ajouté avec succès')),
    );
    Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
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
    _showError(message);
  }

  Widget _buildFormField(String label, String key, {bool isNumber = false}) {
    return TextFormField(
      controller: _controllers[key],
      decoration: InputDecoration(labelText: label),
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
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
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    return Scaffold(
      appBar: AppBar(title: const Text('Ajouter un livre')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Image picker
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                    image: _imageFile != null
                        ? DecorationImage(image: FileImage(_imageFile!), fit: BoxFit.cover)
                        : null,
                  ),
                  child: _imageFile == null
                      ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_a_photo, size: 50),
                        SizedBox(height: 8),
                        Text('Ajouter une couverture'),
                      ],
                    ),
                  )
                      : null,
                ),
              ),
              if (_uploadError != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(_uploadError!, style: const TextStyle(color: Colors.red)),
                ),

              const SizedBox(height: 20),
              _buildFormField('Titre', 'title'),
              const SizedBox(height: 16),
              _buildFormField('Auteur', 'author'),
              const SizedBox(height: 16),
              _buildFormField('Description', 'description'),
              const SizedBox(height: 16),

              // Price and Pages row
              Row(
                children: [
                  Expanded(child: _buildFormField('Prix', 'price', isNumber: true)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildFormField('Pages', 'pages', isNumber: true)),
                ],
              ),

              const SizedBox(height: 16),
              _buildFormField('Note (0-100)', 'rating', isNumber: true),
              const SizedBox(height: 16),

              // Category dropdown
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: const InputDecoration(labelText: 'Catégorie'),
                items: _categories.map((c) => DropdownMenuItem(
                  value: c,
                  child: Text(c),
                )).toList(),
                onChanged: (value) => setState(() => _selectedCategory = value),
                validator: (value) => value == null ? 'Sélectionnez une catégorie' : null,
              ),

              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _submitForm,
                  child: const Text('PUBLIER LE LIVRE', style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
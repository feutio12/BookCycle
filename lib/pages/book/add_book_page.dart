import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:bookcycle/pages/home/homepage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class AddBookPage extends StatefulWidget {
  final Map<String, dynamic>? book;
  final String? bookId;

  const AddBookPage({super.key, this.book, this.bookId});

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
  };

  File? _imageFile;
  String? _selectedCategory;
  String? _selectedCondition;
  String? _selectedType;
  bool _isLoading = false;
  bool _isEditing = false;
  String? _existingImageBase64;

  static const _categories = [
    'Science-fiction', 'Romance', 'Fantasy', 'Comedie',
    'Classique', 'Philosophie', 'Littérature', 'autres'
  ];

  static const _conditions = [
    'Neuf', 'Très bon état', 'Bon état', 'État acceptable'
  ];

  static const _types = [
    'Échange', 'Vente', 'Don'
  ];

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  @override
  void dispose() {
    _controllers.values.forEach((controller) => controller.dispose());
    super.dispose();
  }

  void _initializeForm() {
    if (widget.book != null) {
      _isEditing = true;

      _controllers['title']!.text = widget.book!['title'] ?? '';
      _controllers['author']!.text = widget.book!['author'] ?? '';
      _controllers['description']!.text = widget.book!['description'] ?? '';
      _controllers['price']!.text = widget.book!['price']?.toString() ?? '0';
      _controllers['pages']!.text = widget.book!['pages']?.toString() ?? '0';

      _selectedCategory = widget.book!['category'];
      _selectedCondition = widget.book!['condition'];
      _selectedType = widget.book!['type'];
      _existingImageBase64 = widget.book!['imageUrl'];
    }
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);

      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
          _existingImageBase64 = null; // Effacer l'image existante si nouvelle image sélectionnée
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    }
  }

  Future<String?> _convertImageToBase64() async {
    if (_imageFile != null) {
      try {
        final bytes = await _imageFile!.readAsBytes();
        return base64Encode(bytes);
      } catch (e) {
        return null;
      }
    }
    return _existingImageBase64;
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    if (_imageFile == null && _existingImageBase64 == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez ajouter une image')),
      );
      return;
    }

    if (_selectedCategory == null || _selectedCondition == null || _selectedType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez remplir tous les champs')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final imageBase64 = await _convertImageToBase64();
      if (imageBase64 == null) throw Exception('Erreur avec l\'image');

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Utilisateur non connecté');

      final bookData = {
        'title': _controllers['title']!.text.trim(),
        'author': _controllers['author']!.text.trim(),
        'description': _controllers['description']!.text.trim(),
        'price': int.parse(_controllers['price']!.text),
        'pages': int.parse(_controllers['pages']!.text),
        'category': _selectedCategory!,
        'condition': _selectedCondition!,
        'type': _selectedType!,
        'imageUrl': imageBase64,
        'publisherEmail': user.email,
        'userId': user.uid,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (_isEditing && widget.bookId != null) {
        // Mode édition - Vérifier que l'utilisateur est le propriétaire
        final bookDoc = await FirebaseFirestore.instance
            .collection('books')
            .doc(widget.bookId)
            .get();

        if (bookDoc.exists) {
          final existingBook = bookDoc.data() as Map<String, dynamic>;
          if (existingBook['publisherEmail'] != user.email) {
            throw Exception('Vous n\'êtes pas autorisé à modifier ce livre');
          }
        }

        await FirebaseFirestore.instance
            .collection('books')
            .doc(widget.bookId)
            .update(bookData);
      } else {
        // Mode ajout
        bookData['createdAt'] = FieldValue.serverTimestamp();
        bookData['likes'] = 0;
        bookData['isPopular'] = false;
        bookData['rating'] = 0.0;

        await FirebaseFirestore.instance
            .collection('books')
            .add(bookData);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEditing ? 'Livre publié avec succès!' : 'Livre modifié avec succès!'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.of(context).pop(true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildImagePicker() {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        height: 200,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: _imageFile != null
            ? Image.file(_imageFile!, fit: BoxFit.cover)
            : _existingImageBase64 != null && _existingImageBase64 != "100"
            ? Image.memory(base64Decode(_existingImageBase64!), fit: BoxFit.cover)
            : Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.camera_alt, size: 50, color: Colors.grey[400]),
            const SizedBox(height: 8),
            Text(
              'Ajouter une image',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, String key, {bool isNumber = false, int maxLines = 1}) {
    return TextFormField(
      controller: _controllers[key],
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.white,
      ),
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      maxLines: maxLines,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Ce champ est requis';
        }
        if (isNumber && int.tryParse(value) == null) {
          return 'Veuillez entrer un nombre valide';
        }
        return null;
      },
    );
  }

  Widget _buildDropdown(String label, List<String> items, String? value, Function(String?) onChanged) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.white,
      ),
      items: items.map((String item) {
        return DropdownMenuItem<String>(
          value: item,
          child: Text(item),
        );
      }).toList(),
      onChanged: onChanged,
      validator: (value) {
        if (value == null) {
          return 'Veuillez sélectionner une option';
        }
        return null;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Ajouter un livre' : 'Modifier le livre'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      backgroundColor: Colors.grey[100],
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Image picker
              _buildImagePicker(),
              const SizedBox(height: 20),

              // Titre
              _buildTextField('Titre du livre', 'title', maxLines: 2),
              const SizedBox(height: 16),

              // Auteur
              _buildTextField('Auteur', 'author', maxLines: 2),
              const SizedBox(height: 16),

              // Description
              _buildTextField('Description', 'description', maxLines: 4),
              const SizedBox(height: 16),

              // Prix
              _buildTextField('Prix (FCFA)', 'price', isNumber: true),
              const SizedBox(height: 16),

              // Nombre de pages
              _buildTextField('Nombre de pages', 'pages', isNumber: true),
              const SizedBox(height: 16),

              // Catégorie
              _buildDropdown('Catégorie', _categories, _selectedCategory, (value) {
                setState(() => _selectedCategory = value);
              }),
              const SizedBox(height: 16),

              // État
              _buildDropdown('État du livre', _conditions, _selectedCondition, (value) {
                setState(() => _selectedCondition = value);
              }),
              const SizedBox(height: 16),

              // Type
              _buildDropdown('Type', _types, _selectedType, (value) {
                setState(() => _selectedType = value);
              }),
              const SizedBox(height: 24),

              // Bouton de soumission
              ElevatedButton(
                onPressed: _isLoading ? null : _submitForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                  _isEditing ? 'PUBLIER LE LIVRE' : 'MODIFIER LE LIVRE',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
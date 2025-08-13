import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';

class AddBookPage extends StatefulWidget {
  final bool isGuest;
  const AddBookPage({super.key, required this.isGuest});

  @override
  State<AddBookPage> createState() => _AddBookPageState();
}

class _AddBookPageState extends State<AddBookPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _authorController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _pagesController = TextEditingController();

  final _picker = ImagePicker();
  File? _imageFile;
  String? _selectedCategory;
  bool _isLoading = false;
  String? _uploadError;

  final List<String> _categories = [
    'Science-fiction', 'Romance', 'Fantasy',
    'Classique', 'Philosophie', 'Littérature'
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _authorController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _pagesController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 70,
      );

      if (pickedFile != null) {
        final file = File(pickedFile.path);
        // Vérifier la taille du fichier (max 1MB pour Firestore)
        if (await file.length() > 1048576) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('L\'image est trop grande (max 1MB)'),
              ),
            );
          }
          return;
        }

        setState(() {
          _imageFile = file;
          _uploadError = null;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
          ),
        );
      }
    }
  }

  Future<String?> _convertImageToBase64() async {
    if (_imageFile == null) return null;

    try {
      final bytes = await _imageFile!.readAsBytes();
      return base64Encode(bytes);
    } catch (e) {
      if (mounted) {
        setState(() {
          _uploadError = 'Erreur de conversion: ${e.toString()}';
        });
      }
      return null;
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    if (_imageFile == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Veuillez ajouter une image')),
        );
      }
      return;
    }

    if (_selectedCategory == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Veuillez sélectionner une catégorie')),
        );
      }
      return;
    }

    setState(() => _isLoading = true);

    try {
      final imageBase64 = await _convertImageToBase64();
      if (imageBase64 == null) return;

      final bookData = {
        'title': _titleController.text.trim(),
        'author': _authorController.text.trim(),
        'description': _descriptionController.text.trim(),
        'imageBase64': imageBase64,
        'category': _selectedCategory!,
        'price': double.tryParse(_priceController.text) ?? 0,
        'pages': int.tryParse(_pagesController.text) ?? 0,
        'likes': 0,
        'rating': 0.0,
        'isPopular': false,
        'createdAt': FieldValue.serverTimestamp(),
      };

      if (!widget.isGuest) {
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) throw Exception('Utilisateur non connecté');
        bookData['userId'] = user.uid;
        bookData['publisherName'] = user.displayName ?? 'Anonyme';
      }

      await FirebaseFirestore.instance.collection('books').add(bookData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Livre ajouté avec succès')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajouter un livre'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
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
                        ? DecorationImage(
                        image: FileImage(_imageFile!),
                        fit: BoxFit.cover)
                        : null,
                  ),
                  child: _imageFile == null
                      ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.add_a_photo, size: 50),
                        const SizedBox(height: 8),
                        const Text('Ajouter une couverture'),
                      ],
                    ),
                  )
                      : null,
                ),
              ),
              if (_uploadError != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    _uploadError!,
                  ),
                ),

              const SizedBox(height: 20),

              // Formulaire (identique à avant)
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Titre'),
                validator: (value) =>
                value!.isEmpty ? 'Ce champ est requis' : null,
              ),

              const SizedBox(height: 16),

              // Description field
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (value) => value!.isEmpty ? 'Ce champ est requis' : null,
              ),

              const SizedBox(height: 16),

              // Price and pages row
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _priceController,
                      decoration: const InputDecoration(
                        labelText: 'Prix (fcfa)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Ce champ est requis';
                        if (double.tryParse(value) == null) return 'Entrez un nombre valide';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _pagesController,
                      decoration: const InputDecoration(
                        labelText: 'Pages',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Ce champ est requis';
                        if (int.tryParse(value) == null) return 'Entrez un nombre valide';
                        return null;
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Category dropdown
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Catégorie',
                  border: OutlineInputBorder(),
                ),
                items: _categories.map((c) => DropdownMenuItem(
                  value: c,
                  child: Text(c),
                )).toList(),
                onChanged: (value) => setState(() => _selectedCategory = value),
                validator: (value) => value == null ? 'Sélectionnez une catégorie' : null,
              ),

              const SizedBox(height: 32),

              // Submit button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _submitForm,
                  child: const Text(
                    'PUBLIER LE LIVRE',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
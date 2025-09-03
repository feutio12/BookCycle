import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../composants/common_components.dart' show PrimaryButton;

class EditBookPage extends StatefulWidget {
  final String bookId;
  final Map<String, dynamic> bookData;

  const EditBookPage({
    super.key,
    required this.bookId,
    required this.bookData,
  });

  @override
  State<EditBookPage> createState() => _EditBookPageState();
}

class _EditBookPageState extends State<EditBookPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _authorController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();

  String _condition = 'Bon';
  String _type = 'Échange';

  @override
  void initState() {
    super.initState();
    // Pré-remplir les champs avec les données existantes
    _titleController.text = widget.bookData['title'] ?? '';
    _authorController.text = widget.bookData['author'] ?? '';
    _descriptionController.text = widget.bookData['description'] ?? '';
    _categoryController.text = widget.bookData['category'] ?? '';
    _locationController.text = widget.bookData['location'] ?? '';
    _condition = widget.bookData['condition'] ?? 'Bon';
    _type = widget.bookData['type'] ?? 'Échange';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _authorController.dispose();
    _descriptionController.dispose();
    _categoryController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _updateBook() async {
    if (_formKey.currentState!.validate()) {
      try {
        await FirebaseFirestore.instance
            .collection('books')
            .doc(widget.bookId)
            .update({
          'title': _titleController.text,
          'author': _authorController.text,
          'description': _descriptionController.text,
          'category': _categoryController.text,
          'location': _locationController.text,
          'condition': _condition,
          'type': _type,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Livre mis à jour avec succès')),
        );

        Navigator.of(context).pop();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la mise à jour: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Modifier le livre'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _updateBook,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Titre'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer un titre';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _authorController,
                decoration: const InputDecoration(labelText: 'Auteur'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer un auteur';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 3,
              ),
              TextFormField(
                controller: _categoryController,
                decoration: const InputDecoration(labelText: 'Catégorie'),
              ),
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(labelText: 'Localisation'),
              ),
              DropdownButtonFormField<String>(
                value: _condition,
                decoration: const InputDecoration(labelText: 'État'),
                items: ['Excellent', 'Bon', 'Moyen', 'Usé']
                    .map((condition) => DropdownMenuItem(
                  value: condition,
                  child: Text(condition),
                ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _condition = value!;
                  });
                },
              ),
              DropdownButtonFormField<String>(
                value: _type,
                decoration: const InputDecoration(labelText: 'Type'),
                items: ['Échange', 'Don', 'Vente']
                    .map((type) => DropdownMenuItem(
                  value: type,
                  child: Text(type),
                ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _type = value!;
                  });
                },
              ),
              const SizedBox(height: 20),
              PrimaryButton(
                text: 'Enregistrer les modifications',
                onPressed: _updateBook,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bookcycle/composants/common_components.dart';
import 'package:bookcycle/composants/common_utils.dart';

class AdminBooksManagement extends StatefulWidget {
  const AdminBooksManagement({super.key});

  @override
  State<AdminBooksManagement> createState() => _AdminBooksManagementState();
}

class _AdminBooksManagementState extends State<AdminBooksManagement> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _searchQuery = '';
  String _filterStatus = 'Tous';

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Gestion des livres',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            // Search and filter bar
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Rechercher un livre...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 16),
                DropdownButton<String>(
                  value: _filterStatus,
                  items: const [
                    DropdownMenuItem(value: 'Tous', child: Text('Tous')),
                    DropdownMenuItem(value: 'available', child: Text('Disponibles')),
                    DropdownMenuItem(value: 'exchanged', child: Text('Échangés')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _filterStatus = value!;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Books list
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore.collection('books').snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text('Erreur: ${snapshot.error}'));
                  }
      
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
      
                  var books = snapshot.data!.docs;
      
                  // Apply filters
                  if (_searchQuery.isNotEmpty) {
                    books = books.where((book) {
                      final title = book['title']?.toString().toLowerCase() ?? '';
                      final author = book['author']?.toString().toLowerCase() ?? '';
                      return title.contains(_searchQuery.toLowerCase()) ||
                          author.contains(_searchQuery.toLowerCase());
                    }).toList();
                  }
      
                  return ListView.builder(
                    itemCount: books.length,
                    itemBuilder: (context, index) {
                      final book = books[index];
                      final data = book.data() as Map<String, dynamic>;
      
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: data['imageUrl'] != null && data['imageUrl'] != "100"
                              ? Image.memory(
                            base64Decode(data['imageUrl']),
                            width: 50,
                            height: 70,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(Icons.book),
                          )
                              : const Icon(Icons.book, size: 40),
                          title: Text(data['title'] ?? 'Sans titre'),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Auteur: ${data['author'] ?? 'Inconnu'}'),
                              Text('Catégorie: ${data['category'] ?? 'Non catégorisé'}'),
                              Text('Prix: ${data['price'] ?? '0'} FCFA'),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.visibility),
                                onPressed: () => _viewBookDetails(book.id, data),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () => _deleteBook(book.id, data['title'] ?? 'Livre'),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _viewBookDetails(String bookId, Map<String, dynamic> bookData) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Détails du livre'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (bookData['imageUrl'] != null && bookData['imageUrl'] != "100")
                Center(
                  child: Image.memory(
                    base64Decode(bookData['imageUrl']),
                    height: 200,
                    fit: BoxFit.contain,
                  ),
                ),
              const SizedBox(height: 16),
              Text('Titre: ${bookData['title'] ?? 'Non spécifié'}'),
              Text('Auteur: ${bookData['author'] ?? 'Non spécifié'}'),
              Text('Description: ${bookData['description'] ?? 'Non spécifié'}'),
              Text('Catégorie: ${bookData['category'] ?? 'Non spécifié'}'),
              Text('Prix: ${bookData['price'] ?? '0'} FCFA'),
              Text('Pages: ${bookData['pages'] ?? '0'}'),
              Text('Note: ${bookData['rating'] ?? '0'}/100'),
              Text('Publié par: ${bookData['publisherName'] ?? 'Anonyme'}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  void _deleteBook(String bookId, String bookTitle) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text('Êtes-vous sûr de vouloir supprimer le livre "$bookTitle"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              try {
                await _firestore.collection('books').doc(bookId).delete();
                Navigator.pop(context);
                AppUtils.showSuccessSnackBar(context, 'Livre supprimé avec succès');
              } catch (e) {
                AppUtils.showErrorSnackBar(context, 'Erreur: $e');
              }
            },
            child: const Text('Supprimer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
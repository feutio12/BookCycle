import 'package:cloud_firestore/cloud_firestore.dart';

class Book {
  final String id;
  final String title;
  final String author;
  final String publisherId;
  final List<String> categories; // Changé de String à List<String>
  final String? imageUrl;
  final String? description; // Ajout de la description

  Book({
    required this.id,
    required this.title,
    required this.author,
    required this.publisherId,
    required this.categories, // Modifié pour accepter une liste
    this.imageUrl,
    this.description,
  });

  factory Book.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Book(
      id: doc.id,
      title: data['title'] ?? '',
      author: data['author'] ?? '',
      publisherId: data['publisherId'] ?? '',
      categories: List<String>.from(data['categories'] ?? []), // Conversion en List<String>
      imageUrl: data['imageUrl'],
      description: data['description'],
    );
  }
}
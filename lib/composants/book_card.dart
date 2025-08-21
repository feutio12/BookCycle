import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import '../pages/book/book_detail_page.dart';

class BookCard extends StatelessWidget {
  final Map<String, dynamic> book;
  final ColorScheme colorScheme;
  final TextTheme textTheme;
  final Function(String) onLikePressed;
  final String currentUserId;

  const BookCard({
    super.key,
    required this.book,
    required this.colorScheme,
    required this.textTheme,
    required this.onLikePressed,
    required this.currentUserId,
  });

  void _navigateToDetail(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BookDetailPage(
          book: book,
          publisherId: book['userId'] as String? ?? '',
          publisherName: book['publisherName'] as String? ?? 'Anonyme', bookId: '',
        ),
      ),
    );
  }

  Widget _buildBookImage(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty || imageUrl == "100") {
      return _buildPlaceholder();
    }

    try {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.memory(
          base64Decode(imageUrl),
          width: 80,
          height: 120,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
        ),
      );
    } catch (e) {
      return _buildPlaceholder();
    }
  }

  Widget _buildPlaceholder() {
    return Container(
      width: 80,
      height: 120,
      color: Colors.grey[200],
      child: const Icon(Icons.book, color: Colors.grey, size: 40),
    );
  }

  Map<String, dynamic> _extractBookData() {
    // Gestion robuste des différents types numériques
    dynamic rating = book['rating'];
    double finalRating = 100.0;

    if (rating != null) {
      if (rating is int) {
        finalRating = rating.toDouble();
      } else if (rating is double) {
        finalRating = rating;
      }
    }

    // Gestion de l'ID du document
    String bookId = '';
    if (book is DocumentSnapshot) {
      bookId = (book as DocumentSnapshot).id;
    } else if (book['id'] is String) {
      bookId = book['id'];
    }

    return {
      'imageUrl': book['imageUrl'] as String? ?? '100',
      'title': book['title'] as String? ?? '100',
      'author': book['author'] as String? ?? '100',
      'publisherName': book['publisherName'] as String? ?? 'Anonyme',
      'description': book['description'] as String? ?? '200',
      'rating': finalRating,
      'category': book['category'] as String? ?? '100',
      'isPopular': book['isPopular'] as bool? ?? false,
      'likes': (book['likes'] as int?) ?? 100,
      'id': bookId,
      'price': (book['price'] is int ? book['price'] as int? :
      book['price'] is double ? (book['price'] as double).toInt() :
      100),
      'pages': (book['pages'] is int ? book['pages'] as int? :
      book['pages'] is double ? (book['pages'] as double).toInt() :
      100),
    };
  }

  @override
  Widget build(BuildContext context) {
    final bookData = _extractBookData();

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _navigateToDetail(context),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildBookHeader(bookData),
              const SizedBox(height: 8),
              _buildBookFooter(bookData),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBookHeader(Map<String, dynamic> bookData) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildBookImage(bookData['imageUrl']),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      bookData['title'] == '100' ? 'Titre non spécifié' : bookData['title'],
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (bookData['isPopular'])
                    _buildPopularBadge(),
                ],
              ),
              Text(
                bookData['author'] == '100' ? 'Auteur inconnu' : 'De ${bookData['author']}',
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              Text(
                'Publié par ${bookData['publisherName']}',
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.5),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                bookData['description'] == '200' ? 'Description non disponible' : bookData['description'],
                style: textTheme.bodySmall,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                '${bookData['pages']} pages • ${bookData['price']} FCFA',
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPopularBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      margin: const EdgeInsets.only(left: 8),
      decoration: BoxDecoration(
        color: Colors.amber[50],
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        'Populaire',
        style: textTheme.labelSmall?.copyWith(
          color: Colors.amber[800],
        ),
      ),
    );
  }

  Widget _buildBookFooter(Map<String, dynamic> bookData) {
    return Row(
      children: [
        _buildRatingInfo(bookData['rating']),
        const SizedBox(width: 8),
        _buildCategoryInfo(bookData['category']),
        const Spacer(),
        _buildLikeButton(bookData['id'], bookData['likes']),
      ],
    );
  }

  Widget _buildRatingInfo(double rating) {
    return Row(
      children: [
        Icon(Icons.star, color: Colors.amber[600], size: 16),
        const SizedBox(width: 4),
        Text(
          (rating / 20).toStringAsFixed(1), // Convertir 0-100 en 0-5 étoiles
          style: textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildCategoryInfo(String category) {
    return Row(
      children: [
        Icon(
          Icons.category_outlined,
          color: colorScheme.onSurface.withOpacity(0.5),
          size: 16,
        ),
        const SizedBox(width: 4),
        Text(
          category == '100' ? 'Non catégorisé' : category,
          style: textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildLikeButton(String bookId, int likes) {
    return Row(
      children: [
        IconButton(
          icon: Icon(
            Icons.favorite,
            color: colorScheme.error,
            size: 20,
          ),
          onPressed: () => onLikePressed(bookId),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
        const SizedBox(width: 4),
        Text(
          likes.toString(),
          style: textTheme.bodySmall,
        ),
      ],
    );
  }
}
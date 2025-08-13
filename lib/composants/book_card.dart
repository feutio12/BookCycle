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
          publisherId: book['publisherId'] as String? ?? '',
          publisherName: book['publisherName'] as String? ?? 'Anonyme',
        ),
      ),
    );
  }

  Widget _buildBookImage(String? imageBase64) {
    if (imageBase64 == null || imageBase64.isEmpty) {
      return _buildPlaceholder();
    }

    try {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.memory(
          base64Decode(imageBase64),
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

  Widget _buildPlaceholder({bool loading = false, double? progress, double? total}) {
    return Container(
      width: 80,
      height: 120,
      color: Colors.grey[200],
      child: Stack(
        alignment: Alignment.center,
        children: [
          const Icon(Icons.book, color: Colors.grey, size: 40),
          if (loading && progress != null && total != null)
            CircularProgressIndicator(
              value: progress / total,
              color: Colors.grey[600],
            ),
        ],
      ),
    );
  }

  Map<String, dynamic> _extractBookData() {
    return {
      'imageBase64': book['imageBase64'] as String? ?? '',
      'title': book['title'] as String? ?? 'Titre inconnu',
      'author': book['author'] as String? ?? 'Auteur inconnu',
      'publisherName': book['publisherName'] as String? ?? 'Anonyme',
      'description': book['description'] as String? ?? 'Description non disponible',
      'rating': (book['rating'] as num?)?.toDouble() ?? 0.0,
      'category': book['category'] as String? ?? 'Non catégorisé',
      'isPopular': book['isPopular'] as bool? ?? false,
      'isLiked': book['isLiked'] as bool? ?? false,
      'likes': (book['likes'] as int?) ?? 0,
      'id': book['id'] as String? ?? '',
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
        _buildBookImage(bookData['imageBase64']),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      bookData['title'],
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
                'De ${bookData['author']}',
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
                bookData['description'],
                style: textTheme.bodySmall,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
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
        _buildLikeButton(bookData['id'], bookData['isLiked'], bookData['likes']),
      ],
    );
  }

  Widget _buildRatingInfo(double rating) {
    return Row(
      children: [
        Icon(Icons.star, color: Colors.amber[600], size: 16),
        const SizedBox(width: 4),
        Text(
          rating.toStringAsFixed(1),
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
          category,
          style: textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildLikeButton(String bookId, bool isLiked, int likes) {
    return Row(
      children: [
        IconButton(
          icon: Icon(
            isLiked ? Icons.favorite : Icons.favorite_border,
            color: isLiked ? colorScheme.error : null,
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
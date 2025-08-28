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
          publisherName: book['publisherName'] as String? ?? 'Anonyme',
          bookId: book['id'] ?? '',
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
        borderRadius: BorderRadius.circular(12),
        child: Image.memory(
          base64Decode(imageUrl),
          width: 90,
          height: 130,
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
      width: 90,
      height: 130,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.grey[100]!,
            Colors.grey[200]!,
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Icon(Icons.menu_book_rounded,
          color: Colors.grey[400],
          size: 40),
    );
  }

  Map<String, dynamic> _extractBookData() {
    dynamic rating = book['rating'];
    double finalRating = 0.0;

    if (rating != null) {
      if (rating is int) {
        finalRating = rating.toDouble();
      } else if (rating is double) {
        finalRating = rating;
      }
    }

    String bookId = '';
    if (book is DocumentSnapshot) {
      bookId = (book as DocumentSnapshot).id;
    } else if (book['id'] is String) {
      bookId = book['id'];
    }

    return {
      'imageUrl': book['imageUrl'] as String? ?? '100',
      'title': book['title'] as String? ?? 'Titre non spécifié',
      'author': book['author'] as String? ?? 'Auteur inconnu',
      'publisherName': book['publisherName'] as String? ?? 'Anonyme',
      'description': book['description'] as String? ?? 'Description non disponible',
      'rating': finalRating,
      'category': book['category'] as String? ?? 'Non catégorisé',
      'isPopular': book['isPopular'] as bool? ?? false,
      'likes': (book['likes'] as int?) ?? 0,
      'id': bookId,
      'price': (book['price'] is int ? book['price'] as int? :
      book['price'] is double ? (book['price'] as double).toInt() : 0),
      'pages': (book['pages'] is int ? book['pages'] as int? :
      book['pages'] is double ? (book['pages'] as double).toInt() : 0),
      'condition': book['condition'] as String? ?? 'Bon état',
      'type': book['type'] as String? ?? 'Échange',
    };
  }

  @override
  Widget build(BuildContext context) {
    final bookData = _extractBookData();
    final starRating = bookData['rating'] > 0 ? (bookData['rating'] / 20).toStringAsFixed(1) : '0.0';

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1976D2).withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _navigateToDetail(context),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // En-tête avec badge populaire
                if (bookData['isPopular'])
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFFD700), Color(0xFFFFC400)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '🌟 POPULAIRE',
                      style: textTheme.labelSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 10,
                        letterSpacing: 1,
                      ),
                    ),
                  ),

                // Contenu principal
                Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Image du livre
                        Hero(
                          tag: 'book-${bookData['id']}',
                          child: _buildBookImage(bookData['imageUrl']),

                        ),

                        const SizedBox(width: 10),

                        // Détails du livre
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Titre et auteur
                              Text(
                                bookData['title'],
                                style: textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 18,
                                  color: const Color(0xFF1A237E),
                                  height: 1.3,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),

                              const SizedBox(height: 4),

                              Text(
                                'par ${bookData['author']}',
                                style: textTheme.bodyMedium?.copyWith(
                                  color: const Color(0xFF546E7A),
                                  fontWeight: FontWeight.w500,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),

                              const SizedBox(height: 8),

                              // État et type
                              Row(
                                children: [
                                  _buildInfoChip(
                                    Icons.auto_awesome_rounded,
                                    bookData['condition'],
                                    const Color(0xFF1976D2),
                                  ),
                                  const SizedBox(width: 8),
                                  _buildInfoChip(
                                    bookData['type'] == 'Échange'
                                        ? Icons.swap_horiz_rounded
                                        : Icons.attach_money_rounded,
                                    bookData['type'],
                                    const Color(0xFF4CAF50),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 12),

                              // Description
                              Text(
                                bookData['description'],
                                style: textTheme.bodySmall?.copyWith(
                                  color: const Color(0xFF607D8B),
                                  height: 1.5,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),

                              const SizedBox(height: 12),

                              // Footer avec prix, pages et actions

                            ],
                          ),
                        ),
                      ],
                    ),


                    Row(
                      children: [
                        // Pages
                        Expanded(
                          child: Row(
                            //crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${bookData['price']} FCFA',
                                style: textTheme.bodyLarge?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF1976D2),
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Note et likes
                        Row(
                          children: [
                            _buildRatingStars(bookData['rating']),
                            const SizedBox(width: 16),
                            _buildLikeButton(bookData['id'], bookData['likes']),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),

                // Publié par
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text(
                      'Publié par ${bookData['publisherName']}',
                      style: textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF90A4AE),
                        fontStyle: FontStyle.italic,
                      ),
                    ),Spacer(),
                    Text(
                      '${bookData['pages']} pages',
                      style: textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF78909C),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingStars(double rating) {
    final starCount = (rating / 20).clamp(0, 5).toInt();
    return Row(
      children: [
        Icon(Icons.star_rounded,
            size: 18,
            color: starCount > 0 ? Colors.amber : Colors.grey[300]),
        const SizedBox(width: 2),
        Text(
          (rating / 20).toStringAsFixed(1),
          style: textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: Colors.amber[800],
          ),
        ),
      ],
    );
  }

  Widget _buildLikeButton(String bookId, int likes) {
    final isLiked = book['isLiked'] ?? false;

    return InkWell(
      onTap: () => onLikePressed(bookId),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isLiked
              ? Colors.pink.withOpacity(0.15)
              : Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isLiked
                ? Colors.pink.withOpacity(0.3)
                : Colors.grey.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              size: 18,
              color: isLiked ? Colors.pink[400] : Colors.grey[500],
            ),
            const SizedBox(width: 4),
            Text(
              likes.toString(),
              style: textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: isLiked ? Colors.pink[600] : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'dart:convert';

class BookCard extends StatelessWidget {
  final Map<String, dynamic> book;
  final ColorScheme colorScheme;
  final TextTheme textTheme;
  final Function(String) onLikePressed;
  final String currentUserId;
  final Function(String) onDeleteBook;
  final Function(Map<String, dynamic>) onEditBook;
  final Function(String, String, String) onContactPublisher; // Nouveau callback

  const BookCard({
    super.key,
    required this.book,
    required this.colorScheme,
    required this.textTheme,
    required this.onLikePressed,
    required this.currentUserId,
    required this.onDeleteBook,
    required this.onEditBook,
    required this.onContactPublisher, // Nouveau paramètre

  });

  void _showBookDetails(BuildContext context) {
    final bookData = _extractBookData();
    final isOwner = currentUserId == book['publisherEmail']; // Vérification par email

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          margin: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle pour glisser
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              bookData['title'],
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                                color: Color(0xFF1A237E),
                              ),
                            ),
                          ),
                          if (isOwner)
                            IconButton(
                              icon: const Icon(Icons.close, color: Colors.grey),
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Image du livre
                      Center(
                        child: _buildBookImage(bookData['imageUrl'], size: 150),
                      ),
                      const SizedBox(height: 16),

                      // Auteur
                      Text(
                        'Auteur: ${bookData['author']}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 16,
                          color: Color(0xFF546E7A),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Description
                      Text(
                        'Description:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[700],
                        ),
                      ),
                      Text(bookData['description']),
                      const SizedBox(height: 12),

                      // Catégorie
                      Text(
                        'Catégorie: ${bookData['category']}',
                        style: TextStyle(
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),

                      // État
                      Text(
                        'État: ${bookData['condition']}',
                        style: TextStyle(
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Type
                      Text(
                        'Type: ${bookData['type']}',
                        style: TextStyle(
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Pages
                      Text(
                        'Pages: ${bookData['pages']}',
                        style: TextStyle(
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Prix
                      Text(
                        'Prix: ${bookData['price']} FCFA',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1976D2),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Note
                      Row(
                        children: [
                          _buildRatingStars(bookData['rating']),
                          const SizedBox(width: 8),
                          Text(
                            '(${(bookData['rating'] / 20).toStringAsFixed(1)})',
                            style: TextStyle(
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),

              // Boutons d'action
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  border: Border(top: BorderSide(color: Colors.grey[200]!)),
                ),
                child: Row(
                  children: [
                    if (isOwner) ...[
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            onEditBook(book);
                          },
                          icon: const Icon(Icons.edit, size: 18),
                          label: const Text('Modifier'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            onDeleteBook(bookData['id']);
                          },
                          icon: const Icon(Icons.delete, size: 18),
                          label: const Text('Supprimer'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ] else ...[
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            onContactPublisher(
                              book['publisherEmail'],
                              book['publisherName'],
                              bookData['title'],
                            );
                          },
                          icon: const Icon(Icons.chat, size: 18),
                          label: const Text('Contacter'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Fermer'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBookImage(String? imageUrl, {double size = 90}) {
    if (imageUrl == null || imageUrl.isEmpty || imageUrl == "100") {
      return _buildPlaceholder(size: size);
    }

    try {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.memory(
          base64Decode(imageUrl),
          width: size,
          height: size * 1.44,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildPlaceholder(size: size),
        ),
      );
    } catch (e) {
      return _buildPlaceholder(size: size);
    }
  }

  Widget _buildPlaceholder({double size = 90}) {
    return Container(
      width: size,
      height: size * 1.44,
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
    final starRating = bookData['rating'] > 0 ? (bookData['rating'] / 10).toStringAsFixed(1) : '0.0';

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
          onTap: () => _showBookDetails(context),
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
                        _buildBookImage(bookData['imageUrl']),

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
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: [
                                    _buildInfoChip(
                                      Icons.auto_awesome_rounded,
                                      bookData['condition'],
                                      const Color(0xFF1976D2),
                                    ),
                                    const SizedBox(width: 6),
                                    _buildInfoChip(
                                      bookData['type'] == 'Échange'
                                          ? Icons.swap_horiz_rounded
                                          : Icons.attach_money_rounded,
                                      bookData['type'],
                                      const Color(0xFF4CAF50),
                                    ),
                                  ],
                                ),
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
                            ],
                          ),
                        ),
                      ],
                    ),

                    Row(
                      children: [
                        // Prix
                        Expanded(
                          child: Text(
                            '${bookData['price']} FCFA',
                            style: textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF1976D2),
                              fontSize: 16,
                            ),
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

                // Publié par et pages
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text(
                      'Publié par ${bookData['publisherName']}',
                      style: textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF90A4AE),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const Spacer(),
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
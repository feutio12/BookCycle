import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'dart:convert';

import '../../composants/CustomButtom.dart';
import '../../composants/common_components.dart';

class BookCard extends StatelessWidget {
  final Map<String, dynamic> book;
  final ColorScheme colorScheme;
  final TextTheme textTheme;
  final Function(String) onLikePressed;
  final String currentUserId;
  final Function(String) onDeleteBook;
  final Function(Map<String, dynamic>) onEditBook;
  final Function(String, String, String) onContactPublisher;

  const BookCard({
    super.key,
    required this.book,
    required this.colorScheme,
    required this.textTheme,
    required this.onLikePressed,
    required this.currentUserId,
    required this.onDeleteBook,
    required this.onEditBook,
    required this.onContactPublisher,
  });

  @override
  Widget build(BuildContext context) {
    final bookData = _extractBookData();

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
          onTap: () => _showBookDetails(context, bookData),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // En-tête avec badge populaire
                if (bookData['isPopular']) _buildPopularBadge(),

                // Contenu principal
                _buildBookContent(bookData),

                // Publié par et pages
                const SizedBox(height: 12),
                _buildFooter(bookData),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Méthodes helper pour organiser le code
  Widget _buildPopularBadge() {
    return Container(
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
    );
  }

  Widget _buildBookContent(Map<String, dynamic> bookData) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image du livre
            _buildBookImage(bookData['imageUrl'], size: 80, height: 100),

            const SizedBox(width: 16),

            // Détails du livre
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTitleAuthorSection(bookData),
                  const SizedBox(height: 8),
                  _buildConditionTypeChips(bookData),
                  const SizedBox(height: 12),
                  _buildDescription(bookData),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),
        _buildPriceRatingSection(bookData),
      ],
    );
  }

  Widget _buildTitleAuthorSection(Map<String, dynamic> bookData) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
      ],
    );
  }

  Widget _buildConditionTypeChips(Map<String, dynamic> bookData) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
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
    );
  }

  Widget _buildDescription(Map<String, dynamic> bookData) {
    return Text(
      bookData['description'],
      style: textTheme.bodySmall?.copyWith(
        color: const Color(0xFF607D8B),
        height: 1.5,
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildPriceRatingSection(Map<String, dynamic> bookData) {
    return Row(
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
    );
  }

  Widget _buildFooter(Map<String, dynamic> bookData) {
    return Row(
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
    );
  }

  Widget _buildInfoChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
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
        Icon(
          Icons.star_rounded,
          size: 18,
          color: starCount > 0 ? Colors.amber : Colors.grey[300],
        ),
        const SizedBox(width: 4),
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
            const SizedBox(width: 6),
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

  Widget _buildBookImage(String? base64Data, {double size = 80, double height = 100}) {
    return Container(
      width: size,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: base64Data != null && base64Data.isNotEmpty
            ? Image.memory(
          base64.decode(base64Data),
          fit: BoxFit.cover,
          width: size,
          height: height,
          errorBuilder: (context, error, stackTrace) {
            return _buildPlaceholderIcon();
          },
        )
            : _buildPlaceholderIcon(),
      ),
    );
  }

  Widget _buildPlaceholderIcon() {
    return Container(
      color: Colors.grey[200],
      child: const Icon(Icons.book, color: Colors.grey, size: 32),
    );
  }

  void _showBookDetails(BuildContext context, Map<String, dynamic> bookData) {
    final isOwner = currentUserId == book['publisherEmail'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return _buildBookDetailsModal(bookData, isOwner, context);
      },
    );
  }

  Widget _buildBookDetailsModal(Map<String, dynamic> bookData, bool isOwner, BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      margin: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 40,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildDragHandle(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildModalHeader(bookData, isOwner, context),
                  const SizedBox(height: 16),
                  _buildModalImage(bookData),
                  const SizedBox(height: 20),
                  _buildInfoGrid(bookData),
                  const SizedBox(height: 20),
                  _buildRatingSection(bookData),
                  const SizedBox(height: 16),
                  _buildDescriptionSection(bookData),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          _buildActionButtons(bookData, isOwner, context),
        ],
      ),
    );
  }

  Widget _buildDragHandle() {
    return Container(
      width: 60,
      height: 6,
      margin: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }

  Widget _buildModalHeader(Map<String, dynamic> bookData, bool isOwner, BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            bookData['title'],
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 22,
              color: AppColors.textPrimary,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (isOwner)
          IconButton(
            icon: const Icon(Icons.close, color: AppColors.textSecondary),
            onPressed: () => Navigator.of(context).pop(),
          ),
      ],
    );
  }

  Widget _buildModalImage(Map<String, dynamic> bookData) {
    return Center(
      child: _buildBookImage(
        bookData['imageUrl'],
        size: 180,
        height: 200,
      ),
    );
  }

  Widget _buildInfoGrid(Map<String, dynamic> bookData) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 3,
      crossAxisSpacing: 12,
      mainAxisSpacing: 8,
      children: [
        _buildInfoItem(
          icon: Icons.person,
          label: 'Auteur',
          value: bookData['author'],
        ),
        _buildInfoItem(
          icon: Icons.category,
          label: 'Catégorie',
          value: bookData['category'],
        ),
        _buildInfoItem(
          icon: Icons.auto_awesome,
          label: 'État',
          value: bookData['condition'],
        ),
        _buildInfoItem(
          icon: Icons.type_specimen,
          label: 'Type',
          value: bookData['type'],
        ),
        _buildInfoItem(
          icon: Icons.library_books,
          label: 'Pages',
          value: '${bookData['pages']}',
        ),
        _buildInfoItem(
          icon: Icons.attach_money,
          label: 'Prix',
          value: '${bookData['price']} FCFA',
          valueColor: AppColors.success,
        ),
      ],
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: SingleChildScrollView(
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppColors.primaryBlue),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: valueColor ?? AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingSection(Map<String, dynamic> bookData) {
    return Row(
      children: [
        const Icon(Icons.star, color: Colors.amber, size: 20),
        const SizedBox(width: 8),
        Text(
          '${(bookData['rating'] / 20).toStringAsFixed(1)}',
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildDescriptionSection(Map<String, dynamic> bookData) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Description',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          bookData['description'],
          style: const TextStyle(
            color: AppColors.textSecondary,
            height: 1.7,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(Map<String, dynamic> bookData, bool isOwner, BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        border: Border(top: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Row(
        children: [
          if (isOwner) ...[
            Expanded(
              child: CustomButton(
                text: 'Modifier',
                onPressed: () {
                  Navigator.pop(context);
                  onEditBook(book);
                },
                backgroundColor: AppColors.primaryBlue,
                textColor: Colors.white,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: CustomButton(
                text: 'Supprimer',
                onPressed: () {
                  Navigator.pop(context);
                  onDeleteBook(bookData['id']);
                },
                backgroundColor: AppColors.error,
                textColor: Colors.white,
              ),
            ),
          ] else ...[
            Expanded(
              child: CustomButton(
                text: 'Contacter',
                onPressed: () {
                  Navigator.pop(context);
                  onContactPublisher(
                    book['publisherEmail'],
                    book['publisherName'],
                    bookData['title'],
                  );
                },
                backgroundColor: AppColors.success,
                textColor: Colors.white,
              ),
            ),
          ],
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                side: BorderSide(color: AppColors.primaryBlue),
              ),
              child: const Text(
                'Fermer',
                style: TextStyle(color: AppColors.primaryBlue),
              ),
            ),
          ),
        ],
      ),
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
      'imageUrl': book['imageUrl'] as String? ?? '',
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
      book['price'] is double ? (book['price'] as double).toInt() : 0) ?? 0,
      'pages': (book['pages'] is int ? book['pages'] as int? :
      book['pages'] is double ? (book['pages'] as double).toInt() : 0) ?? 0,
      'condition': book['condition'] as String? ?? 'Bon état',
      'type': book['type'] as String? ?? 'Échange',
    };
  }
}
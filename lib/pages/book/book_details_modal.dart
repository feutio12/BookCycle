import 'package:flutter/material.dart';
import 'dart:convert';

import '../../composants/CustomButtom.dart';
import '../../composants/common_components.dart';

class BookDetailsModal extends StatelessWidget {
  final Map<String, dynamic> book;
  final Map<String, dynamic> bookData;
  final bool isOwner;
  final String currentUserId;
  final Function(Map<String, dynamic>) onEditBook;
  final Function(String) onDeleteBook;
  final Function(BuildContext) onContactPublisher;

  const BookDetailsModal({
    super.key,
    required this.book,
    required this.bookData,
    required this.isOwner,
    required this.currentUserId,
    required this.onEditBook,
    required this.onDeleteBook,
    required this.onContactPublisher,
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 30,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDragHandle(),
              Expanded(
                child: CustomScrollView(
                  controller: scrollController,
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildModalHeader(context),
                            const SizedBox(height: 16),
                            _buildModalImage(),
                            const SizedBox(height: 20),
                            _buildInfoGrid(),
                            const SizedBox(height: 20),
                            _buildRatingSection(),
                            const SizedBox(height: 16),
                            _buildDescriptionSection(),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              _buildActionButtons(context),
            ],
          ),
        );
      },
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

  Widget _buildModalHeader(BuildContext context) {
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

  Widget _buildModalImage() {
    return Hero(
      tag: 'book-image-${book['id']}',
      child: Material(
        color: Colors.transparent,
        child: _buildBookImage(
          bookData['imageUrl'],
          size: 180,
          height: 200,
        ),
      ),
    );
  }

  Widget _buildBookImage(String? base64Data, {double size = 180, double height = 200}) {
    return Container(
      width: size,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
            spreadRadius: 0.5,
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
      child: const Icon(Icons.book, color: Colors.grey, size: 48),
    );
  }

  Widget _buildInfoGrid() {
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
    );
  }

  Widget _buildRatingSection() {
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

  Widget _buildDescriptionSection() {
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

  Widget _buildActionButtons(BuildContext context) {
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
                  onContactPublisher(context);
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
}
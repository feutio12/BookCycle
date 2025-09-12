import 'dart:io';

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';

// Couleurs du thème
class AppColors {
  static const Color primaryBlue = Color(0xFF1976D2);
  static const Color lightBlue = Color(0xFFBBDEFB);
  static const Color accentGreen = Color(0xFF4CAF50);
  static const Color lightGreen = Color(0xFFC8E6C9);
  static const Color darkBlue = Color(0xFF0D47A1);
  static const Color backgroundColor = Color(0xFFE3F2FD);
  static const Color errorRed = Color(0xFFD32F2F);
  static const Color warningOrange = Color(0xFFF57C00);
  static const Color successGreen = Color(0xFF2E7D32);
  static const Color primaryDarkBlue = Color(0xFF1976D2);
  static const Color primaryLightBlue = Color(0xFFBBDEFB);
  static const Color accentLightGreen = Color(0xFFC8E6C9);
  static const Color backgroundLight = Color(0xFFF5F9FF);
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF263238);
  static const Color textSecondary = Color(0xFF78909C);
  static const Color success = Color(0xFF66BB6A);
  static const Color warning = Color(0xFFFFA726);
  static const Color error = Color(0xFFEF5350);
  static const backgroundGray = Color(0xFFF8FAFC);
}


// Styles de texte communs
class AppTextStyles {
  static const TextStyle titleLarge = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: Colors.white,
  );

  static const TextStyle headlineSmall = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: AppColors.darkBlue,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    color: Color(0xFF424242),
  );

  static const TextStyle buttonText = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    letterSpacing: 0.5,
  );
}


// Composant de bouton principal
class PrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isLoading;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final IconData? icon;

  const PrimaryButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.backgroundColor = AppColors.accentGreen,
    this.foregroundColor = Colors.white,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
        child: isLoading
            ? const CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation(Colors.white),
        )
            : Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 20),
              const SizedBox(width: 8),
            ],
            Text(
              text,
              style: AppTextStyles.buttonText,
            ),
          ],
        ),
      ),
    );
  }
}


// Composant de champ de formulaire
class FormTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? Function(String?)? validator;
  final bool isNumber;
  final int? maxLines;
  final TextInputType? keyboardType;

  const FormTextField({
    super.key,
    required this.controller,
    required this.label,
    this.validator,
    this.isNumber = false,
    this.maxLines = 1,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.primaryBlue),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: AppColors.primaryBlue.withOpacity(0.5)),
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: AppColors.primaryBlue, width: 2),
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      style: const TextStyle(color: AppColors.darkBlue, fontWeight: FontWeight.w500),
      keyboardType: keyboardType ?? (isNumber ? TextInputType.number : TextInputType.text),
      maxLines: maxLines,
      validator: validator,
    );
  }
}


// Composant de sélecteur d'image
class ImagePickerWidget extends StatelessWidget {
  final File? imageFile;
  final VoidCallback onTap;
  final String? errorMessage;

  const ImagePickerWidget({
    super.key,
    this.imageFile,
    required this.onTap,
    this.errorMessage, String? existingImageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            height: 200,
            decoration: BoxDecoration(
              color: AppColors.lightBlue,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.primaryBlue, width: 2),
              image: imageFile != null
                  ? DecorationImage(image: FileImage(imageFile!), fit: BoxFit.cover)
                  : null,
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: imageFile == null
                ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_a_photo, size: 50, color: AppColors.primaryBlue),
                  SizedBox(height: 12),
                  Text(
                    'Ajouter une image',
                    style: TextStyle(
                      color: AppColors.primaryBlue,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Cliquez pour sélectionner',
                    style: TextStyle(
                      color: AppColors.primaryBlue,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            )
                : null,
          ),
        ),
        if (errorMessage != null)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: ErrorMessage(message: errorMessage!),
          ),
      ],
    );
  }
}


// Composant de message d'erreur
class ErrorMessage extends StatelessWidget {
  final String message;

  const ErrorMessage({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red[700]),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: Colors.red[700]),
            ),
          ),
        ],
      ),
    );
  }
}

// Composant de message d'information
class InfoMessage extends StatelessWidget {
  final String message;
  final IconData icon;
  final Color color;

  const InfoMessage({
    super.key,
    required this.message,
    this.icon = Icons.info_outline,
    this.color = AppColors.accentGreen,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: AppColors.darkBlue,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Composant de chargement
class LoadingIndicator extends StatelessWidget {
  final String message;

  const LoadingIndicator({super.key, this.message = 'Chargement...'});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation(AppColors.accentGreen),
          ),
          const SizedBox(height: 20),
          Text(
            message,
            style: const TextStyle(
              color: AppColors.primaryBlue,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// Composant de carte de livre
class BookCard extends StatelessWidget {
  final Map<String, dynamic> book;
  final VoidCallback onTap;
  final VoidCallback? onLikePressed;
  final bool isLiked;
  final String currentUserId;

  const BookCard({
    super.key,
    required this.book,
    required this.onTap,
    this.onLikePressed,
    this.isLiked = false,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    final title = book['title'] ?? 'Titre inconnu';
    final author = book['author'] ?? 'Auteur inconnu';
    final imageUrl = book['imageUrl'] ?? '';
    final rating = (book['rating'] as num?)?.toDouble() ?? 0.0;
    final likes = book['likes'] ?? 0;
    final price = book['price'] ?? 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image du livre
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: imageUrl.isNotEmpty
                    ? CachedNetworkImage(
                  imageUrl: imageUrl,
                  width: 80,
                  height: 100,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    width: 80,
                    height: 100,
                    color: Colors.grey[200],
                  ),
                  errorWidget: (context, url, error) => Container(
                    width: 80,
                    height: 100,
                    color: Colors.grey[200],
                    child: const Icon(Icons.book, color: Colors.grey),
                  ),
                )
                    : Container(
                  width: 80,
                  height: 100,
                  color: Colors.grey[200],
                  child: const Icon(Icons.book, color: Colors.grey),
                ),
              ),
              const SizedBox(width: 12),
              // Informations du livre
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      author,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Rating et likes
                    Row(
                      children: [
                        const Icon(Icons.star, size: 16, color: Colors.amber),
                        const SizedBox(width: 4),
                        Text(rating.toStringAsFixed(1)),
                        const SizedBox(width: 16),
                        IconButton(
                          icon: Icon(
                            isLiked ? Icons.favorite : Icons.favorite_border,
                            color: isLiked ? Colors.red : Colors.grey,
                            size: 20,
                          ),
                          onPressed: onLikePressed,
                        ),
                        Text('$likes'),
                      ],
                    ),
                    if (price > 0)
                      Text(
                        '$price €',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
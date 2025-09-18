import 'dart:convert';
import 'package:bookcycle/pages/chats/chatpage.dart';
import 'package:bookcycle/pages/chats/chat_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../composants/common_components.dart';
import '../../composants/common_utils.dart';
import 'edit_book_page.dart';

class BookDetailPage extends StatelessWidget {
  final Map<String, dynamic> book;
  final String publisherId;
  final String publisherName;
  final String bookId;

  const BookDetailPage({
    super.key,
    required this.book,
    required this.publisherId,
    required this.publisherName,
    required this.bookId, required publisherEmail,
  });

  String _getString(String key, [String defaultValue = 'Non spécifié']) {
    return book[key]?.toString() ?? defaultValue;
  }

  double _getDouble(String key, [double defaultValue = 0.0]) {
    return (book[key] as num?)?.toDouble() ?? defaultValue;
  }

  // Modifier _startChatWithPublisher
  Future<void> _startChatWithPublisher(BuildContext context, String bookTitle) async {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      AppUtils.showLoginRequiredSnackBar(context, 'contacter le publicateur');
      return;
    }

    // Vérifier si l'utilisateur essaie de se contacter lui-même
    if (currentUser.uid == publisherId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vous ne pouvez pas vous contacter vous-même')),
      );
      return;
    }

    // Utiliser le vrai userId du livre
    final bookUserId = book['userId'];
    if (bookUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impossible de contacter le vendeur - userId manquant')),
      );
      return;
    }

    final chatId = ChatService.generateChatId(currentUser.uid, bookUserId);
    final initialMessage = 'Bonjour, je suis intéressé par votre livre "$bookTitle"';

    try {
      // Créer le chat s'il n'existe pas
      await ChatService.createChatIfNeeded(
        chatId: chatId,
        otherUserId: bookUserId, // Utiliser le vrai userId
        otherUserName: publisherName,
      );

      // Naviguer vers la page de chat
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => ChatPage(
            chatId: chatId,
            otherUserId: bookUserId, // Utiliser le vrai userId
            otherUserName: publisherName,
            initialMessage: initialMessage,
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la création du chat: $e')),
      );
    }
  }

  Future<void> _editBook(BuildContext context) async {
    // Navigation vers la page d'édition du livre
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditBookPage(
          bookId: bookId,
          bookData: book,
        ),
      ),
    );
  }

  Future<void> _deleteBook(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: const Text('Êtes-vous sûr de vouloir supprimer ce livre ? Cette action est irréversible.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        // Supprimer le livre de Firestore
        await FirebaseFirestore.instance
            .collection('books')
            .doc(bookId)
            .delete();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Livre supprimé avec succès')),
        );

        // Retourner à la page précédente
        Navigator.of(context).pop();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la suppression: $e')),
        );
      }
    }
  }

  Widget _buildBookImage(String? imageUrl, {String? heroTag}) {
    final imageWidget = (imageUrl == null || imageUrl.isEmpty || imageUrl == "100")
        ? _buildPlaceholder()
        : _buildImageFromBase64(imageUrl);

    return heroTag != null
        ? Hero(tag: heroTag, child: imageWidget)
        : imageWidget;
  }

  Widget _buildImageFromBase64(String imageUrl) {
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

  Widget _buildBookHeader(ThemeData theme, String imageUrl, String title, double rating, {String? heroTag}) {
    final author = _getString('author', 'Auteur inconnu');
    final publisherEmail = _getString('publisherEmail', 'Email non disponible');
    final currentUser = FirebaseAuth.instance.currentUser;
    final isOwner = currentUser != null && currentUser.email == publisherEmail;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildBookImage(imageUrl, heroTag: heroTag),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text('Par $author', style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.7))),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.star, color: Colors.amber, size: 20),
                  const SizedBox(width: 4),
                  Text(rating.toStringAsFixed(1), style: theme.textTheme.bodyLarge),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Publié par $publisherName',
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.primary),
              ),
              if (isOwner) ...[
                const SizedBox(height: 8),
                Text(
                  '(Votre publication)',
                  style: theme.textTheme.bodySmall?.copyWith(color: Colors.green),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context, String bookTitle) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final publisherEmail = _getString('publisherEmail', '');
    final isOwner = currentUser != null && currentUser.email == publisherEmail;

    if (isOwner) {
      return Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              icon: const Icon(Icons.edit),
              label: const Text('Modifier'),
              onPressed: () => _editBook(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              icon: const Icon(Icons.delete),
              label: const Text('Supprimer'),
              onPressed: () => _deleteBook(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      );
    } else {
      return PrimaryButton(
        text: 'Contacter le publicateur',
        onPressed: () => _startChatWithPublisher(context, bookTitle),
        icon: Icons.chat,
      );
    }
  }

  Widget _buildSectionTitle(String title, ThemeData theme) {
    return Text(
      title,
      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
    );
  }

  Widget _buildDetailItem(String label, String value, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.6)),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = _getString('title', 'Titre inconnu');
    final description = _getString('description', 'Aucune description disponible');
    final category = _getString('category');
    final imageUrl = _getString('imageUrl', '');
    final rating = _getDouble('rating');
    final publisherEmail = _getString('publisherEmail', '');
    final currentUser = FirebaseAuth.instance.currentUser;
    final isOwner = currentUser != null && currentUser.email == publisherEmail;

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          if (!isOwner) // Afficher le bouton partager seulement si l'utilisateur n'est pas le propriétaire
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Fonctionnalité de partage à implémenter')),
              ),
            ),
          if (isOwner) // Afficher le menu de modification/suppression seulement si l'utilisateur est le propriétaire
            PopupMenuButton(
              onSelected: (value) {
                if (value == 'edit') {
                  _editBook(context);
                } else if (value == 'delete') {
                  _deleteBook(context);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, color: Colors.blue),
                      SizedBox(width: 8),
                      Text('Modifier'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Supprimer'),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBookHeader(theme, imageUrl, title, rating, heroTag: 'book-$bookId'),
            const SizedBox(height: 24),
            _buildActionButtons(context, title),
            const SizedBox(height: 24),
            _buildSectionTitle('Description', theme),
            const SizedBox(height: 8),
            Text(description, style: theme.textTheme.bodyLarge),
            const SizedBox(height: 24),
            _buildSectionTitle('Détails', theme),
            const SizedBox(height: 12),
            _buildDetailItem('Catégorie', category, theme),
            _buildDetailItem('État', _getString('condition', 'Bon état'), theme),
            _buildDetailItem('Type', _getString('type', 'Échange'), theme),
            _buildDetailItem('Localisation', _getString('location', 'Non spécifié'), theme),
          ],
        ),
      ),
    );
  }
}
import 'package:bookcycle/pages/chats/chatpage.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../composants/common_components.dart';
import '../../composants/common_utils.dart';

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
    required this.bookId,
  });

  String _getString(String key, [String defaultValue = 'Non spécifié']) {
    return book[key]?.toString() ?? defaultValue;
  }

  double _getDouble(String key, [double defaultValue = 0.0]) {
    return (book[key] as num?)?.toDouble() ?? defaultValue;
  }

  void _startChatWithPublisher(BuildContext context, String bookTitle) {
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

    final chatId = _generateChatId(currentUser.uid, publisherId);

    // Créer la conversation dans Firestore
    _createChatRoom(chatId, currentUser.uid, publisherId, bookTitle);

    final initialMessage = 'Bonjour, je suis intéressé par votre livre "$bookTitle"';

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ChatPage(
          chatId: chatId,
          otherUserId: publisherId,
          otherUserName: publisherName,
          initialMessage: initialMessage,
        ),
      ),
    );
  }

  Future<void> _createChatRoom(String chatId, String userId1, String userId2, String bookTitle) async {
    final firestore = FirebaseFirestore.instance;

    // Vérifier si le chat existe déjà
    final chatDoc = await firestore.collection('chats').doc(chatId).get();

    if (!chatDoc.exists) {
      // Créer le chat principal
      await firestore.collection('chats').doc(chatId).set({
        'participants': [userId1, userId2],
        'createdAt': FieldValue.serverTimestamp(),
        'lastMessage': 'Début de la conversation',
        'lastMessageTime': FieldValue.serverTimestamp(),
        'aboutBook': bookTitle
      });

      // Créer les références dans les sous-collections des utilisateurs
      await firestore.collection('users').doc(userId1)
          .collection('chats').doc(chatId).set({
        'otherUserId': userId2,
        'otherUserName': publisherName,
        'createdAt': FieldValue.serverTimestamp()
      });

      await firestore.collection('users').doc(userId2)
          .collection('chats').doc(chatId).set({
        'otherUserId': userId1,
        'otherUserName': FirebaseAuth.instance.currentUser?.displayName ?? 'Utilisateur',
        'createdAt': FieldValue.serverTimestamp()
      });
    }
  }

  String _generateChatId(String userId1, String userId2) {
    final ids = [userId1, userId2]..sort();
    return 'chat_${ids[0]}_${ids[1]}';
  }

  Widget _buildBookHeader(ThemeData theme, String imageUrl, String title, double rating) {
    final author = _getString('author', 'Auteur inconnu');

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: imageUrl.isNotEmpty
              ? CachedNetworkImage(
            imageUrl: imageUrl,
            width: 120,
            height: 180,
            fit: BoxFit.cover,
            errorWidget: (context, error, stackTrace) => _buildPlaceholderImage(),
          )
              : _buildPlaceholderImage(),
        ),
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
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      width: 120,
      height: 180,
      color: Colors.grey[200],
      child: const Icon(Icons.book, size: 50),
    );
  }

  Widget _buildContactButton(BuildContext context, String bookTitle) {
    return PrimaryButton(
      text: 'Contacter le publicateur',
      onPressed: () => _startChatWithPublisher(context, bookTitle),
      icon: Icons.chat,
    );
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
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
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

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Fonctionnalité de partage à implémenter')),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBookHeader(theme, imageUrl, title, rating),
            const SizedBox(height: 24),
            _buildContactButton(context, title),
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
import 'package:bookcycle/pages/pages%20rincipales/chatpage.dart';
import 'package:flutter/material.dart';

class BookDetailPage extends StatelessWidget {
  final Map<String, dynamic> book;
  final String publisherId;
  final String publisherName; // Nouveau paramètre pour le nom du publicateur

  const BookDetailPage({
    super.key,
    required this.book,
    required this.publisherId,
    required this.publisherName,
  });

  // Méthode pour extraire les valeurs avec des valeurs par défaut
  String _getString(String key, [String defaultValue = 'Non spécifié']) {
    return book[key]?.toString() ?? defaultValue;
  }

  double _getDouble(String key, [double defaultValue = 0.0]) {
    return (book[key] as num?)?.toDouble() ?? defaultValue;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = _getString('title', 'Titre inconnu');
    final description = _getString('description', 'Aucune description disponible');
    final category = _getString('category');
    final image = _getString('image', 'assets/placeholder_book.png');
    final rating = _getDouble('rating');

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => _shareBook(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBookHeader(theme, image, title, rating),
            const SizedBox(height: 24),
            _buildContactButton(context, title),
            const SizedBox(height: 24),
            _buildSectionTitle('Description', theme),
            const SizedBox(height: 8),
            Text(
              description,
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),
            _buildDetailsSection(theme, category),
          ],
        ),
      ),
    );
  }

  Widget _buildBookHeader(ThemeData theme, String image, String title, double rating) {
    final author = _getString('author', 'Auteur inconnu');

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.asset(
            image,
            width: 120,
            height: 180,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(
              width: 120,
              height: 180,
              color: Colors.grey[200],
              child: const Icon(Icons.book, size: 50),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Par $author',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(
                    Icons.star,
                    color: Colors.amber,
                    size: 20,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    rating.toStringAsFixed(1),
                    style: theme.textTheme.bodyLarge,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Publié par $publisherName',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildContactButton(BuildContext context, String bookTitle) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: const Icon(Icons.chat, size: 24),
        label: const Text(
          'Contacter le publicateur',
          style: TextStyle(fontSize: 16),
        ),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.white,
        ),
        onPressed: () => _startChatWithPublisher(context, bookTitle),
      ),
    );
  }

  void _startChatWithPublisher(BuildContext context, String bookTitle) {
    // Génération d'un chatId unique basé sur les IDs des utilisateurs
    final currentUserId = 'current_user_id'; // À remplacer par votre système d'authentification
    final chatId = _generateChatId(currentUserId, publisherId);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatPage(
          chatId: chatId,
          otherUserName: publisherName,
          initialMessage: "Bonjour, je suis intéressé par votre livre \"$bookTitle\"",
        ),
      ),
    );
  }

  String _generateChatId(String userId1, String userId2) {
    // Crée un ID de chat unique et cohérent peu importe l'ordre des IDs
    final ids = [userId1, userId2]..sort();
    return 'chat_${ids[0]}_${ids[1]}';
  }

  Widget _buildSectionTitle(String title, ThemeData theme) {
    return Text(
      title,
      style: theme.textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildDetailsSection(ThemeData theme, String category) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Détails', theme),
        const SizedBox(height: 12),
        _buildDetailItem('Catégorie', category, theme),
        _buildDetailItem('État', _getString('condition', 'Bon état'), theme),
        _buildDetailItem('Type', _getString('type', 'Échange'), theme),
        _buildDetailItem('Localisation', _getString('location', 'Non spécifié'), theme),
      ],
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
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _shareBook(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Fonctionnalité de partage à implémenter')),
    );
  }
}
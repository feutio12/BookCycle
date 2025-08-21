import 'package:flutter/material.dart';
import 'package:bookcycle/models/auction.dart';

class CarteEnchere extends StatelessWidget {
  final Enchere enchere;
  final VoidCallback? onTap;
  final List<Widget>? actions;

  const CarteEnchere({
    super.key,
    required this.enchere,
    this.onTap,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final couleurPrincipale = theme.colorScheme.primary;

    return Card(
      elevation: 2,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildImage(theme),
                  const SizedBox(width: 12),
                  Expanded(child: _buildEnchereInfo(theme, couleurPrincipale)),
                ],
              ),
              if (actions != null && actions!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: actions!,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImage(ThemeData theme) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 80,
        height: 100,
        color: theme.colorScheme.surfaceVariant,
        child: enchere.imageUrl.isNotEmpty
            ? Image.network(
          enchere.imageUrl,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                    loadingProgress.expectedTotalBytes!
                    : null,
              ),
            );
          },
          errorBuilder: (_, __, ___) => _buildPlaceholderIcon(),
        )
            : _buildPlaceholderIcon(),
      ),
    );
  }

  Widget _buildPlaceholderIcon() {
    return const Center(
      child: Icon(Icons.menu_book_rounded, size: 40, color: Colors.grey),
    );
  }

  Widget _buildEnchereInfo(ThemeData theme, Color couleurPrincipale) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Titre
        Text(
          enchere.titre,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),

        // Description
        if (enchere.description.isNotEmpty)
          Text(
            enchere.description,
            style: theme.textTheme.bodySmall,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        const SizedBox(height: 8),

        // Prix actuel
        Row(
          children: [
            Icon(
              Icons.euro_rounded,
              size: 16,
              color: couleurPrincipale,
            ),
            const SizedBox(width: 4),
            Text(
              '${enchere.prixActuel.toStringAsFixed(2)} €',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: couleurPrincipale,
              ),
            ),
            if (enchere.prixDepart != null) ...[
              const SizedBox(width: 8),
              Text(
                '(${enchere.prixDepart!.toStringAsFixed(2)} € départ)',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ],
        ),
        const SizedBox(height: 6),

        // Temps restant/Statut
        Row(
          children: [
            Icon(
              enchere.estActive ? Icons.timer_outlined : Icons.history,
              size: 16,
              color: enchere.estActive ? Colors.orange : Colors.grey,
            ),
            const SizedBox(width: 4),
            Text(
              enchere.estActive ? enchere.tempsRestant : 'Terminée',
              style: TextStyle(
                color: enchere.estActive ? Colors.orange : Colors.grey,
              ),
            ),
          ],
        ),

        // Nombre d'enchérisseurs
        const SizedBox(height: 6),
        Row(
          children: [
            Icon(
              Icons.people_outline,
              size: 16,
              color: Colors.grey[600],
            ),
            const SizedBox(width: 4),
            Text(
              '${enchere.nombreEncherisseurs} participant${enchere.nombreEncherisseurs > 1 ? 's' : ''}',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ],
        ),

        // État du livre
        if (enchere.etatLivre.isNotEmpty) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(
                Icons.star_outline,
                size: 16,
                color: Colors.grey[600],
              ),
              const SizedBox(width: 4),
              Text(
                enchere.etatLivre,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
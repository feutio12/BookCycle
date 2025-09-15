import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:bookcycle/models/auction.dart';

class AuctionCard extends StatelessWidget {
  final Enchere enchere;
  final VoidCallback onTap;
  final List<Widget> actions;

  const AuctionCard({
    super.key,
    required this.enchere,
    required this.onTap,
    this.actions = const [], required String imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image de l'enchère
              Hero(
                tag: 'enchere-${enchere.id}',
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.memory(
                    base64Decode(enchere.imageUrl),
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 180,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceVariant,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.image_not_supported, size: 40),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Titre de l'enchère
              Text(
                enchere.titre,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),

              // Informations sur l'enchère
              Row(
                children: [
                  // Prix actuel
                  Expanded(
                    child: Text(
                      '${enchere.prixActuel.toStringAsFixed(2)} fcfa',
                      style: TextStyle(
                        color: Colors.green[700],
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ),

                  // Date de fin
                  Expanded(
                    child: Text(
                      'Fin: ${DateFormat('dd/MM/yyyy').format(enchere.dateFin)}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                      ),
                      textAlign: TextAlign.end,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Statut de l'enchère
              Row(
                children: [
                  Icon(
                    enchere.estActive ? Icons.timer : Icons.history,
                    size: 16,
                    color: enchere.estActive
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    enchere.estActive
                        ? _formaterTempsRestant(enchere.dateFin)
                        : 'Terminée',
                    style: TextStyle(
                      fontSize: 14,
                      color: enchere.estActive
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                    ),
                  ),
                ],
              ),

              // Actions
              if (actions.isNotEmpty) ...[
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: actions,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  static String _formaterTempsRestant(DateTime dateFin) {
    final difference = dateFin.difference(DateTime.now());
    if (difference.inDays > 0) return '${difference.inDays} jour${difference.inDays > 1 ? 's' : ''}';
    if (difference.inHours > 0) return '${difference.inHours} heure${difference.inHours > 1 ? 's' : ''}';
    if (difference.inMinutes > 0) return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''}';
    return 'Moins d\'une minute';
  }
}

class AuctionDetailItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const AuctionDetailItem({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary, size: 20),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 15,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}
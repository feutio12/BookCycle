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
    this.actions = const [],
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image de l'enchère
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      enchere.imageUrl ?? 'https://picsum.photos/100/150?book',
                      width: 60,
                      height: 90,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 60,
                        height: 90,
                        color: Colors.grey[200],
                        child: const Icon(Icons.broken_image, size: 24),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          enchere.titre,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Prix actuel: ${enchere.prixActuel.toStringAsFixed(2)} €',
                          style: TextStyle(
                            color: Colors.green[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Fin: ${DateFormat('dd/MM/yyyy').format(enchere.dateFin)}',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Actions
              if (actions.isNotEmpty)
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: actions,
                ),
            ],
          ),
        ),
      ),
    );
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
    required this.value, required String valeur,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Theme.of(context).primaryColor),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          Text(value),
        ],
      ),
    );
  }
}
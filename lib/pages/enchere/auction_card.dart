import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:bookcycle/models/auction.dart';
import 'package:intl/intl.dart';

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
          errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
        ),
      );
    } catch (e) {
      return _buildPlaceholder();
    }
  }

  Widget _buildPlaceholder({double size = 90}) {
    return Container(
      width: 80,
      height: 110,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(Icons.book_rounded, size: 40, color: Colors.grey[400]),
    );
  }

  String _formaterTempsRestant(DateTime dateFin) {
    final difference = dateFin.difference(DateTime.now());
    if (difference.inDays > 0) return '${difference.inDays} jour${difference.inDays > 1 ? 's' : ''}';
    if (difference.inHours > 0) return '${difference.inHours} heure${difference.inHours > 1 ? 's' : ''}';
    if (difference.inMinutes > 0) return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''}';
    return 'Moins d\'une minute';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  Hero(
                    tag: 'enchere-${enchere.id}',
                    child: _buildBookImage(enchere.imageUrl),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          enchere.titre,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        if (enchere.description != null)
                          Text(
                            enchere.description!,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        const SizedBox(height: 8),
                        Text(
                          'Prix actuel: ${enchere.prixActuel.toStringAsFixed(2)} fcfa',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Colors.green,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.timer,
                              size: 16,
                              color: enchere.estActive ? Colors.orange : Colors.grey,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              enchere.estActive
                                  ? _formaterTempsRestant(enchere.dateFin)
                                  : 'Terminée le ${DateFormat('dd/MM/yyyy').format(enchere.dateFin)}',
                              style: TextStyle(
                                fontSize: 14,
                                color: enchere.estActive ? Colors.orange : Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (actions.isNotEmpty) ...[
                const SizedBox(height: 16),
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
}
import 'package:flutter/material.dart';

class ProfileStats extends StatelessWidget {
  final Map<String, dynamic> userData;
  final int booksPublishedCount;
  final int auctionsCount;

  const ProfileStats({
    Key? key,
    required this.userData,
    required this.booksPublishedCount,
    required this.auctionsCount,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final stats = userData['stats'] ?? {};
    final auctionsWon = stats['auctionsWon'] ?? 0;
    final activeAuctions = stats['activeAuctions'] ?? 0;
    final rating = (stats['rating'] ?? 0.0).toDouble();

    return Column(
      children: [
        // Carte principale des statistiques
        Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                const Text(
                  'Statistiques',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem(
                      'Livres Publiés',
                      booksPublishedCount.toString(),
                      Icons.library_books,
                      Colors.blue,
                    ),
                    _buildStatItem(
                      'Enchères Créées',
                      auctionsCount.toString(),
                      Icons.gavel,
                      Colors.orange,
                    ),
                    _buildStatItem(
                      'Enchères Gagnées',
                      auctionsWon.toString(),
                      Icons.emoji_events,
                      Colors.amber,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildStatItem(
                      'Enchères Actives',
                      activeAuctions.toString(),
                      Icons.timer,
                      Colors.purple,
                    ),
                    _buildStatItem(
                      'Note',
                      rating.toStringAsFixed(1),
                      Icons.star,
                      Colors.amber,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

      ]
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 24, color: color),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildMiniStatCard(String label, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

}
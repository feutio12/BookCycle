import 'package:flutter/material.dart';
import 'package:bookcycle/models/auction.dart';
import 'package:bookcycle/widgets/auction_card.dart';

class AuctionPage extends StatefulWidget {
  const AuctionPage({super.key});

  @override
  State<AuctionPage> createState() => _AuctionPageState();
}

class _AuctionPageState extends State<AuctionPage> {
  late Future<List<Auction>> _activeAuctions;
  late Future<List<Auction>> _closedAuctions;

  @override
  void initState() {
    super.initState();
    _loadAuctions();
  }

  void _loadAuctions() {
    // Remplacez par votre appel API réel
    _activeAuctions = Future.delayed(const Duration(seconds: 1), () {
      return List.generate(5, (index) => Auction(
        id: 'active-$index',
        title: 'Livre rare ${index + 1}',
        description: 'Édition limitée ${1920 + index}',
        currentBid: 50.0 + (index * 10),
        startingPrice: 30.0,
        endTime: DateTime.now().add(Duration(days: index + 1)),
        imageUrl: 'https://picsum.photos/200/300?random=$index',
        bidderCount: 3 + index,
        isActive: true,
        bookCondition: ['Neuf', 'Bon état', 'Usagé'][index % 3],
      ));
    });

    _closedAuctions = Future.delayed(const Duration(seconds: 1), () {
      return List.generate(3, (index) => Auction(
        id: 'closed-$index',
        title: 'Collection ancienne ${index + 1}',
        description: 'Édition originale ${1900 + index}',
        currentBid: 120.0 + (index * 30),
        endTime: DateTime.now().subtract(Duration(days: index + 1)),
        imageUrl: 'https://picsum.photos/200/300?old=$index',
        winner: 'lecteur${123 + index}@bookcycle.com',
        isActive: false,
        bookCondition: 'Usagé',
      ));
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Enchères BookCycle'),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.timer), text: 'En cours'),
              Tab(icon: Icon(Icons.history), text: 'Terminées'),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadAuctions,
            ),
          ],
        ),
        body: TabBarView(
          children: [
            _buildAuctionsTab(_activeAuctions, true),
            _buildAuctionsTab(_closedAuctions, false),
          ],
        ),
      ),
    );
  }

  Widget _buildAuctionsTab(Future<List<Auction>> auctions, bool isActive) {
    return FutureBuilder<List<Auction>>(
      future: auctions,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Erreur: ${snapshot.error}'));
        }

        final auctions = snapshot.data ?? [];

        if (auctions.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isActive ? Icons.hourglass_empty : Icons.history_toggle_off,
                  size: 60,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  isActive
                      ? 'Aucune enchère en cours'
                      : 'Aucune enchère terminée',
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async => _loadAuctions(),
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: auctions.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final auction = auctions[index];
              return AuctionCard(
                auction: auction,
                onTap: () => _showAuctionDetails(context, auction),
                actions: [
                  if (isActive)
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                      ),
                      onPressed: () => _placeBid(auction),
                      child: const Text('Enchérir'),
                    ),
                  TextButton(
                    onPressed: () => _showAuctionDetails(context, auction),
                    child: const Text('Détails'),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  void _showAuctionDetails(BuildContext context, Auction auction) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _buildAuctionDetails(ctx, auction),
    );
  }

  Widget _buildAuctionDetails(BuildContext context, Auction auction) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                auction.imageUrl ?? 'https://picsum.photos/400/300?book',
                height: 200,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 200,
                  color: Colors.grey[200],
                  child: const Icon(Icons.broken_image, size: 50),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            auction.title,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          if (auction.description != null)
            Text(
              auction.description!,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          const Divider(height: 32),
          _buildDetailRow(
            context,
            icon: Icons.attach_money,
            label: 'Prix ${auction.isActive ? 'actuel' : 'final'}',
            value: '${auction.currentBid.toStringAsFixed(2)} €',
          ),
          if (auction.startingPrice != null)
            _buildDetailRow(
              context,
              icon: Icons.price_change,
              label: 'Prix de départ',
              value: '${auction.startingPrice!.toStringAsFixed(2)} €',
            ),
          _buildDetailRow(
            context,
            icon: auction.isActive ? Icons.timer : Icons.history,
            label: auction.isActive ? 'Temps restant' : 'Statut',
            value: auction.isActive ? auction.timeLeft : 'Terminée',
          ),
          if (auction.bookCondition != null)
            _buildDetailRow(
              context,
              icon: Icons.star,
              label: 'État du livre',
              value: auction.bookCondition!,
            ),
          if (!auction.isActive && auction.winner != null)
            _buildDetailRow(
              context,
              icon: Icons.emoji_events,
              label: 'Gagnant',
              value: auction.winner!,
            ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Fermer'),
              ),
              if (auction.isActive) ...[
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    _placeBid(auction);
                    Navigator.pop(context);
                  },
                  child: const Text('Faire une offre'),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
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

  void _placeBid(Auction auction) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nouvelle offre'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Livre: ${auction.title}'),
            const SizedBox(height: 16),
            Text(
              'Offre actuelle: ${auction.currentBid.toStringAsFixed(2)} €',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Votre offre (€)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: Implémenter la logique d'enchère
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Offre soumise avec succès!')),
              );
            },
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AdminAuctionsManagement extends StatefulWidget {
  const AdminAuctionsManagement({super.key});

  @override
  State<AdminAuctionsManagement> createState() => _AdminAuctionsManagementState();
}

class _AdminAuctionsManagementState extends State<AdminAuctionsManagement> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ScrollController _scrollController = ScrollController();
  String _filterStatus = 'Tous';
  String _searchQuery = '';

  final List<String> _statusOptions = ['Tous', 'Active', 'Terminée', 'Annulée'];

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // Méthode utilitaire pour formater les dates
  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return DateFormat('dd/MM/yyyy HH:mm').format(date);
  }

  // Méthode utilitaire pour calculer le temps restant
  String _formatTimeRemaining(DateTime endDate) {
    final now = DateTime.now();
    final difference = endDate.difference(now);

    if (difference.isNegative) return 'Terminé';

    final days = difference.inDays;
    final hours = difference.inHours.remainder(24);
    final minutes = difference.inMinutes.remainder(60);

    if (days > 0) {
      return '$days j ${hours}h';
    } else if (hours > 0) {
      return '${hours}h ${minutes}min';
    } else {
      return '${minutes}min';
    }
  }

  // Méthode utilitaire pour afficher des messages de succès
  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  // Méthode utilitaire pour afficher des messages d'erreur
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  Future<void> _cancelAuction(String auctionId) async {
    try {
      await _firestore.collection('encheres').doc(auctionId).update({
        'status': 'Annulée',
        'cancelledAt': FieldValue.serverTimestamp(),
      });
      _showSuccessSnackBar('Enchère annulée avec succès');
    } catch (e) {
      _showErrorSnackBar('Erreur lors de l\'annulation: $e');
    }
  }

  Future<void> _extendAuction(String auctionId, DateTime currentEndDate) async {
    final newEndDate = currentEndDate.add(const Duration(days: 1));

    try {
      await _firestore.collection('encheres').doc(auctionId).update({
        'dateFin': newEndDate,
      });
      _showSuccessSnackBar('Enchère prolongée d\'un jour');
    } catch (e) {
      _showErrorSnackBar('Erreur lors de la prolongation: $e');
    }
  }

  Widget _buildAuctionCard(DocumentSnapshot auction) {
    final data = auction.data() as Map<String, dynamic>;
    final bookTitle = data['titre'] ?? 'Sans titre';
    final currentBid = data['prixActuel'] ?? 0.0;
    final endDate = (data['dateFin'] as Timestamp?)?.toDate() ?? DateTime.now();
    final status = data['status'] ?? 'Active';
    final bidsCount = data['nombreOffres'] ?? 0;
    final isActive = status == 'Active' && endDate.isAfter(DateTime.now());

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue,
          child: Text(
            '${currentBid.toStringAsFixed(0)}\€',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(
          bookTitle,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Fin: ${_formatDate(endDate)}'),
            Text('Offres: $bidsCount • Statut: $status'),
            if (isActive)
              Text(
                'Temps restant: ${_formatTimeRemaining(endDate)}',
                style: TextStyle(color: Colors.green[700]),
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isActive) ...[
              IconButton(
                icon: const Icon(Icons.timer, size: 20),
                onPressed: () => _extendAuction(auction.id, endDate),
                tooltip: 'Prolonger d\'un jour',
              ),
              IconButton(
                icon: const Icon(Icons.cancel, size: 20, color: Colors.red),
                onPressed: () => _showCancelConfirmation(auction.id),
                tooltip: 'Annuler l\'enchère',
              ),
            ],
            IconButton(
              icon: const Icon(Icons.visibility, size: 20),
              onPressed: () => _showAuctionDetails(auction),
              tooltip: 'Voir les détails',
            ),
          ],
        ),
      ),
    );
  }

  void _showCancelConfirmation(String auctionId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer l\'annulation'),
        content: const Text('Êtes-vous sûr de vouloir annuler cette enchère ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _cancelAuction(auctionId);
            },
            child: const Text('Confirmer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showAuctionDetails(DocumentSnapshot auction) {
    final data = auction.data() as Map<String, dynamic>;
    final startDate = (data['dateDebut'] as Timestamp?)?.toDate();
    final endDate = (data['dateFin'] as Timestamp?)?.toDate();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Détails de l\'enchère'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Livre: ${data['titre'] ?? 'N/A'}'),
              Text('Prix actuel: ${data['prixActuel']?.toStringAsFixed(2) ?? '0.00'} €'),
              Text('Prix de départ: ${data['prixDepart']?.toStringAsFixed(2) ?? '0.00'} €'),
              Text('Offres: ${data['nombreOffres'] ?? 0}'),
              Text('Début: ${_formatDate(startDate)}'),
              Text('Fin: ${_formatDate(endDate)}'),
              Text('Statut: ${data['status'] ?? 'N/A'}'),
              Text('Vendeur: ${data['vendeurId'] ?? 'N/A'}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Gestion des Enchères',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Filtres et recherche
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: 'Rechercher par titre...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) => setState(() => _searchQuery = value),
                  ),
                ),
                const SizedBox(width: 16),
                DropdownButton<String>(
                  value: _filterStatus,
                  items: _statusOptions.map((status) {
                    return DropdownMenuItem(
                      value: status,
                      child: Text(status),
                    );
                  }).toList(),
                  onChanged: (value) => setState(() => _filterStatus = value!),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Liste des enchères
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore.collection('encheres').snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text('Erreur: ${snapshot.error}'));
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  var auctions = snapshot.data!.docs;

                  // Appliquer les filtres
                  if (_filterStatus != 'Tous') {
                    auctions = auctions.where((auction) {
                      final data = auction.data() as Map<String, dynamic>;
                      return data['status'] == _filterStatus;
                    }).toList();
                  }

                  if (_searchQuery.isNotEmpty) {
                    auctions = auctions.where((auction) {
                      final data = auction.data() as Map<String, dynamic>;
                      final title = data['titre']?.toString().toLowerCase() ?? '';
                      return title.contains(_searchQuery.toLowerCase());
                    }).toList();
                  }

                  // Trier par date de fin
                  auctions.sort((a, b) {
                    final aData = a.data() as Map<String, dynamic>;
                    final bData = b.data() as Map<String, dynamic>;
                    final aDate = (aData['dateFin'] as Timestamp?)?.toDate() ?? DateTime(0);
                    final bDate = (bData['dateFin'] as Timestamp?)?.toDate() ?? DateTime(0);
                    return aDate.compareTo(bDate);
                  });

                  if (auctions.isEmpty) {
                    return const Center(child: Text('Aucune enchère trouvée'));
                  }

                  return ListView.builder(
                    controller: _scrollController,
                    itemCount: auctions.length,
                    itemBuilder: (context, index) {
                      return _buildAuctionCard(auctions[index]);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
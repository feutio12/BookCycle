import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bookcycle/admin/widgets/admin_drawer.dart';
import 'package:bookcycle/admin/widgets/data_table.dart';
import 'package:bookcycle/admin/services/admin_service.dart';

class AdminAuctionsPage extends StatefulWidget {
  @override
  _AdminAuctionsPageState createState() => _AdminAuctionsPageState();
}

class _AdminAuctionsPageState extends State<AdminAuctionsPage> {
  final AdminService _adminService = AdminService();
  String _filterStatus = 'all';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Gestion des enchères'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() {
                _filterStatus = value;
              });
            },
            itemBuilder: (BuildContext context) => [
              PopupMenuItem(value: 'all', child: Text('Toutes les enchères')),
              PopupMenuItem(value: 'active', child: Text('Actives')),
              PopupMenuItem(value: 'completed', child: Text('Terminées')),
              PopupMenuItem(value: 'cancelled', child: Text('Annulées')),
            ],
            icon: Icon(Icons.filter_list),
          ),
        ],
      ),
      drawer: AdminDrawer(),
      body: StreamBuilder<QuerySnapshot>(
        stream: _adminService.getAuctions(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Erreur: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          final auctions = snapshot.data!.docs;
          final filteredAuctions = _filterStatus == 'all'
              ? auctions
              : auctions.where((auction) {
            final data = auction.data() as Map<String, dynamic>;
            return data['status'] == _filterStatus;
          }).toList();

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Liste des enchères (${filteredAuctions.length})',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 16),
                Expanded(
                  child: AdminDataTable(
                    columns: [
                      DataColumn(label: Text('Livre')),
                      DataColumn(label: Text('Vendeur')),
                      DataColumn(label: Text('Prix actuel')),
                      DataColumn(label: Text('Enchérisseurs')),
                      DataColumn(label: Text('Statut')),
                      DataColumn(label: Text('Fin')),
                      DataColumn(label: Text('Actions')),
                    ],
                    rows: filteredAuctions.map((auction) {
                      final data = auction.data() as Map<String, dynamic>;
                      return DataRow(cells: [
                        DataCell(
                          ConstrainedBox(
                            constraints: BoxConstraints(maxWidth: 120),
                            child: Text(
                              data['bookTitle'] ?? 'Sans titre',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        DataCell(Text(data['sellerName'] ?? 'N/A')),
                        DataCell(Text(data['currentBid'] != null
                            ? '${data['currentBid']} €'
                            : 'N/A')),
                        DataCell(Text('${data['biddersCount'] ?? 0}')),
                        DataCell(
                          Chip(
                            label: Text(
                              _getStatusText(data['status']),
                              style: TextStyle(color: Colors.white),
                            ),
                            backgroundColor: _getStatusColor(data['status']),
                          ),
                        ),
                        DataCell(Text(data['endDate'] != null
                            ? _formatDate(data['endDate'].toDate())
                            : 'N/A')),
                        DataCell(Row(
                          children: [
                            IconButton(
                              icon: Icon(Icons.visibility, color: Colors.blue),
                              onPressed: () {
                                // Voir les détails de l'enchère
                              },
                            ),
                            if (data['status'] == 'active')
                              IconButton(
                                icon: Icon(Icons.cancel, color: Colors.red),
                                onPressed: () {
                                  _showCancelDialog(context, auction.id, data['bookTitle']);
                                },
                              ),
                          ],
                        )),
                      ]);
                    }).toList(),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'active': return 'Active';
      case 'completed': return 'Terminée';
      case 'cancelled': return 'Annulée';
      default: return 'Inconnu';
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'active': return Colors.green;
      case 'completed': return Colors.blue;
      case 'cancelled': return Colors.red;
      default: return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showCancelDialog(BuildContext context, String auctionId, String title) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirmer l\'annulation'),
          content: Text('Êtes-vous sûr de vouloir annuler l\'enchère "$title"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Annuler'),
            ),
            TextButton(
              onPressed: () {
                _adminService.cancelAuction(auctionId);
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Enchère annulée avec succès')),
                );
              },
              child: Text('Confirmer', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }
}
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bookcycle/admin/widgets/admin_drawer.dart';
import 'package:bookcycle/admin/widgets/data_table.dart';
import 'package:bookcycle/admin/services/admin_service.dart';

class AdminBooksPage extends StatefulWidget {
  @override
  _AdminBooksPageState createState() => _AdminBooksPageState();
}

class _AdminBooksPageState extends State<AdminBooksPage> {
  final AdminService _adminService = AdminService();
  String _filterStatus = 'all';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Gestion des livres'),
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
              PopupMenuItem(value: 'all', child: Text('Tous les livres')),
              PopupMenuItem(value: 'available', child: Text('Disponibles')),
              PopupMenuItem(value: 'sold', child: Text('Vendus')),
              PopupMenuItem(value: 'reserved', child: Text('Réservés')),
            ],
            icon: Icon(Icons.filter_list),
          ),
        ],
      ),
      drawer: AdminDrawer(),
      body: StreamBuilder<QuerySnapshot>(
        stream: _adminService.getBooks(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Erreur: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          final books = snapshot.data!.docs;
          final filteredBooks = _filterStatus == 'all'
              ? books
              : books.where((book) {
            final data = book.data() as Map<String, dynamic>;
            return data['status'] == _filterStatus;
          }).toList();

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Liste des livres (${filteredBooks.length})',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 16),
                Expanded(
                  child: AdminDataTable(
                    columns: [
                      DataColumn(label: Text('Titre')),
                      DataColumn(label: Text('Auteur')),
                      DataColumn(label: Text('Propriétaire')),
                      DataColumn(label: Text('Statut')),
                      DataColumn(label: Text('Prix')),
                      DataColumn(label: Text('Actions')),
                    ],
                    rows: filteredBooks.map((book) {
                      final data = book.data() as Map<String, dynamic>;
                      return DataRow(cells: [
                        DataCell(
                          ConstrainedBox(
                            constraints: BoxConstraints(maxWidth: 150),
                            child: Text(
                              data['title'] ?? 'Sans titre',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        DataCell(Text(data['author'] ?? 'N/A')),
                        DataCell(Text(data['ownerName'] ?? 'N/A')),
                        DataCell(
                          Chip(
                            label: Text(
                              _getStatusText(data['status']),
                              style: TextStyle(color: Colors.white),
                            ),
                            backgroundColor: _getStatusColor(data['status']),
                          ),
                        ),
                        DataCell(Text(data['price'] != null
                            ? '${data['price']} €'
                            : 'N/A')),
                        DataCell(Row(
                          children: [
                            IconButton(
                              icon: Icon(Icons.visibility, color: Colors.blue),
                              onPressed: () {
                                // Voir les détails du livre
                              },
                            ),
                            IconButton(
                              icon: Icon(Icons.edit, color: Colors.orange),
                              onPressed: () {
                                // Modifier le livre
                              },
                            ),
                            IconButton(
                              icon: Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                _showDeleteDialog(context, book.id, data['title']);
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
      case 'available': return 'Disponible';
      case 'sold': return 'Vendu';
      case 'reserved': return 'Réservé';
      default: return 'Inconnu';
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'available': return Colors.green;
      case 'sold': return Colors.red;
      case 'reserved': return Colors.orange;
      default: return Colors.grey;
    }
  }

  void _showDeleteDialog(BuildContext context, String bookId, String title) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirmer la suppression'),
          content: Text('Êtes-vous sûr de vouloir supprimer le livre "$title"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Annuler'),
            ),
            TextButton(
              onPressed: () {
                _adminService.updateBookStatus(bookId, 'deleted');
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Livre supprimé avec succès')),
                );
              },
              child: Text('Supprimer', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }
}
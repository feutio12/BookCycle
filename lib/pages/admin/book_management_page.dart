import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../composants/common_components.dart';

class BookManagementPage extends StatefulWidget {
  const BookManagementPage({super.key});

  @override
  State<BookManagementPage> createState() => _BookManagementPageState();
}

class _BookManagementPageState extends State<BookManagementPage> {
  String _filterStatus = 'all';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Gestion des livres', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          _buildStatusFilter(),
          const SizedBox(height: 24),
          Expanded(child: _buildBooksTable()),
        ],
      ),
    );
  }

  Widget _buildStatusFilter() {
    return Wrap(spacing: 8, children: [
      FilterChip(label: const Text('Tous'), selected: _filterStatus == 'all', onSelected: (_) => setState(() => _filterStatus = 'all')),
      FilterChip(label: const Text('Disponibles'), selected: _filterStatus == 'available', onSelected: (_) => setState(() => _filterStatus = 'available')),
      FilterChip(label: const Text('En attente'), selected: _filterStatus == 'pending', onSelected: (_) => setState(() => _filterStatus = 'pending')),
      FilterChip(label: const Text('Échangés'), selected: _filterStatus == 'exchanged', onSelected: (_) => setState(() => _filterStatus = 'exchanged')),
    ]);
  }

  Widget _buildBooksTable() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('books').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return ErrorMessage(message: 'Erreur: ${snapshot.error}');
        if (snapshot.connectionState == ConnectionState.waiting) return const LoadingIndicator();

        final books = snapshot.data!.docs.where(_filterBook).toList();

        return books.isEmpty
            ? const Center(child: Text('Aucun livre trouvé'))
            : SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: DataTable(
            columns: const [
              DataColumn(label: Text('Titre')),
              DataColumn(label: Text('Auteur')),
              DataColumn(label: Text('Propriétaire')),
              DataColumn(label: Text('Statut')),
              DataColumn(label: Text('Ajouté le')),
              DataColumn(label: Text('Actions')),
            ],
            rows: books.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return DataRow(cells: [
                DataCell(SizedBox(width: 200, child: Text(data['title'] ?? ''))),
                DataCell(Text(data['author'] ?? 'Inconnu')),
                DataCell(Text(data['ownerName'] ?? 'Inconnu')),
                DataCell(_buildStatusChip(data['status'])),
                DataCell(Text(DateFormat('dd/MM/yy').format((data['createdAt'] as Timestamp).toDate()))),
                DataCell(_buildBookActions(doc.id, data)),
              ]);
            }).toList(),
          ),
        );
      },
    );
  }

  bool _filterBook(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final status = data['status']?.toString() ?? '';

    if (_filterStatus == 'all') return true;
    if (_filterStatus == 'available') return status == 'available';
    if (_filterStatus == 'pending') return status == 'pending';
    if (_filterStatus == 'exchanged') return status == 'exchanged';
    return true;
  }

  Widget _buildStatusChip(String? status) {
    Color color;
    switch (status) {
      case 'available': color = Colors.green;
      case 'pending': color = Colors.orange;
      case 'exchanged': color = Colors.blue;
      case 'reported': color = Colors.red;
      default: color = Colors.grey;
    }
    return Chip(label: Text(status ?? 'inactive', style: const TextStyle(color: Colors.white)), backgroundColor: color);
  }

  Widget _buildBookActions(String bookId, Map<String, dynamic> data) {
    return Row(children: [
      IconButton(icon: const Icon(Icons.visibility, size: 20), onPressed: () => _viewBook(bookId)),
      IconButton(icon: const Icon(Icons.edit, size: 20), onPressed: () => _editBook(bookId, data)),
      IconButton(icon: const Icon(Icons.delete, size: 20, color: Colors.red), onPressed: () => _deleteBook(bookId)),
    ]);
  }

  void _viewBook(String bookId) {
    // Naviguer vers la page de détail du livre
  }

  void _editBook(String bookId, Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Modifier le livre'),
        content: SizedBox(width: 500, child: _buildBookEditForm(data)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          ElevatedButton(onPressed: () => _saveBookChanges(bookId), child: const Text('Sauvegarder')),
        ],
      ),
    );
  }

  Widget _buildBookEditForm(Map<String, dynamic> data) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      TextFormField(initialValue: data['title'], decoration: const InputDecoration(labelText: 'Titre')),
      TextFormField(initialValue: data['author'], decoration: const InputDecoration(labelText: 'Auteur')),
      // Ajouter plus de champs
    ]);
  }

  void _saveBookChanges(String bookId) {
    Navigator.pop(context);
  }

  void _deleteBook(String bookId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: const Text('Êtes-vous sûr de vouloir supprimer ce livre ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () {
              FirebaseFirestore.instance.collection('books').doc(bookId).delete();
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }
}
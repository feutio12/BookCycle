// auction_management_page.dart - Version améliorée
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../composants/common_components.dart';

class AuctionManagementPage extends StatefulWidget {
  const AuctionManagementPage({super.key});

  @override
  State<AuctionManagementPage> createState() => _AuctionManagementPageState();
}

class _AuctionManagementPageState extends State<AuctionManagementPage> {
  String _filterStatus = 'all';
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _bookTitleController = TextEditingController();
  final TextEditingController _currentBidController = TextEditingController();
  final TextEditingController _sellerNameController = TextEditingController();
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 7));

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Gestion des enchères', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              const Spacer(),
              ElevatedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Nouvelle enchère'),
                onPressed: _createNewAuction,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildStatusFilter(),
          const SizedBox(height: 24),
          Expanded(
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: _buildAuctionsTable(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusFilter() {
    return Wrap(
      spacing: 8,
      children: [
        FilterChip(
          label: const Text('Toutes'),
          selected: _filterStatus == 'all',
          onSelected: (_) => setState(() => _filterStatus = 'all'),
          selectedColor: AppColors.primaryBlue.withOpacity(0.2),
          checkmarkColor: AppColors.primaryBlue,
        ),
        FilterChip(
          label: const Text('Actives'),
          selected: _filterStatus == 'active',
          onSelected: (_) => setState(() => _filterStatus = 'active'),
          selectedColor: Colors.green.withOpacity(0.2),
          checkmarkColor: Colors.green,
        ),
        FilterChip(
          label: const Text('Terminées'),
          selected: _filterStatus == 'ended',
          onSelected: (_) => setState(() => _filterStatus = 'ended'),
          selectedColor: Colors.blue.withOpacity(0.2),
          checkmarkColor: Colors.blue,
        ),
        FilterChip(
          label: const Text('Annulées'),
          selected: _filterStatus == 'cancelled',
          onSelected: (_) => setState(() => _filterStatus = 'cancelled'),
          selectedColor: Colors.red.withOpacity(0.2),
          checkmarkColor: Colors.red,
        ),
      ],
    );
  }

  Widget _buildAuctionsTable() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('auctions').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return ErrorMessage(message: 'Erreur: ${snapshot.error}');
        if (snapshot.connectionState == ConnectionState.waiting) return const LoadingIndicator();

        final auctions = snapshot.data!.docs.where(_filterAuction).toList();

        return auctions.isEmpty
            ? const Center(child: Text('Aucune enchère trouvée', style: TextStyle(color: Colors.grey)))
            : SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: DataTable(
            columnSpacing: 16,
            columns: const [
              DataColumn(label: Text('Livre', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Vendeur', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Prix actuel', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Enchères', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Début', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Fin', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Statut', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
            ],
            rows: auctions.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return DataRow(
                cells: [
                  DataCell(SizedBox(width: 150, child: Text(data['bookTitle'] ?? '', overflow: TextOverflow.ellipsis))),
                  DataCell(Text(data['sellerName'] ?? 'Inconnu')),
                  DataCell(Text('${data['currentBid'] ?? 0} €', style: const TextStyle(fontWeight: FontWeight.w500))),
                  DataCell(Text('${data['bidCount'] ?? 0}')),
                  DataCell(Text(DateFormat('dd/MM/yy').format((data['startDate'] as Timestamp).toDate()))),
                  DataCell(Text(DateFormat('dd/MM/yy').format((data['endDate'] as Timestamp).toDate()))),
                  DataCell(_buildAuctionStatusChip(data['status'])),
                  DataCell(_buildAuctionActions(doc.id, data)),
                ],
              );
            }).toList(),
          ),
        );
      },
    );
  }

  bool _filterAuction(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final status = data['status']?.toString() ?? '';

    if (_filterStatus == 'all') return true;
    if (_filterStatus == 'active') return status == 'active';
    if (_filterStatus == 'ended') return status == 'ended';
    if (_filterStatus == 'cancelled') return status == 'cancelled';
    return true;
  }

  Widget _buildAuctionStatusChip(String? status) {
    Color color;
    switch (status) {
      case 'active': color = Colors.green;
      case 'ended': color = Colors.blue;
      case 'cancelled': color = Colors.red;
      default: color = Colors.grey;
    }
    return Chip(
      label: Text(status ?? 'inactive', style: const TextStyle(color: Colors.white, fontSize: 12)),
      backgroundColor: color,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    );
  }

  Widget _buildAuctionActions(String auctionId, Map<String, dynamic> data) {
    return Row(children: [
      IconButton(icon: const Icon(Icons.visibility, size: 20), onPressed: () => _viewAuction(auctionId)),
      IconButton(icon: const Icon(Icons.edit, size: 20), onPressed: () => _editAuction(auctionId, data)),
      IconButton(icon: const Icon(Icons.delete, size: 20, color: Colors.red), onPressed: () => _deleteAuction(auctionId)),
    ]);
  }

  void _createNewAuction() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nouvelle enchère'),
        content: SizedBox(width: 500, child: _buildAuctionForm()),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          ElevatedButton(onPressed: () => _saveNewAuction(), child: const Text('Créer')),
        ],
      ),
    );
  }

  Widget _buildAuctionForm() {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextFormField(
            controller: _bookTitleController,
            decoration: const InputDecoration(
              labelText: 'Titre du livre',
              border: OutlineInputBorder(),
            ),
            validator: (value) => value?.isEmpty == true ? 'Ce champ est requis' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _sellerNameController,
            decoration: const InputDecoration(
              labelText: 'Nom du vendeur',
              border: OutlineInputBorder(),
            ),
            validator: (value) => value?.isEmpty == true ? 'Ce champ est requis' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _currentBidController,
            decoration: const InputDecoration(
              labelText: 'Prix initial',
              border: OutlineInputBorder(),
              prefixText: '€ ',
            ),
            keyboardType: TextInputType.number,
            validator: (value) => value?.isEmpty == true ? 'Ce champ est requis' : null,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ListTile(
                  title: Text('Date de début: ${DateFormat('dd/MM/yyyy').format(_startDate)}'),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: _startDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null && picked != _startDate) {
                      setState(() => _startDate = picked);
                    }
                  },
                ),
              ),
              Expanded(
                child: ListTile(
                  title: Text('Date de fin: ${DateFormat('dd/MM/yyyy').format(_endDate)}'),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: _endDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null && picked != _endDate) {
                      setState(() => _endDate = picked);
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _saveNewAuction() {
    if (_formKey.currentState!.validate()) {
      // Enregistrer la nouvelle enchère dans Firestore
      FirebaseFirestore.instance.collection('enchere').add({
        'bookTitle': _bookTitleController.text,
        'sellerName': _sellerNameController.text,
        'currentBid': double.parse(_currentBidController.text),
        'startDate': _startDate,
        'endDate': _endDate,
        'status': 'active',
        'bidCount': 0,
        'createdAt': DateTime.now(),
      }).then((value) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Enchère créée avec succès')),
        );
      }).catchError((error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $error')),
        );
      });
    }
  }

  void _viewAuction(String auctionId) {
    // Naviguer vers la page de détail de l'enchère
  }

  void _editAuction(String auctionId, Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Modifier l\'enchère'),
        content: SizedBox(width: 500, child: _buildAuctionEditForm(data)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          ElevatedButton(onPressed: () => _saveAuctionChanges(auctionId), child: const Text('Sauvegarder')),
        ],
      ),
    );
  }

  Widget _buildAuctionEditForm(Map<String, dynamic> data) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      TextFormField(initialValue: data['bookTitle'], decoration: const InputDecoration(labelText: 'Titre du livre')),
      const SizedBox(height: 16),
      TextFormField(initialValue: data['currentBid']?.toString(), decoration: const InputDecoration(labelText: 'Prix actuel')),
    ]);
  }

  void _saveAuctionChanges(String auctionId) {
    Navigator.pop(context);
  }

  void _deleteAuction(String auctionId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: const Text('Êtes-vous sûr de vouloir supprimer cette enchère ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () {
              FirebaseFirestore.instance.collection('auctions').doc(auctionId).delete();
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
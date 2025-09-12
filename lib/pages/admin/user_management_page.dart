import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../composants/common_components.dart';

class UserManagementPage extends StatefulWidget {
  const UserManagementPage({super.key});

  @override
  State<UserManagementPage> createState() => _UserManagementPageState();
}

class _UserManagementPageState extends State<UserManagementPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _searchQuery = '';
  String _filterStatus = 'all';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Gestion des utilisateurs', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          _buildSearchAndFilters(),
          const SizedBox(height: 24),
          Expanded(child: _buildUsersTable()),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Rechercher un utilisateur...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
          ),
        ),
        const SizedBox(width: 16),
        DropdownButton<String>(
          value: _filterStatus,
          items: const [
            DropdownMenuItem(value: 'all', child: Text('Tous')),
            DropdownMenuItem(value: 'active', child: Text('Actifs')),
            DropdownMenuItem(value: 'inactive', child: Text('Inactifs')),
            DropdownMenuItem(value: 'banned', child: Text('Bannis')),
          ],
          onChanged: (value) => setState(() => _filterStatus = value!),
        ),
        const SizedBox(width: 16),
        ElevatedButton.icon(
          icon: const Icon(Icons.person_add),
          label: const Text('Nouvel utilisateur'),
          onPressed: _addNewUser,
        ),
      ],
    );
  }

  Widget _buildUsersTable() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return ErrorMessage(message: 'Erreur: ${snapshot.error}');
        if (snapshot.connectionState == ConnectionState.waiting) return const LoadingIndicator();

        final users = snapshot.data!.docs.where(_filterUser).toList();

        return users.isEmpty
            ? const Center(child: Text('Aucun utilisateur trouvé'))
            : SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: DataTable(
            columns: const [
              DataColumn(label: Text('Utilisateur')),
              DataColumn(label: Text('Email')),
              DataColumn(label: Text('Inscription')),
              DataColumn(label: Text('Statut')),
              DataColumn(label: Text('Actions')),
            ],
            rows: users.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return DataRow(cells: [
                DataCell(_buildUserInfo(data)),
                DataCell(Text(data['email'] ?? '')),
                DataCell(Text(DateFormat('dd/MM/yy').format((data['createdAt'] as Timestamp).toDate()))),
                DataCell(_buildStatusChip(data)),
                DataCell(_buildUserActions(doc.id, data)),
              ]);
            }).toList(),
          ),
        );
      },
    );
  }

  bool _filterUser(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final name = data['name']?.toString().toLowerCase() ?? '';
    final email = data['email']?.toString().toLowerCase() ?? '';
    final isActive = data['isActive'] ?? true;
    final isBanned = data['isBanned'] ?? false;

    // Filtre de recherche
    if (_searchQuery.isNotEmpty && !name.contains(_searchQuery) && !email.contains(_searchQuery)) {
      return false;
    }

    // Filtre de statut
    if (_filterStatus == 'active') return isActive && !isBanned;
    if (_filterStatus == 'inactive') return !isActive && !isBanned;
    if (_filterStatus == 'banned') return isBanned;

    return true;
  }

  Widget _buildUserInfo(Map<String, dynamic> data) {
    return Row(
      children: [
        CircleAvatar(
          backgroundColor: AppColors.primaryBlue,
          child: Text(data['name']?[0] ?? 'U', style: const TextStyle(color: Colors.white)),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(data['name'] ?? 'Utilisateur', style: const TextStyle(fontWeight: FontWeight.bold)),
            Text('${data['booksCount'] ?? 0} livres', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          ],
        ),
      ],
    );
  }

  Widget _buildStatusChip(Map<String, dynamic> data) {
    if (data['isBanned'] == true) {
      return const Chip(label: Text('Banni', style: TextStyle(color: Colors.white)), backgroundColor: Colors.red);
    } else if (data['isActive'] == true) {
      return const Chip(label: Text('Actif', style: TextStyle(color: Colors.white)), backgroundColor: Colors.green);
    } else {
      return const Chip(label: Text('Inactif', style: TextStyle(color: Colors.white)), backgroundColor: Colors.grey);
    }
  }

  Widget _buildUserActions(String userId, Map<String, dynamic> data) {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.visibility, size: 20),
          onPressed: () => _viewUserProfile(userId),
        ),
        IconButton(
          icon: const Icon(Icons.edit, size: 20),
          onPressed: () => _editUser(userId, data),
        ),
        if (data['isBanned'] == true)
          IconButton(
            icon: const Icon(Icons.person_add, size: 20, color: Colors.green),
            onPressed: () => _unbanUser(userId),
          )
        else
          IconButton(
            icon: const Icon(Icons.block, size: 20, color: Colors.red),
            onPressed: () => _banUser(userId),
          ),
      ],
    );
  }

  void _addNewUser() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ajouter un nouvel utilisateur'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(decoration: const InputDecoration(labelText: 'Nom complet')),
              TextFormField(decoration: const InputDecoration(labelText: 'Email'), keyboardType: TextInputType.emailAddress),
              TextFormField(decoration: const InputDecoration(labelText: 'Mot de passe'), obscureText: true),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('Créer')),
        ],
      ),
    );
  }

  void _viewUserProfile(String userId) {
    // Naviguer vers la page de profil de l'utilisateur
  }

  void _editUser(String userId, Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Modifier l\'utilisateur'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                initialValue: data['name'],
                decoration: const InputDecoration(labelText: 'Nom complet'),
              ),
              TextFormField(
                initialValue: data['email'],
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
              ),
              CheckboxListTile(
                title: const Text('Compte actif'),
                value: data['isActive'] ?? true,
                onChanged: (value) {},
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('Sauvegarder')),
        ],
      ),
    );
  }

  void _banUser(String userId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bannir l\'utilisateur'),
        content: const Text('Êtes-vous sûr de vouloir bannir cet utilisateur ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () {
              _firestore.collection('users').doc(userId).update({'isBanned': true});
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Bannir'),
          ),
        ],
      ),
    );
  }

  void _unbanUser(String userId) {
    _firestore.collection('users').doc(userId).update({'isBanned': false});
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Utilisateur débanni')),
    );
  }
}
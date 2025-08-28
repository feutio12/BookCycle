import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bookcycle/composants/common_components.dart';
import 'package:bookcycle/composants/common_utils.dart';

class AdminUsersManagement extends StatefulWidget {
  const AdminUsersManagement({super.key});

  @override
  State<AdminUsersManagement> createState() => _AdminUsersManagementState();
}

class _AdminUsersManagementState extends State<AdminUsersManagement> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _searchQuery = '';
  String _filterRole = 'Tous';

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Gestion des utilisateurs',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            // Search and filter bar
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Rechercher un utilisateur...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 16),
                DropdownButton<String>(
                  value: _filterRole,
                  items: const [
                    DropdownMenuItem(value: 'Tous', child: Text('Tous')),
                    DropdownMenuItem(value: 'user', child: Text('Utilisateurs')),
                    DropdownMenuItem(value: 'admin', child: Text('Administrateurs')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _filterRole = value!;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Users list
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore.collection('users').snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text('Erreur: ${snapshot.error}'));
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  var users = snapshot.data!.docs;

                  // Apply filters
                  if (_searchQuery.isNotEmpty) {
                    users = users.where((user) {
                      final name = user['name']?.toString().toLowerCase() ?? '';
                      final email = user['email']?.toString().toLowerCase() ?? '';
                      return name.contains(_searchQuery.toLowerCase()) ||
                          email.contains(_searchQuery.toLowerCase());
                    }).toList();
                  }

                  if (_filterRole != 'Tous') {
                    users = users.where((user) {
                      return user['role'] == _filterRole;
                    }).toList();
                  }

                  return ListView.builder(
                    itemCount: users.length,
                    itemBuilder: (context, index) {
                      final user = users[index];
                      final data = user.data() as Map<String, dynamic>;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppColors.primaryBlue,
                            child: Text(
                              data['name'] != null && data['name'].isNotEmpty
                                  ? data['name'][0].toUpperCase()
                                  : '?',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          title: Text(data['name'] ?? 'Sans nom'),
                          subtitle: Text(data['email'] ?? ''),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Chip(
                                label: Text(data['role'] ?? 'user'),
                                backgroundColor: data['role'] == 'admin'
                                    ? Colors.blue[100]
                                    : Colors.grey[200],
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () => _editUser(user.id, data),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () => _deleteUser(user.id, data['name'] ?? 'Utilisateur'),
                              ),
                            ],
                          ),
                        ),
                      );
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

  void _editUser(String userId, Map<String, dynamic> userData) {
    showDialog(
      context: context,
      builder: (context) {
        final nameController = TextEditingController(text: userData['name'] ?? '');
        final emailController = TextEditingController(text: userData['email'] ?? '');
        String selectedRole = userData['role'] ?? 'user';

        return SingleChildScrollView(
          child: AlertDialog(
            title: const Text('Modifier utilisateur'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Nom'),
                ),
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                  enabled: false,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedRole,
                  items: const [
                    DropdownMenuItem(value: 'user', child: Text('Utilisateur')),
                    DropdownMenuItem(value: 'admin', child: Text('Administrateur')),
                  ],
                  onChanged: (value) {
                    selectedRole = value!;
                  },
                  decoration: const InputDecoration(labelText: 'Rôle'),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Annuler'),
              ),
              ElevatedButton(
                onPressed: () async {
                  try {
                    await _firestore.collection('users').doc(userId).update({
                      'name': nameController.text,
                      'role': selectedRole,
                    });
                    Navigator.pop(context);
                    AppUtils.showSuccessSnackBar(context, 'Utilisateur modifié avec succès');
                  } catch (e) {
                    AppUtils.showErrorSnackBar(context, 'Erreur: $e');
                  }
                },
                child: const Text('Enregistrer'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _deleteUser(String userId, String userName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text('Êtes-vous sûr de vouloir supprimer l\'utilisateur "$userName"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              try {
                await _firestore.collection('users').doc(userId).delete();
                Navigator.pop(context);
                AppUtils.showSuccessSnackBar(context, 'Utilisateur supprimé avec succès');
              } catch (e) {
                AppUtils.showErrorSnackBar(context, 'Erreur: $e');
              }
            },
            child: const Text('Supprimer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
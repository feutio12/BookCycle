import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserManagementPage extends StatefulWidget {
  const UserManagementPage({super.key});

  @override
  State<UserManagementPage> createState() => _UserManagementPageState();
}

class _UserManagementPageState extends State<UserManagementPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des membres BookCycle'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Rechercher un membre',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {});
                  },
                ),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('users').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                final users = snapshot.data!.docs.where((user) {
                  final data = user.data() as Map<String, dynamic>;
                  final query = _searchController.text.toLowerCase();
                  return data['name'].toString().toLowerCase().contains(query) ||
                      data['email'].toString().toLowerCase().contains(query);
                }).toList();

                return ListView.builder(
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final user = users[index];
                    final data = user.data() as Map<String, dynamic>;

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundImage: data['photoUrl'] != null
                              ? NetworkImage(data['photoUrl'])
                              : null,
                          child: data['photoUrl'] == null
                              ? Text(data['name'][0])
                              : null,
                        ),
                        title: Text(data['name']),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(data['email']),
                            Text('${data['bookCount'] ?? 0} livres partagés'),
                          ],
                        ),
                        trailing: Switch(
                          value: data['isActive'] ?? true,
                          onChanged: (value) => _toggleUserStatus(user.id, value),
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
    );
  }

  Future<void> _toggleUserStatus(String userId, bool isActive) async {
    await _firestore.collection('users').doc(userId).update({
      'isActive': isActive,
      'statusChangedAt': DateTime.now(),
    });
  }
}
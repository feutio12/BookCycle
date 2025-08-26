import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class UserManagementPage extends StatefulWidget {
  const UserManagementPage({super.key});

  @override
  State<UserManagementPage> createState() => _UserManagementPageState();
}

class _UserManagementPageState extends State<UserManagementPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();
  int _selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des membres',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Rechercher un membre',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
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
          TabBar(
            onTap: (index) => setState(() => _selectedTab = index),
            labelColor: Colors.deepPurple,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.deepPurple,
            tabs: const [
              Tab(text: 'Tous les membres'),
              Tab(text: 'Actifs'),
              Tab(text: 'Inactifs'),
            ],
          ),
          Expanded(
            child: IndexedStack(
              index: _selectedTab,
              children: [
                _buildUserList(),
                _buildActiveUserList(),
                _buildInactiveUserList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserList() {
    return StreamBuilder<QuerySnapshot>(
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
              margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.deepPurple[100],
                  backgroundImage: data['photoUrl'] != null
                      ? NetworkImage(data['photoUrl'])
                      : null,
                  child: data['photoUrl'] == null
                      ? Text(data['name'][0], style: const TextStyle(color: Colors.deepPurple))
                      : null,
                ),
                title: Text(data['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(data['email'], style: const TextStyle(fontSize: 12)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.book, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text('${data['sharedBooksCount'] ?? 0} livres',
                            style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                      ],
                    ),
                  ],
                ),
                trailing: Switch(
                  value: data['isActive'] ?? true,
                  activeColor: Colors.deepPurple,
                  onChanged: (value) => _toggleUserStatus(user.id, value),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildActiveUserList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('users').where('isActive', isEqualTo: true).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        final users = snapshot.data!.docs.where((user) {
          final data = user.data() as Map<String, dynamic>;
          final query = _searchController.text.toLowerCase();
          return data['name'].toString().toLowerCase().contains(query) ||
              data['email'].toString().toLowerCase().contains(query);
        }).toList();

        return _buildUserListView(users);
      },
    );
  }

  Widget _buildInactiveUserList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('users').where('isActive', isEqualTo: false).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        final users = snapshot.data!.docs.where((user) {
          final data = user.data() as Map<String, dynamic>;
          final query = _searchController.text.toLowerCase();
          return data['name'].toString().toLowerCase().contains(query) ||
              data['email'].toString().toLowerCase().contains(query);
        }).toList();

        return _buildUserListView(users);
      },
    );
  }

  Widget _buildUserListView(List<QueryDocumentSnapshot> users) {
    if (users.isEmpty) {
      return const Center(child: Text('Aucun utilisateur trouvé'));
    }

    return ListView.builder(
      itemCount: users.length,
      itemBuilder: (context, index) {
        final user = users[index];
        final data = user.data() as Map<String, dynamic>;

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.deepPurple[100],
              backgroundImage: data['photoUrl'] != null
                  ? NetworkImage(data['photoUrl'])
                  : null,
              child: data['photoUrl'] == null
                  ? Text(data['name'][0], style: const TextStyle(color: Colors.deepPurple))
                  : null,
            ),
            title: Text(data['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(data['email'], style: const TextStyle(fontSize: 12)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.book, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text('${data['sharedBooksCount'] ?? 0} livres',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                  ],
                ),
              ],
            ),
            trailing: Switch(
              value: data['isActive'] ?? true,
              activeColor: Colors.deepPurple,
              onChanged: (value) => _toggleUserStatus(user.id, value),
            ),
          ),
        );
      },
    );
  }

  Future<void> _toggleUserStatus(String userId, bool isActive) async {
    await _firestore.collection('users').doc(userId).update({
      'isActive': isActive,
      'statusChangedAt': DateTime.now(),
    });
  }
}
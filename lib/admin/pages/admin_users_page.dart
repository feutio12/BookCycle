import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bookcycle/admin/widgets/admin_drawer.dart';
import 'package:bookcycle/admin/widgets/data_table.dart';
import 'package:bookcycle/admin/services/admin_service.dart';

class AdminUsersPage extends StatefulWidget {
  @override
  _AdminUsersPageState createState() => _AdminUsersPageState();
}

class _AdminUsersPageState extends State<AdminUsersPage> {
  final AdminService _adminService = AdminService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Gestion des utilisateurs'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      drawer: AdminDrawer(),
      body: StreamBuilder<QuerySnapshot>(
        stream: _adminService.getUsers(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Erreur: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          final users = snapshot.data!.docs;

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Liste des utilisateurs (${users.length})',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 16),
                Expanded(
                  child: AdminDataTable(
                    columns: [
                      DataColumn(label: Text('Nom')),
                      DataColumn(label: Text('Email')),
                      DataColumn(label: Text('Inscription')),
                      DataColumn(label: Text('Statut')),
                      DataColumn(label: Text('Actions')),
                    ],
                    rows: users.map((user) {
                      final data = user.data() as Map<String, dynamic>;
                      return DataRow(cells: [
                        DataCell(Text(data['name'] ?? 'N/A')),
                        DataCell(Text(data['email'] ?? 'N/A')),
                        DataCell(Text(data['createdAt'] != null
                            ? DateTime.fromMillisecondsSinceEpoch(data['createdAt'].millisecondsSinceEpoch).toString().substring(0, 10)
                            : 'N/A')),
                        DataCell(
                          Chip(
                            label: Text(
                              data['isActive'] == true ? 'Actif' : 'Inactif',
                              style: TextStyle(color: Colors.white),
                            ),
                            backgroundColor: data['isActive'] == true ? Colors.green : Colors.red,
                          ),
                        ),
                        DataCell(Row(
                          children: [
                            IconButton(
                              icon: Icon(Icons.visibility, color: Colors.blue),
                              onPressed: () {
                                // Voir les détails de l'utilisateur
                              },
                            ),
                            IconButton(
                              icon: Icon(
                                data['isActive'] == true ? Icons.block : Icons.check_circle,
                                color: data['isActive'] == true ? Colors.red : Colors.green,
                              ),
                              onPressed: () {
                                _adminService.updateUserStatus(user.id, !(data['isActive'] ?? false));
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
}
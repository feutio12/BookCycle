import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bookcycle/admin/widgets/admin_drawer.dart';
import 'package:bookcycle/admin/widgets/data_table.dart';
import 'package:bookcycle/admin/services/admin_service.dart';

class AdminChatsPage extends StatefulWidget {
  @override
  _AdminChatsPageState createState() => _AdminChatsPageState();
}

class _AdminChatsPageState extends State<AdminChatsPage> {
  final AdminService _adminService = AdminService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Gestion des conversations'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      drawer: AdminDrawer(),
      body: StreamBuilder<QuerySnapshot>(
        stream: _adminService.getChats(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Erreur: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          final chats = snapshot.data!.docs;

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Liste des conversations (${chats.length})',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 16),
                Expanded(
                  child: AdminDataTable(
                    columns: [
                      DataColumn(label: Text('Participants')),
                      DataColumn(label: Text('Dernier message')),
                      DataColumn(label: Text('Date')),
                      DataColumn(label: Text('Messages')),
                      DataColumn(label: Text('Actions')),
                    ],
                    rows: chats.map((chat) {
                      final data = chat.data() as Map<String, dynamic>;
                      final participants = data['participants'] != null
                          ? (data['participants'] as List<dynamic>).join(', ')
                          : 'N/A';

                      final lastMessage = data['lastMessage'] ?? 'Aucun message';
                      final lastMessageTime = data['lastMessageTime'] != null
                          ? _formatDateTime(data['lastMessageTime'].toDate())
                          : 'N/A';

                      final messageCount = data['messageCount'] ?? 0;

                      return DataRow(cells: [
                        DataCell(
                          ConstrainedBox(
                            constraints: BoxConstraints(maxWidth: 200),
                            child: Text(
                              participants,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        DataCell(
                          ConstrainedBox(
                            constraints: BoxConstraints(maxWidth: 200),
                            child: Text(
                              lastMessage,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        DataCell(Text(lastMessageTime)),
                        DataCell(Text('$messageCount')),
                        DataCell(Row(
                          children: [
                            IconButton(
                              icon: Icon(Icons.visibility, color: Colors.blue),
                              onPressed: () {
                                // Voir la conversation
                              },
                            ),
                            IconButton(
                              icon: Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                _showDeleteDialog(context, chat.id, participants);
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

  String _formatDateTime(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _showDeleteDialog(BuildContext context, String chatId, String participants) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirmer la suppression'),
          content: Text('Êtes-vous sûr de vouloir supprimer la conversation avec $participants?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Annuler'),
            ),
            TextButton(
              onPressed: () {
                _adminService.deleteChat(chatId);
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Conversation supprimée avec succès')),
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
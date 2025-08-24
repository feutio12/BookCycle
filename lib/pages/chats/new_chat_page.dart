import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../composants/common_components.dart';
import '../pages rincipales/chatpage.dart';
import 'chat_service.dart';
class NewChatPage extends StatelessWidget {
  const NewChatPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nouvelle conversation'),
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Erreur: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final currentUserId = FirebaseAuth.instance.currentUser?.uid;
          final users = snapshot.data!.docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return data['uid'] != currentUserId;
          }).toList();

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final userDoc = users[index];
              final userData = userDoc.data() as Map<String, dynamic>;

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.primaryBlue,
                  child: Text(
                    userData['name'] != null && userData['name'].isNotEmpty
                        ? userData['name'][0].toUpperCase()
                        : '?',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                title: Text(userData['name'] ?? 'Utilisateur inconnu'),
                subtitle: Text(userData['email'] ?? ''),
                onTap: () async {
                  final chatId = ChatService.generateChatId(
                    currentUserId!,
                    userData['uid'],
                  );

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatPage(
                        chatId: chatId,
                        otherUserId: userData['uid'],
                        otherUserName: userData['name'] ?? 'Utilisateur',
                        initialMessage: null,
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../composants/common_components.dart';
import '../../models/chats.dart';
import '../pages rincipales/chatpage.dart';

class DiscussionsListPage extends StatefulWidget {
  const DiscussionsListPage({super.key, required List<ChatDiscussion> discussions});

  @override
  State<DiscussionsListPage> createState() => _DiscussionsListPageState();
}

class _DiscussionsListPageState extends State<DiscussionsListPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late Stream<QuerySnapshot> _discussionsStream;

  @override
  void initState() {
    super.initState();
    _loadDiscussions();
  }

  void _loadDiscussions() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    _discussionsStream = _firestore
        .collection('chats')
        .where('participants', arrayContains: currentUser.uid)
        .orderBy('lastMessageTime', descending: true)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = _auth.currentUser;

    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Messages'),
          backgroundColor: AppColors.primaryBlue,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: InfoMessage(
            message: 'Vous devez être connecté pour voir vos messages',
            icon: Icons.chat,
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _discussionsStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: ErrorMessage(message: 'Erreur: ${snapshot.error}'),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingIndicator(message: 'Chargement des discussions...');
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: InfoMessage(
                message: 'Aucune discussion pour le moment',
                icon: Icons.chat_bubble_outline,
              ),
            );
          }

          final discussions = snapshot.data!.docs.map((doc) {
            return ChatDiscussion.fromFirestore(doc);
          }).toList();

          return ListView.builder(
            itemCount: discussions.length,
            itemBuilder: (context, index) {
              final discussion = discussions[index];
              return _DiscussionTile(
                discussion: discussion,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatPage(
                        chatId: discussion.chatId,
                        otherUserId: discussion.otherUserId,
                        otherUserName: discussion.otherUserName, initialMessage: '',
                      ),
                    ),
                  ).then((_) {
                    // Rafraîchir la liste après retour de la page de chat
                    setState(() {
                      _loadDiscussions();
                    });
                  });
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _DiscussionTile extends StatelessWidget {
  final ChatDiscussion discussion;
  final VoidCallback onTap;

  const _DiscussionTile({
    required this.discussion,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: AppColors.primaryBlue,
        child: Text(
          discussion.otherUserName.isNotEmpty
              ? discussion.otherUserName[0].toUpperCase()
              : '?',
          style: const TextStyle(color: Colors.white),
        ),
      ),
      title: Text(
        discussion.otherUserName,
        style: TextStyle(
          fontWeight: discussion.unreadCount > 0
              ? FontWeight.bold
              : FontWeight.normal,
        ),
      ),
      subtitle: Text(
        discussion.lastMessage,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontWeight: discussion.unreadCount > 0
              ? FontWeight.bold
              : FontWeight.normal,
        ),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            _formatMessageTime(discussion.lastMessageTime),
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          if (discussion.unreadCount > 0)
            Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: Text(
                discussion.unreadCount > 9
                    ? '9+'
                    : discussion.unreadCount.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      onTap: onTap,
    );
  }

  String _formatMessageTime(DateTime timestamp) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDay = DateTime(
        timestamp.year,
        timestamp.month,
        timestamp.day
    );

    if (messageDay == today) {
      return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    } else if (messageDay == today.subtract(const Duration(days: 1))) {
      return 'Hier';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }
}
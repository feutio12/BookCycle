import 'package:bookcycle/pages/chats/subscription_manager.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../composants/common_components.dart';
import '../../models/chats.dart';
import '../chatbot/chatbot_service.dart';
import 'chatpage.dart' hide InfoMessage, ErrorMessage;
import 'chat_utils.dart';

class DiscussionsListPage extends StatefulWidget {
  const DiscussionsListPage({super.key});

  @override
  State<DiscussionsListPage> createState() => _DiscussionsListPageState();
}

class _DiscussionsListPageState extends State<DiscussionsListPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final SubscriptionManager _subscriptionManager = SubscriptionManager();

  Stream<QuerySnapshot>? _discussionsStream;

  @override
  void initState() {
    super.initState();
    _loadDiscussions();
  }

  void _loadDiscussions() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    _discussionsStream = FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser.uid)
        .collection('chats')
        .orderBy('lastMessageTime', descending: true)
        .snapshots();
  }

  Future<void> _refreshDiscussions() async {
    setState(() {
      _loadDiscussions();
    });
  }

  @override
  void dispose() {
    _subscriptionManager.dispose(); // Nettoyer les subscriptions
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = _auth.currentUser;

    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Messages'),
          backgroundColor: Colors.blue,
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
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshDiscussions,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshDiscussions,
        child: StreamBuilder<QuerySnapshot>(
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
                final data = doc.data() as Map<String, dynamic>;
                return ChatDiscussion(
                  chatId: doc.id,
                  participants: [],
                  otherUserId: data['otherUserId'] ?? '',
                  otherUserName: data['otherUserName'] ?? 'Utilisateur inconnu',
                  lastMessage: data['lastMessage'] ?? '',
                  lastMessageTime: (data['lastMessageTime'] as Timestamp).toDate(),
                  lastMessageSenderId: data['lastMessageSenderId'] ?? '',
                  unreadCount: data['unreadCount'] ?? 0,
                );
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
                            otherUserName: discussion.otherUserName,
                            initialMessage: '',
                          ),
                        ),
                      ).then((_) {
                        // Rafraîchir la liste après retour de la discussion
                        _refreshDiscussions();
                      });
                    },
                  );
                },
              );
            }
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ChatBotPage()),
          );
        },
        backgroundColor: Colors.white,
        foregroundColor: Colors.blue,
        elevation: 8.0,
        highlightElevation: 12.0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
          side: BorderSide(color: Colors.blue.shade100, width: 2.0),
        ),
        tooltip: 'Parler avec notre assistant',
        child: Container(
          padding: EdgeInsets.all(8.0),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade50, Colors.white],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: Image.asset(
            'assets/images/book.png',
            width: 32,
            height: 32,

          ),
        ),
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
        backgroundColor: Colors.blue,
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
            ChatUtils.formatMessageTime(discussion.lastMessageTime),
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
}
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/chats.dart';
import 'chat_service.dart';
import 'chat_utils.dart' hide ChatService;
import 'publisher_profile_page.dart';

class ChatPage extends StatefulWidget {
  final String chatId;
  final String otherUserId;
  final String otherUserName;
  final String? initialMessage;

  const ChatPage({
    super.key,
    required this.chatId,
    required this.otherUserId,
    required this.otherUserName,
    this.initialMessage,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Stream<QuerySnapshot>? _messagesStream;
  bool _isSending = false;
  bool _isInitializing = true;
  Set<String> _readMessages = {};
  bool _isOtherUserOnline = false;
  late final StreamSubscription<DocumentSnapshot> _userStatusSubscription;

  @override
  void initState() {
    super.initState();
    _initializeChat();
    _prefillInitialMessage();
    _subscribeToUserStatus();
  }

  void _subscribeToUserStatus() {
    // Écouter les changements de statut de l'autre utilisateur
    _userStatusSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.otherUserId)
        .snapshots()
        .listen((snapshot) {
      if (mounted) {
        setState(() {
          _isOtherUserOnline = snapshot.data()?['isOnline'] ?? false;
        });
      }
    });
  }

  Future<void> _initializeChat() async {
    try {
      await ChatService.createChatIfNeeded(
        chatId: widget.chatId,
        otherUserId: widget.otherUserId,
        otherUserName: widget.otherUserName,
      );

      setState(() {
        _messagesStream = ChatService.getMessagesStream(widget.chatId);
        _isInitializing = false;
      });

      _markMessagesAsRead();

      // Scroll to bottom after initialization
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.jumpTo(0);
        }
      });
    } catch (e) {
      debugPrint('Erreur lors de l\'initialisation du chat: $e');
      setState(() {
        _isInitializing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de l\'initialisation du chat: $e')),
      );
    }
  }

  void _prefillInitialMessage() {
    if (widget.initialMessage != null && widget.initialMessage!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _messageController.text = widget.initialMessage!;
      });
    }
  }

  Future<void> _markMessagesAsRead() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return;

      final messages = await FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.chatId)
          .collection('messages')
          .where('senderId', isNotEqualTo: currentUser.uid)
          .where('read', isEqualTo: false)
          .get();

      for (var doc in messages.docs) {
        await ChatService.updateMessageReadStatus(widget.chatId, doc.id);
        _readMessages.add(doc.id);
      }

      await ChatService.markMessagesAsRead(widget.chatId);
    } catch (e) {
      debugPrint('Erreur lors du marquage des messages comme lus: $e');
    }
  }

  Future<void> _sendMessage() async {
    if (_isSending) return;

    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    setState(() {
      _isSending = true;
    });

    try {
      await ChatService.sendMessage(
        chatId: widget.chatId,
        content: content,
        otherUserId: widget.otherUserId,
        otherUserName: widget.otherUserName,
      );

      _messageController.clear();

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      debugPrint('Erreur lors de l\'envoi du message: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de l\'envoi du message: $e')),
      );
    } finally {
      setState(() {
        _isSending = false;
      });
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _userStatusSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PublisherProfilePage(
                  publisherId: widget.otherUserId,
                  publisherName: widget.otherUserName,
                ),
              ),
            );
          },
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.blue,
                child: Text(
                  widget.otherUserName.isNotEmpty
                      ? widget.otherUserName[0].toUpperCase()
                      : '?',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.otherUserName,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      _isOtherUserOnline ? "En ligne" : "Hors ligne",
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: _isOtherUserOnline ? Colors.green : Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.videocam),
            tooltip: 'Appel vidéo',
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.call),
            tooltip: 'Appel vocal',
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'profile') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PublisherProfilePage(
                      publisherId: widget.otherUserId,
                      publisherName: widget.otherUserName,
                    ),
                  ),
                );
              } else if (value == 'clear') {
                _showClearChatDialog();
              }
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem<String>(
                value: 'profile',
                child: Text('Voir le profil'),
              ),
              const PopupMenuItem<String>(
                value: 'clear',
                child: Text('Effacer la conversation'),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _isInitializing
                ? const Center(child: CircularProgressIndicator())
                : StreamBuilder<QuerySnapshot>(
              stream: _messagesStream,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: ErrorMessage(
                      message: 'Erreur: ${snapshot.error}',
                      onRetry: _initializeChat,
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final messages = snapshot.data!.docs;

                if (messages.isEmpty) {
                  return const Center(
                    child: InfoMessage(
                      message: 'Aucun message pour le moment',
                      icon: Icons.chat_bubble_outline,
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final messageDoc = messages[index];
                    final messageData = messageDoc.data() as Map<String, dynamic>;

                    final message = ChatMessage(
                      id: messageDoc.id,
                      senderId: messageData['senderId'] ?? '',
                      senderName: messageData['senderName'] ?? 'Inconnu',
                      content: messageData['content'] ?? '',
                      timestamp: (messageData['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
                      isRead: messageData['read'] ?? false,
                    );

                    final isMe = message.senderId == _auth.currentUser?.uid;
                    final isRead = isMe ? message.isRead : true;

                    return MessageBubble(
                      message: message,
                      isMe: isMe,
                      isRead: isRead,
                    );
                  },
                );
              },
            ),
          ),
          MessageInputField(
            controller: _messageController,
            onSend: _sendMessage,
            isSending: _isSending,
          ),
        ],
      ),
    );
  }

  void _showClearChatDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Effacer la conversation'),
          content: const Text('Êtes-vous sûr de vouloir effacer toute la conversation? Cette action est irréversible.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Implémenter la logique pour effacer la conversation
              },
              child: const Text('Effacer', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }
}

// Composants supplémentaires pour une meilleure expérience
class ErrorMessage extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const ErrorMessage({super.key, required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
              child: const Text('Réessayer'),
            ),
          ],
        ],
      ),
    );
  }
}

class InfoMessage extends StatelessWidget {
  final String message;
  final IconData icon;

  const InfoMessage({super.key, required this.message, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 48, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }
}
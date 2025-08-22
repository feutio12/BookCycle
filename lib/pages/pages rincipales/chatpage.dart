import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/chats.dart';
import '../chats/chat_service.dart';
import '../chats/chat_utils.dart';

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

  @override
  void initState() {
    super.initState();
    _initializeChat();
    _prefillInitialMessage();
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
    } catch (e) {
      debugPrint('Erreur lors de l\'initialisation du chat: $e');
      setState(() {
        _isInitializing = false;
      });
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.blue,
              // backgroundImage: ,
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.otherUserName,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  "En ligne",
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.green,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.videocam)),
          IconButton(onPressed: () {}, icon: const Icon(Icons.call)),
          IconButton(onPressed: () {}, icon: const Icon(Icons.more_vert)),
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
                  return Center(child: Text('Erreur: ${snapshot.error}'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final messages = snapshot.data!.docs;

                if (messages.isEmpty) {
                  return const Center(
                    child: Text('Aucun message pour le moment'),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final messageDoc = messages[index];
                    final messageData =
                    messageDoc.data() as Map<String, dynamic>;

                    final message = ChatMessage(
                      id: messageDoc.id,
                      senderId: messageData['senderId'] ?? '',
                      senderName: messageData['senderName'] ?? 'Inconnu',
                      content: messageData['content'] ?? '',
                      timestamp: (messageData['timestamp'] as Timestamp?)
                          ?.toDate() ??
                          DateTime.now(),
                      isRead: messageData['read'] ?? false,
                    );

                    final isMe =
                        message.senderId == _auth.currentUser?.uid;
                    final isRead = isMe
                        ? (_readMessages.contains(message.id) ||
                        message.isRead)
                        : true;

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
}
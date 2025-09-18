import 'dart:async';
import 'package:bookcycle/pages/chats/subscription_manager.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/chats.dart';
import '../../utils/stream_page_mixin.dart';
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

class _ChatPageState extends State<ChatPage> with StreamPageMixin {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final SubscriptionManager _subscriptionManager = SubscriptionManager();
  final FocusNode _messageFocusNode = FocusNode();

  Stream<QuerySnapshot>? _messagesStream;
  bool _isSending = false;
  bool _isInitializing = true;
  int _unreadCount = 0;
  bool _isOtherUserOnline = false;
  late StreamSubscription<QuerySnapshot> _messagesSubscription;
  Map<String, bool> _readStatus = {};

  @override
  void initState() {
    super.initState();
    _initializeChat();
    _prefillInitialMessage();
    _subscribeToUnreadMessages();
    _subscribeToUserStatus();
    _fetchOtherUserNameIfNeeded();
    _subscribeToReadStatus();
  }

  void _subscribeToReadStatus() {
    _messagesSubscription = FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chatId)
        .collection('messages')
        .snapshots()
        .listen((snapshot) {
      if (mounted) {
        for (var change in snapshot.docChanges) {
          if (change.type == DocumentChangeType.modified) {
            final messageData = change.doc.data() as Map<String, dynamic>;
            setState(() {
              _readStatus[change.doc.id] = messageData['read'] ?? false;
            });
          }
        }
      }
    });

    _subscriptionManager.add(_messagesSubscription);
  }

  void _fetchOtherUserNameIfNeeded() async {
    if (widget.otherUserName.isEmpty || widget.otherUserName == 'Vendeur') {
      try {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.otherUserId)
            .get();

        if (userDoc.exists) {
          final userData = userDoc.data() as Map<String, dynamic>;
          final userName = userData['name'] ?? userData['email'] ?? 'Utilisateur';
          // Mise à jour du nom si nécessaire
        }
      } catch (e) {
        debugPrint('Erreur lors de la récupération du nom: $e');
      }
    }
  }

  void _subscribeToUnreadMessages() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    final unreadSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser.uid)
        .collection('chats')
        .doc(widget.chatId)
        .snapshots()
        .listen((snapshot) {
      if (mounted && snapshot.exists) {
        final unreadCount = snapshot.data()?['unreadCount'] ?? 0;
        setState(() {
          _unreadCount = unreadCount;
        });
      }
    });

    _subscriptionManager.add(unreadSubscription);
  }

  void _subscribeToUserStatus() {
    final statusSubscription = FirebaseFirestore.instance
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

    _subscriptionManager.add(statusSubscription);
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
          .where('senderId', isEqualTo: widget.otherUserId)
          .where('read', isEqualTo: false)
          .get();

      final batch = FirebaseFirestore.instance.batch();
      for (var doc in messages.docs) {
        batch.update(doc.reference, {'read': true});
        setState(() {
          _readStatus[doc.id] = true;
        });
      }

      await batch.commit();

      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .collection('chats')
          .doc(widget.chatId)
          .update({'unreadCount': 0});

      setState(() {
        _unreadCount = 0;
      });
    } catch (e) {
      debugPrint('Erreur lors du marquage des messages comme lus: $e');
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (ModalRoute.of(context)?.isCurrent ?? false) {
      _markMessagesAsRead();
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
    _messageFocusNode.dispose();
    _subscriptionManager.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
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
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.blue[500],
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    widget.otherUserName.isNotEmpty
                        ? widget.otherUserName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.otherUserName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _isOtherUserOnline ? "En ligne" : "Hors ligne",
                      style: TextStyle(
                        fontSize: 12,
                        color: _isOtherUserOnline ? Colors.green[600] : Colors.grey[600],
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
            icon: Icon(Icons.videocam, color: Colors.blue[600]),
            tooltip: 'Appel vidéo',
          ),
          IconButton(
            onPressed: () {},
            icon: Icon(Icons.call, color: Colors.blue[600]),
            tooltip: 'Appel vocal',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _isInitializing
                ? _buildLoadingState()
                : StreamBuilder<QuerySnapshot>(
              stream: _messagesStream,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return _buildErrorState(snapshot.error.toString());
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return _buildLoadingState();
                }

                final messages = snapshot.data!.docs;

                if (messages.isEmpty) {
                  return _buildEmptyState();
                }

                return Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.grey[50]!,
                        Colors.grey[100]!,
                      ],
                    ),
                  ),
                  child: ListView.builder(
                    controller: _scrollController,
                    reverse: true,
                    padding: const EdgeInsets.all(16),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final messageDoc = messages[index];
                      final messageData = messageDoc.data() as Map<String, dynamic>;

                      final message = ChatMessage(
                        id: messageDoc.id,
                        senderId: messageData['senderId'] ?? '',
                        senderName: messageData['senderName'],
                        content: messageData['content'] ?? '',
                        timestamp: (messageData['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
                        isRead: messageData['read'] ?? false,
                      );

                      final isMe = message.senderId == _auth.currentUser?.uid;
                      final isRead = isMe ? (_readStatus[message.id] ?? message.isRead) : true;

                      return _buildMessageBubble(message, isMe, isRead);
                    },
                  ),
                );
              },
            ),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[600]!),
          ),
          const SizedBox(height: 16),
          Text(
            'Chargement de la conversation...',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Colors.red[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Erreur de chargement',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _initializeChat,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[600],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Commencez la conversation',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Envoyez votre premier message à ${widget.otherUserName}',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message, bool isMe, bool isRead) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe)
            Container(
              width: 32,
              height: 32,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: Colors.blue[400],
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  message.senderName.isNotEmpty
                      ? message.senderName[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isMe ? Colors.blue[600] : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: isMe ? const Radius.circular(16) : const Radius.circular(4),
                  bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.content,
                    style: TextStyle(
                      color: isMe ? Colors.white : Colors.black87,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        _formatTime(message.timestamp),
                        style: TextStyle(
                          color: isMe ? Colors.white70 : Colors.grey[600],
                          fontSize: 10,
                        ),
                      ),
                      if (isMe) ...[
                        const SizedBox(width: 4),
                        Icon(
                          isRead ? Icons.done_all : Icons.done,
                          size: 12,
                          color: isRead ? Colors.blue[100] : Colors.white70,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(25),
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () {},
                    icon: Icon(Icons.emoji_emotions_outlined, color: Colors.grey[600]),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      focusNode: _messageFocusNode,
                      decoration: InputDecoration(
                        hintText: 'Tapez votre message...',
                        hintStyle: TextStyle(color: Colors.grey[600]),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      maxLines: null,
                      textCapitalization: TextCapitalization.sentences,
                    ),
                  ),
                  IconButton(
                    onPressed: () {},
                    icon: Icon(Icons.attach_file, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.blue[600],
              shape: BoxShape.circle,
            ),
            child: IconButton(
              onPressed: _sendMessage,
              icon: _isSending
                  ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
                  : const Icon(Icons.send, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(timestamp.year, timestamp.month, timestamp.day);

    if (messageDate == today) {
      return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    } else {
      return '${timestamp.day}/${timestamp.month} ${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    }
  }
}
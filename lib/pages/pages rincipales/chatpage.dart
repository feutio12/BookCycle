// chatpage.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// 1. Modèle de discussion
class ChatDiscussion {
  final String chatId;
  final String otherUserId;
  final String otherUserName;
  final String lastMessage;
  final DateTime lastMessageTime;
  final int unreadCount;

  ChatDiscussion({
    required this.chatId,
    required this.otherUserId,
    required this.otherUserName,
    required this.lastMessage,
    required this.lastMessageTime,
    this.unreadCount = 0,
  });

  String get formattedTime => DateFormat('HH:mm').format(lastMessageTime);
}

// 2. Page de liste des discussions
class DiscussionsListPage extends StatelessWidget {
  final List<ChatDiscussion> discussions;

  const DiscussionsListPage({super.key, required this.discussions});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
      ),
      body: ListView.builder(
        itemCount: discussions.length,
        itemBuilder: (context, index) {
          final discussion = discussions[index];
          return ListTile(
            leading: CircleAvatar(
              child: Text(discussion.otherUserName[0]),
            ),
            title: Text(discussion.otherUserName),
            subtitle: Text(discussion.lastMessage),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(discussion.formattedTime),
                if (discussion.unreadCount > 0)
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      discussion.unreadCount.toString(),
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
              ],
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatPage(
                    chatId: discussion.chatId,
                    otherUserName: discussion.otherUserName,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// 3. Modèle de message (inchangé)
class ChatMessage {
  final String senderId;
  final String content;
  final DateTime timestamp;
  final bool isMe;

  ChatMessage({
    required this.senderId,
    required this.content,
    required this.timestamp,
    required this.isMe,
  });

  String get formattedTime => DateFormat('HH:mm').format(timestamp);
}

// 4. Contrôleur de chat (inchangé)
class ChatController {
  final List<ChatMessage> _messages = [];
  final TextEditingController messageController = TextEditingController();

  List<ChatMessage> get messages => _messages;

  void addMessage(String content, String senderId, bool isMe) {
    final message = ChatMessage(
      senderId: senderId,
      content: content,
      timestamp: DateTime.now(),
      isMe: isMe,
    );
    _messages.add(message);
  }

  void dispose() {
    messageController.dispose();
  }
}

class ChatPage extends StatefulWidget {
  final String chatId;
  final String otherUserName;
  final String? initialMessage; // Nouveau paramètre optionnel

  const ChatPage({
    super.key,
    required this.chatId,
    required this.otherUserName,
    this.initialMessage, // Message initial optionnel
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  late final ChatController _chatController;

  @override
  void initState() {
    super.initState();
    _chatController = ChatController();
    _loadMessages();
  }

  Future<void> _loadMessages() async {
    // Ajoute le message initial s'il est fourni
    if (widget.initialMessage != null) {
      _chatController.addMessage(
        widget.initialMessage!,
        widget.otherUserName,
        false,
      );
    }
    if (mounted) setState(() {});
  }

  void _sendMessage() {
    final content = _chatController.messageController.text.trim();
    if (content.isEmpty) return;

    _chatController.addMessage(content, "Moi", true);
    _chatController.messageController.clear();
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _chatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Discussion avec ${widget.otherUserName}"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              reverse: true,
              itemCount: _chatController.messages.length,
              itemBuilder: (context, index) {
                final message = _chatController.messages.reversed.toList()[index];
                return _MessageBubble(message: message);
              },
            ),
          ),
          _MessageInputField(
            controller: _chatController.messageController,
            onSend: _sendMessage,
          ),
        ],
      ),
    );
  }
}

// 6. Widgets pour les bulles de message et champ de saisie (inchangés)
class _MessageBubble extends StatelessWidget {
  final ChatMessage message;

  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: message.isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
        decoration: BoxDecoration(
          color: message.isMe
              ? Theme.of(context).colorScheme.primary
              : Colors.grey[300],
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: message.isMe ? const Radius.circular(16) : const Radius.circular(0),
            bottomRight: message.isMe ? const Radius.circular(0) : const Radius.circular(16),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!message.isMe)
              Text(
                message.senderId,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.secondary,
                ),
              ),
            Text(
              message.content,
              style: TextStyle(
                color: message.isMe ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              message.formattedTime,
              style: TextStyle(
                fontSize: 10,
                color: message.isMe ? Colors.white70 : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageInputField extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;

  const _MessageInputField({
    required this.controller,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: "Écrire un message...",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24.0),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 12.0,
                ),
              ),
              onSubmitted: (_) => onSend(),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: onSend,
          ),
        ],
      ),
    );
  }
}
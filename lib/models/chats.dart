import 'package:cloud_firestore/cloud_firestore.dart';

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
    required this.unreadCount,
  });

  // Convertir à partir d'un DocumentSnapshot Firestore
  factory ChatDiscussion.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChatDiscussion(
      chatId: doc.id,
      otherUserId: data['otherUserId'] ?? '',
      otherUserName: data['otherUserName'] ?? 'Utilisateur inconnu',
      lastMessage: data['lastMessage'] ?? 'Aucun message',
      lastMessageTime: (data['lastMessageTime'] as Timestamp).toDate(),
      unreadCount: data['unreadCount'] ?? 0,
    );
  }
}

class ChatMessage {
  final String senderId;
  final String senderName;
  final String content;
  final DateTime timestamp;

  ChatMessage({
    required this.senderId,
    required this.senderName,
    required this.content,
    required this.timestamp,
  });

  // Convertir en Map pour Firestore
  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'senderName': senderName,
      'content': content,
      'timestamp': timestamp,
    };
  }

  // Créer à partir d'un DocumentSnapshot Firestore
  factory ChatMessage.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChatMessage(
      senderId: data['senderId'] ?? '',
      senderName: data['senderName'] ?? 'Inconnu',
      content: data['content'] ?? '',
      timestamp: (data['timestamp'] as Timestamp).toDate(),
    );
  }

  // Formater l'heure pour l'affichage
  String get formattedTime {
    return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
  }
}
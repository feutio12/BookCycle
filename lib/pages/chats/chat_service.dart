import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChatService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static String generateChatId(String userId1, String userId2) {
    final ids = [userId1, userId2]..sort();
    return 'chat_${ids[0]}_${ids[1]}';
  }

  static Future<void> markMessagesAsRead(String chatId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return;

      final chatDoc = await _firestore.collection('chats').doc(chatId).get();
      if (chatDoc.exists) {
        await _firestore.collection('chats').doc(chatId).update({
          'unreadCount': 0,
        });
      }
    } catch (e) {
      print('Erreur lors du marquage des messages comme lus: $e');
    }
  }

  static Stream<QuerySnapshot> getChatsStream(String userId) {
    return _firestore
        .collection('chats')
        .where('participants', arrayContains: userId)
        .orderBy('lastMessageTime', descending: true)
        .snapshots();
  }

  static Future<void> sendMessage({
    required String chatId,
    required String content,
    required String otherUserId,
    required String otherUserName,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return;

      final messageData = {
        'senderId': currentUser.uid,
        'senderName': currentUser.displayName ?? 'Anonyme',
        'content': content,
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
      };

      await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .add(messageData);

      await _firestore.collection('chats').doc(chatId).update({
        'lastMessage': content,
        'lastMessageTime': FieldValue.serverTimestamp(),
        'lastMessageSenderId': currentUser.uid,
        'unreadCount': FieldValue.increment(1),
        'otherUserId': otherUserId,
        'otherUserName': otherUserName,
      });
    } catch (e) {
      print('Erreur lors de l\'envoi du message: $e');
      rethrow;
    }
  }

  static Future<void> createChatIfNeeded({
    required String chatId,
    required String otherUserId,
    required String otherUserName,
  }) async {
    try {
      final chatDoc = await _firestore.collection('chats').doc(chatId).get();
      if (!chatDoc.exists) {
        final currentUser = _auth.currentUser;
        if (currentUser == null) return;

        await _firestore.collection('chats').doc(chatId).set({
          'participants': [currentUser.uid, otherUserId],
          'lastMessage': '',
          'lastMessageTime': FieldValue.serverTimestamp(),
          'lastMessageSenderId': '',
          'unreadCount': 0,
          'otherUserId': otherUserId,
          'otherUserName': otherUserName,
        });

        await _firestore
            .collection('chats')
            .doc(chatId)
            .collection('messages')
            .add({
          'senderId': 'system',
          'senderName': 'Système',
          'content': 'Conversation démarrée',
          'timestamp': FieldValue.serverTimestamp(),
          'read': true,
        });
      }
    } catch (e) {
      print('Erreur lors de la création du chat: $e');
      rethrow;
    }
  }

  static Future<void> updateMessageReadStatus(String chatId, String messageId) async {
    try {
      await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc(messageId)
          .update({'read': true});
    } catch (e) {
      print('Erreur lors de la mise à jour du statut de lecture: $e');
    }
  }

  static Stream<QuerySnapshot> getMessagesStream(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }
}
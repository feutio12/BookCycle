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

      // Update unread count in chat document
      await _firestore.collection('chats').doc(chatId).update({
        'unreadCount': 0,
      });

      // Mark all unread messages from other user as read
      final messages = await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .where('senderId', isNotEqualTo: currentUser.uid)
          .where('read', isEqualTo: false)
          .get();

      final batch = _firestore.batch();
      for (var doc in messages.docs) {
        batch.update(doc.reference, {'read': true});
      }
      await batch.commit();
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

      // Create message data
      final messageData = {
        'senderId': currentUser.uid,
        'senderName': currentUser.displayName ?? 'Anonyme',
        'content': content,
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
      };

      // Add message to subcollection
      final messageRef = await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .add(messageData);

      // Update chat document with latest message info
      await _firestore.collection('chats').doc(chatId).update({
        'lastMessage': content,
        'lastMessageTime': FieldValue.serverTimestamp(),
        'lastMessageSenderId': currentUser.uid,
        'unreadCount': FieldValue.increment(1),
        'otherUserId': otherUserId,
        'otherUserName': otherUserName,
      });

      // Update user's chat subcollection
      await _updateUserChatReference(chatId, currentUser.uid, otherUserId, otherUserName, content);
    } catch (e) {
      print('Erreur lors de l\'envoi du message: $e');
      rethrow;
    }
  }

  static Future<void> _updateUserChatReference(
      String chatId,
      String userId,
      String otherUserId,
      String otherUserName,
      String lastMessage
      ) async {
    try {
      // Update current user's chat reference
      await _firestore.collection('users').doc(userId)
          .collection('chats').doc(chatId).set({
        'otherUserId': otherUserId,
        'otherUserName': otherUserName,
        'lastMessage': lastMessage,
        'lastMessageTime': FieldValue.serverTimestamp(),
        'unreadCount': 0, // Current user sent the message, so unread count is 0
      }, SetOptions(merge: true));

      // Update other user's chat reference with unread count
      await _firestore.collection('users').doc(otherUserId)
          .collection('chats').doc(chatId).set({
        'otherUserId': userId,
        'otherUserName': FirebaseAuth.instance.currentUser?.displayName ?? 'Utilisateur',
        'lastMessage': lastMessage,
        'lastMessageTime': FieldValue.serverTimestamp(),
        'unreadCount': FieldValue.increment(1),
      }, SetOptions(merge: true));
    } catch (e) {
      print('Erreur lors de la mise à jour des références de chat: $e');
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

        // Create the chat document
        await _firestore.collection('chats').doc(chatId).set({
          'participants': [currentUser.uid, otherUserId],
          'lastMessage': 'Conversation démarrée',
          'lastMessageTime': FieldValue.serverTimestamp(),
          'lastMessageSenderId': 'system',
          'unreadCount': 0,
          'otherUserId': otherUserId,
          'otherUserName': otherUserName,
          'createdAt': FieldValue.serverTimestamp(),
        });

        // Add a system message to the messages subcollection
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

        // Create chat references in both users' subcollections
        await _createUserChatReferences(chatId, currentUser.uid, otherUserId, otherUserName);
      }
    } catch (e) {
      print('Erreur lors de la création du chat: $e');
      rethrow;
    }
  }

  static Future<void> _createUserChatReferences(
      String chatId,
      String userId1,
      String userId2,
      String userName2
      ) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return;

      // For user 1
      await _firestore.collection('users').doc(userId1)
          .collection('chats').doc(chatId).set({
        'otherUserId': userId2,
        'otherUserName': userName2,
        'lastMessage': 'Conversation démarrée',
        'lastMessageTime': FieldValue.serverTimestamp(),
        'unreadCount': 0,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // For user 2
      await _firestore.collection('users').doc(userId2)
          .collection('chats').doc(chatId).set({
        'otherUserId': userId1,
        'otherUserName': currentUser.displayName ?? 'Utilisateur',
        'lastMessage': 'Conversation démarrée',
        'lastMessageTime': FieldValue.serverTimestamp(),
        'unreadCount': 0,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Erreur lors de la création des références de chat: $e');
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

  // Get a specific chat document
  static Future<DocumentSnapshot> getChatDocument(String chatId) {
    return _firestore.collection('chats').doc(chatId).get();
  }

  // Delete a chat and all its messages
  static Future<void> deleteChat(String chatId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return;

      // Get chat data first to identify participants
      final chatDoc = await _firestore.collection('chats').doc(chatId).get();
      if (chatDoc.exists) {
        final participants = List<String>.from(chatDoc.data()!['participants'] ?? []);

        // Delete chat references from all participants
        for (var userId in participants) {
          await _firestore.collection('users').doc(userId)
              .collection('chats').doc(chatId).delete();
        }
      }

      // First delete all messages in the subcollection
      final messages = await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .get();

      final batch = _firestore.batch();
      for (var doc in messages.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      // Then delete the chat document
      await _firestore.collection('chats').doc(chatId).delete();
    } catch (e) {
      print('Erreur lors de la suppression du chat: $e');
      rethrow;
    }
  }
}
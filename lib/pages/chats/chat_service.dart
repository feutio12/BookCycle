import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChatService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static String generateChatId(String userId1, String userId2) {
    final ids = [userId1, userId2]..sort();
    return 'chat_${ids[0]}_${ids[1]}';
  }

  static Future<String> getOrCreateChat(String currentUserId, String otherUserId, String otherUserName) async {
    final chatId = generateChatId(currentUserId, otherUserId);

    // Vérifier si le chat existe déjà dans la collection utilisateur
    final userChatDoc = await _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('chats')
        .doc(chatId)
        .get();

    if (!userChatDoc.exists) {
      // Créer un nouveau chat
      await createChatIfNeeded(
        chatId: chatId,
        otherUserId: otherUserId,
        otherUserName: otherUserName,
      );
    }

    return chatId;
  }

  static Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists) {
        return userDoc.data();
      }
      return null;
    } catch (e) {
      print('Erreur lors de la récupération du profil: $e');
      return null;
    }
  }

  static Future<void> markMessagesAsRead(String chatId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return;

      // Mettre à jour le compteur de messages non lus dans le document chat
      await _firestore.collection('chats').doc(chatId).update({
        'unreadCount': 0,
      });

      // Marquer tous les messages non lus de l'autre utilisateur comme lus
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

      // Mettre à jour la référence de chat de l'utilisateur
      await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('chats')
          .doc(chatId)
          .update({'unreadCount': 0});

    } catch (e) {
      print('Erreur lors du marquage des messages comme lus: $e');
      rethrow;
    }
  }

  static Stream<QuerySnapshot> getChatsStream(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('chats')
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
      if (currentUser == null) throw Exception('Utilisateur non connecté');

      final messageData = {
        'senderId': currentUser.uid,
        'senderName': currentUser.displayName ?? 'Anonyme',
        'content': content,
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
      };

      // Ajouter le message
      await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .add(messageData);

      // Mettre à jour le document chat principal
      await _firestore.collection('chats').doc(chatId).update({
        'lastMessage': content,
        'lastMessageTime': FieldValue.serverTimestamp(),
        'lastMessageSenderId': currentUser.uid,
        'unreadCount': FieldValue.increment(1),
      });

      // Mettre à jour la référence de chat de l'expéditeur
      await _updateUserChatReference(
        userId: currentUser.uid,
        chatId: chatId,
        otherUserId: otherUserId,
        otherUserName: otherUserName,
        lastMessage: content,
        lastMessageSenderId: currentUser.uid,
        incrementUnread: false,
      );

      // Mettre à jour la référence de chat du destinataire
      await _updateUserChatReference(
        userId: otherUserId,
        chatId: chatId,
        otherUserId: currentUser.uid,
        otherUserName: currentUser.displayName ?? 'Utilisateur',
        lastMessage: content,
        lastMessageSenderId: currentUser.uid,
        incrementUnread: true,
      );

    } catch (e) {
      print('Erreur lors de l\'envoi du message: $e');
      rethrow;
    }
  }

  static Future<void> _updateUserChatReference({
    required String userId,
    required String chatId,
    required String otherUserId,
    required String otherUserName,
    required String lastMessage,
    required String lastMessageSenderId,
    required bool incrementUnread,
  }) async {
    try {
      final updateData = {
        'otherUserId': otherUserId,
        'otherUserName': otherUserName,
        'lastMessage': lastMessage,
        'lastMessageTime': FieldValue.serverTimestamp(),
        'lastMessageSenderId': lastMessageSenderId,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (incrementUnread) {
        updateData['unreadCount'] = FieldValue.increment(1);
      } else {
        updateData['unreadCount'] = 0;
      }

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('chats')
          .doc(chatId)
          .set(updateData, SetOptions(merge: true));
    } catch (e) {
      print('Erreur lors de la mise à jour des références de chat: $e');
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
        if (currentUser == null) throw Exception('Utilisateur non connecté');

        final currentUserName = currentUser.displayName ?? 'Utilisateur';

        // Structure de données pour le chat principal
        final chatData = {
          'participants': [currentUser.uid, otherUserId],
          'participantNames': {
            currentUser.uid: currentUserName,
            otherUserId: otherUserName,
          },
          'lastMessage': 'Conversation démarrée',
          'lastMessageTime': FieldValue.serverTimestamp(),
          'lastMessageSenderId': 'system',
          'unreadCount': 0,
          'createdAt': FieldValue.serverTimestamp(),
        };

        await _firestore.collection('chats').doc(chatId).set(chatData);

        // Message système
        final messageData = {
          'senderId': 'system',
          'senderName': 'Système',
          'content': 'Conversation démarrée',
          'timestamp': FieldValue.serverTimestamp(),
          'read': true,
        };

        await _firestore
            .collection('chats')
            .doc(chatId)
            .collection('messages')
            .add(messageData);

        // Références utilisateur
        final systemMessage = 'Conversation démarrée';

        // Pour l'utilisateur courant
        await _updateUserChatReference(
          userId: currentUser.uid,
          chatId: chatId,
          otherUserId: otherUserId,
          otherUserName: otherUserName,
          lastMessage: systemMessage,
          lastMessageSenderId: 'system',
          incrementUnread: false,
        );

        // Pour l'autre utilisateur
        await _updateUserChatReference(
          userId: otherUserId,
          chatId: chatId,
          otherUserId: currentUser.uid,
          otherUserName: currentUserName,
          lastMessage: systemMessage,
          lastMessageSenderId: 'system',
          incrementUnread: false,
        );
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
      rethrow;
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

  static Future<DocumentSnapshot> getChatDocument(String chatId) {
    return _firestore.collection('chats').doc(chatId).get();
  }

  static Future<void> deleteChat(String chatId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return;

      // Obtenir les participants du chat
      final chatDoc = await _firestore.collection('chats').doc(chatId).get();
      if (chatDoc.exists) {
        final participants = List<String>.from(chatDoc.data()!['participants'] ?? []);

        // Supprimer les références de chat de tous les participants
        for (var userId in participants) {
          await _firestore.collection('users').doc(userId)
              .collection('chats').doc(chatId).delete();
        }
      }

      // Supprimer tous les messages
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

      // Supprimer le document chat principal
      await _firestore.collection('chats').doc(chatId).delete();
    } catch (e) {
      print('Erreur lors de la suppression du chat: $e');
      rethrow;
    }
  }
}
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

    // Vérifier si le chat existe déjà
    final chatDoc = await _firestore.collection('chats').doc(chatId).get();

    if (!chatDoc.exists) {
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

      // Créer les données du message avec statut non lu
      final messageData = {
        'senderId': currentUser.uid,
        'senderName': currentUser.displayName ?? 'Anonyme',
        'content': content,
        'timestamp': FieldValue.serverTimestamp(),
        'read': false, // Message non lu par le destinataire
      };

      // Ajouter le message à la sous-collection
      await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .add(messageData);

      // Mettre à jour le document chat avec les infos du dernier message
      await _firestore.collection('chats').doc(chatId).update({
        'lastMessage': content,
        'lastMessageTime': FieldValue.serverTimestamp(),
        'lastMessageSenderId': currentUser.uid,
        'unreadCount': FieldValue.increment(1), // Incrémenter le compteur de non-lus
      });

      // Mettre à jour la sous-collection de chat de l'utilisateur courant
      await _firestore.collection('users').doc(currentUser.uid)
          .collection('chats').doc(chatId).set({
        'otherUserId': otherUserId,
        'otherUserName': otherUserName,
        'lastMessage': content,
        'lastMessageTime': FieldValue.serverTimestamp(),
        'lastMessageSenderId': currentUser.uid,
        'unreadCount': 0, // L'expéditeur a 0 message non lu
      }, SetOptions(merge: true));

      // Mettre à jour la sous-collection de chat du destinataire avec compteur de non-lus
      await _firestore.collection('users').doc(otherUserId)
          .collection('chats').doc(chatId).set({
        'otherUserId': currentUser.uid,
        'otherUserName': currentUser.displayName ?? 'Utilisateur',
        'lastMessage': content,
        'lastMessageTime': FieldValue.serverTimestamp(),
        'lastMessageSenderId': currentUser.uid,
        'unreadCount': FieldValue.increment(1), // Destinataire a +1 message non lu
      }, SetOptions(merge: true));

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
      // Mettre à jour la référence de chat de l'utilisateur courant
      await _firestore.collection('users').doc(userId)
          .collection('chats').doc(chatId).set({
        'otherUserId': otherUserId,
        'otherUserName': otherUserName,
        'lastMessage': lastMessage,
        'lastMessageTime': FieldValue.serverTimestamp(),
        'lastMessageSenderId': userId,
        'unreadCount': 0, // L'utilisateur courant a envoyé le message, donc compteur à 0
      }, SetOptions(merge: true));

      // Mettre à jour la référence de chat de l'autre utilisateur avec compteur de non lus
      await _firestore.collection('users').doc(otherUserId)
          .collection('chats').doc(chatId).set({
        'otherUserId': userId,
        'otherUserName': _auth.currentUser?.displayName ?? 'Utilisateur',
        'lastMessage': lastMessage,
        'lastMessageTime': FieldValue.serverTimestamp(),
        'lastMessageSenderId': userId,
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

        // Structure de données pour le chat
        final chatData = {
          'participants': [currentUser.uid, otherUserId],
          'lastMessage': 'Conversation démarrée',
          'lastMessageTime': FieldValue.serverTimestamp(),
          'lastMessageSenderId': 'system',
          'unreadCount': 0,
          'otherUserId': otherUserId,
          'otherUserName': otherUserName,
          'createdAt': FieldValue.serverTimestamp(),
        };

        // Créer le document chat
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
        final currentUserName = currentUser.displayName ?? 'Utilisateur';

        // Pour l'utilisateur courant
        await _firestore.collection('users').doc(currentUser.uid)
            .collection('chats').doc(chatId).set({
          'otherUserId': otherUserId,
          'otherUserName': otherUserName,
          'lastMessage': 'Conversation démarrée',
          'lastMessageTime': FieldValue.serverTimestamp(),
          'lastMessageSenderId': 'system',
          'unreadCount': 0,
          'createdAt': FieldValue.serverTimestamp(),
        });

        // Pour l'autre utilisateur
        await _firestore.collection('users').doc(otherUserId)
            .collection('chats').doc(chatId).set({
          'otherUserId': currentUser.uid,
          'otherUserName': currentUserName,
          'lastMessage': 'Conversation démarrée',
          'lastMessageTime': FieldValue.serverTimestamp(),
          'lastMessageSenderId': 'system',
          'unreadCount': 0,
          'createdAt': FieldValue.serverTimestamp(),
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

  // Obtenir un document chat spécifique
  static Future<DocumentSnapshot> getChatDocument(String chatId) {
    return _firestore.collection('chats').doc(chatId).get();
  }

  // Supprimer un chat et tous ses messages
  static Future<void> deleteChat(String chatId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return;

      // Obtenir d'abord les données du chat pour identifier les participants
      final chatDoc = await _firestore.collection('chats').doc(chatId).get();
      if (chatDoc.exists) {
        final participants = List<String>.from(chatDoc.data()!['participants'] ?? []);

        // Supprimer les références de chat de tous les participants
        for (var userId in participants) {
          await _firestore.collection('users').doc(userId)
              .collection('chats').doc(chatId).delete();
        }
      }

      // D'abord supprimer tous les messages de la sous-collection
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

      // Puis supprimer le document chat
      await _firestore.collection('chats').doc(chatId).delete();
    } catch (e) {
      print('Erreur lors de la suppression du chat: $e');
      rethrow;
    }
  }
}
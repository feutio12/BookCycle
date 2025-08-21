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
}
class ChatDiscussion {

  final String chatId;

  final List<String> participants;

  final String otherUserId;

  final String otherUserName;

  final String lastMessage;

  final DateTime lastMessageTime;

  final String lastMessageSenderId;

  final int unreadCount;



  ChatDiscussion({

    required this.chatId,

    required this.participants,

    required this.otherUserId,

    required this.otherUserName,

    required this.lastMessage,

    required this.lastMessageTime,

    required this.lastMessageSenderId,

    required this.unreadCount,

  });

}



class ChatMessage {

  final String id;

  final String senderId;

  final String senderName;

  final String content;

  final DateTime timestamp;

  final bool isRead;



  ChatMessage({

    required this.id,

    required this.senderId,

    required this.senderName,

    required this.content,

    required this.timestamp,

    required this.isRead,

  });

}
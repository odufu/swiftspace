class ChatMessage {
  final String id;
  final String senderId;
  final String text;
  final DateTime timestamp;
  final bool isRead;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.text,
    required this.timestamp,
    this.isRead = false,
  });
}

class ChatRoom {
  final String id;
  final String propertyId;
  final String propertyTitle;
  final String propertyImageUrl;
  final String agentName;
  final List<ChatMessage> messages;
  final String lastMessage;
  final DateTime lastMessageTime;

  ChatRoom({
    required this.id,
    required this.propertyId,
    required this.propertyTitle,
    required this.propertyImageUrl,
    required this.agentName,
    required this.messages,
    required this.lastMessage,
    required this.lastMessageTime,
  });
}

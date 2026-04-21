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

  ChatMessage copyWith({
    String? id,
    String? senderId,
    String? text,
    DateTime? timestamp,
    bool? isRead,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      text: text ?? this.text,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
    );
  }
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

  int get unreadCount => messages.where((m) => !m.isRead && m.senderId != 'user').length;

  ChatRoom copyWith({
    String? id,
    String? propertyId,
    String? propertyTitle,
    String? propertyImageUrl,
    String? agentName,
    List<ChatMessage>? messages,
    String? lastMessage,
    DateTime? lastMessageTime,
  }) {
    return ChatRoom(
      id: id ?? this.id,
      propertyId: propertyId ?? this.propertyId,
      propertyTitle: propertyTitle ?? this.propertyTitle,
      propertyImageUrl: propertyImageUrl ?? this.propertyImageUrl,
      agentName: agentName ?? this.agentName,
      messages: messages ?? this.messages,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
    );
  }
}

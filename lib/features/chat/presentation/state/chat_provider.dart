import 'package:flutter/material.dart';
import 'package:swiftspace/features/chat/domain/entities/chat.dart';

class ChatProvider with ChangeNotifier {
  final Map<String, ChatRoom> _rooms = {};

  List<ChatRoom> get rooms => _rooms.values.toList()
    ..sort((a, b) => b.lastMessageTime.compareTo(a.lastMessageTime));

  ChatRoom? getRoomByProperty(String propertyId) {
    try {
      return _rooms.values.firstWhere(
        (r) => r.propertyId == propertyId,
      );
    } catch (_) {
      return null;
    }
  }

  void sendMessage(String roomId, String text, String senderId) {
    if (!_rooms.containsKey(roomId)) return;

    final room = _rooms[roomId]!;
    final newMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      senderId: senderId,
      text: text,
      timestamp: DateTime.now(),
    );

    final updatedMessages = List<ChatMessage>.from(room.messages)..add(newMessage);
    
    _rooms[roomId] = ChatRoom(
      id: room.id,
      propertyId: room.propertyId,
      propertyTitle: room.propertyTitle,
      propertyImageUrl: room.propertyImageUrl,
      agentName: room.agentName,
      messages: updatedMessages,
      lastMessage: text,
      lastMessageTime: DateTime.now(),
    );

    notifyListeners();
    
    // Auto-reply mock logic
    if (senderId == 'user') {
      _mockAutoReply(roomId);
    }
  }

  void createRoom(String propertyId, String title, String imageUrl, String agentName) {
    // Check if room exists
    final existingRoom = _rooms.values.any((r) => r.propertyId == propertyId);
    if (!existingRoom) {
      final id = 'room_${DateTime.now().millisecondsSinceEpoch}';
      _rooms[id] = ChatRoom(
        id: id,
        propertyId: propertyId,
        propertyTitle: title,
        propertyImageUrl: imageUrl,
        agentName: agentName,
        messages: [],
        lastMessage: 'Tap to start conversation',
        lastMessageTime: DateTime.now(),
      );
      notifyListeners();
    }
  }

  void _mockAutoReply(String roomId) {
    Future.delayed(const Duration(seconds: 2), () {
      if (_rooms.containsKey(roomId)) {
        sendMessage(roomId, "Hello! Thanks for your interest. How can I help you with this property?", "agent");
      }
    });
  }
}

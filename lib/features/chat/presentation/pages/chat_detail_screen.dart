import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:swiftspace/features/chat/presentation/state/chat_provider.dart';
import 'package:swiftspace/features/chat/domain/entities/chat.dart';

class ChatDetailScreen extends StatefulWidget {
  final String roomId;

  const ChatDetailScreen({super.key, required this.roomId});

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chatProvider = Provider.of<ChatProvider>(context);
    ChatRoom? room;
    try {
      room = chatProvider.rooms.firstWhere((r) => r.id == widget.roomId);
    } catch (_) {
      room = null;
    }

    if (room == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Chat')),
        body: const Center(child: Text('Conversation not found')),
      );
    }

    // After the null check, we can safely use room! or re-assign to non-nullable
    final activeRoom = room;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              backgroundImage: NetworkImage(activeRoom.propertyImageUrl),
              radius: 18,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    activeRoom.agentName, 
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    activeRoom.propertyTitle, 
                    style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w500),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(LucideIcons.phone), onPressed: () {}),
          IconButton(icon: const Icon(LucideIcons.moreVertical), onPressed: () {}),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: activeRoom.messages.length,
              itemBuilder: (context, index) {
                final msg = activeRoom.messages[index];
                final isMe = msg.senderId == 'user';
                
                return Align(
                  alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                    decoration: BoxDecoration(
                      color: isMe ? theme.colorScheme.primary : (theme.brightness == Brightness.dark ? Colors.grey[800] : Colors.grey[200]),
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft: Radius.circular(isMe ? 16 : 0),
                        bottomRight: Radius.circular(isMe ? 0 : 16),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                      children: [
                        Text(
                          msg.text,
                          style: TextStyle(
                            color: isMe ? Colors.white : theme.colorScheme.onSurface,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${msg.timestamp.hour}:${msg.timestamp.minute.toString().padLeft(2, '0')}',
                          style: TextStyle(
                            color: isMe ? Colors.white70 : Colors.grey[600],
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          _buildInput(theme, chatProvider),
        ],
      ),
    );
  }

  Widget _buildInput(ThemeData theme, ChatProvider chatProvider) {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 8, 16, MediaQuery.of(context).padding.bottom + 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -5))
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: theme.brightness == Brightness.dark ? Colors.grey[900] : Colors.grey[100],
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: _controller,
                decoration: const InputDecoration(
                  hintText: 'Type a message...',
                  border: InputBorder.none,
                ),
                onSubmitted: (_) => _handleSend(chatProvider),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: Icon(LucideIcons.send, color: theme.colorScheme.primary),
            onPressed: () => _handleSend(chatProvider),
          ),
        ],
      ),
    );
  }

  void _handleSend(ChatProvider chatProvider) {
    if (_controller.text.trim().isEmpty) return;
    chatProvider.sendMessage(widget.roomId, _controller.text.trim(), 'user');
    _controller.clear();
    Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:swiftspace/features/chat/presentation/state/notification_provider.dart';
import 'package:swiftspace/features/chat/domain/entities/notification.dart';

class NotificationSheet {
  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Consumer<NotificationProvider>(
          builder: (context, provider, child) {
            final notes = provider.notifications;
            return Container(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Notifications',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextButton(
                          onPressed: provider.markAllAsRead,
                          child: const Text('Mark all as read'),
                        ),
                      ],
                    ),
                  ),
                  const Divider(),
                  if (notes.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Text('No new notifications'),
                    )
                  else
                    Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: notes.length,
                        itemBuilder: (context, index) {
                          final n = notes[index];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: _getNoteColor(
                                n.type,
                              ).withValues(alpha: 0.1),
                              child: Icon(
                                _getNoteIcon(n.type),
                                color: _getNoteColor(n.type),
                                size: 20,
                              ),
                            ),
                            title: Text(
                              n.title,
                              style: TextStyle(
                                fontWeight: n.isRead
                                    ? FontWeight.normal
                                    : FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              n.message,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: Text(
                              _formatTime(n.timestamp),
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey[600],
                              ),
                            ),
                            onTap: () => provider.markAsRead(n.id),
                          );
                        },
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  static IconData _getNoteIcon(NotificationType type) {
    switch (type) {
      case NotificationType.inspection:
        return LucideIcons.calendar;
      case NotificationType.offer:
        return LucideIcons.landmark;
      case NotificationType.chat:
        return LucideIcons.messageSquare;
      case NotificationType.match:
        return LucideIcons.home;
      case NotificationType.system:
        return LucideIcons.info;
      default:
        return LucideIcons.bell;
    }
  }

  static Color _getNoteColor(NotificationType type) {
    switch (type) {
      case NotificationType.inspection:
        return Colors.blue;
      case NotificationType.offer:
        return Colors.green;
      case NotificationType.chat:
        return Colors.orange;
      case NotificationType.match:
        return Colors.purple;
      case NotificationType.system:
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  static String _formatTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

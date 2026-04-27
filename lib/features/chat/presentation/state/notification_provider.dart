import 'package:flutter/material.dart';
import 'package:swiftspace/features/chat/domain/entities/notification.dart';

class NotificationProvider with ChangeNotifier {
  final List<NotificationModel> _notifications = [];

  List<NotificationModel> get notifications => List.unmodifiable(
        _notifications..sort((a, b) => b.timestamp.compareTo(a.timestamp)),
      );

  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  NotificationProvider() {
    _seedMockNotifications();
  }

  void addNotification(NotificationModel notification) {
    _notifications.add(notification);
    notifyListeners();
  }

  void markAsRead(String id) {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
      notifyListeners();
    }
  }

  void markAllAsRead() {
    for (int i = 0; i < _notifications.length; i++) {
      _notifications[i] = _notifications[i].copyWith(isRead: true);
    }
    notifyListeners();
  }

  void clearNotifications() {
    _notifications.clear();
    notifyListeners();
  }

  void _seedMockNotifications() {
    _notifications.addAll([
      NotificationModel(
        id: '1',
        title: 'New Lead: John Doe',
        message: 'John Doe requested an inspection for Luxury Villa in Abuja.',
        type: NotificationType.inspection,
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
        isRead: false,
      ),
      NotificationModel(
        id: '2',
        title: 'Offer Received',
        message: 'You have a new offer of ₦45,000,000 for Semi-Detached House.',
        type: NotificationType.offer,
        timestamp: DateTime.now().subtract(const Duration(minutes: 45)),
        isRead: false,
      ),
      NotificationModel(
        id: '3',
        title: 'Property Match',
        message: 'A new 3-bedroom apartment matching your filters was just listed.',
        type: NotificationType.match,
        timestamp: DateTime.now().subtract(const Duration(days: 1)),
        isRead: true,
      ),
    ]);
  }
  
  // Simulation method for live updates
  void triggerMockLiveNotification() {
    final newNote = NotificationModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: 'Instant Alert',
      message: 'Someone just viewed your property listing!',
      type: NotificationType.system,
      timestamp: DateTime.now(),
      isRead: false,
    );
    addNotification(newNote);
  }
}

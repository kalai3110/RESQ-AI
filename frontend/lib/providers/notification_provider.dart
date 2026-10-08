import 'package:flutter/foundation.dart';
import '../models/notification_item.dart';
import '../services/api_service.dart';
import '../constants/api_constants.dart';

class NotificationProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<NotificationItem> _notifications = [];
  int _unreadCount = 0;
  bool _isLoading = false;

  List<NotificationItem> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;

  Future<void> fetchNotifications({int? userId}) async {
    _isLoading = true;
    notifyListeners();

    String url = ApiConstants.notifications;
    if (userId != null) {
      url += '?user_id=$userId';
    }

    final result = await _apiService.get(url);
    _isLoading = false;

    if (result['success'] == true && result['notifications'] is List) {
      _notifications = (result['notifications'] as List).map((e) => NotificationItem.fromJson(e)).toList();
      _unreadCount = result['unread_count'] is int ? result['unread_count'] : _notifications.where((n) => !n.isRead).length;
    }
    notifyListeners();
  }

  Future<void> markRead(int notifId) async {
    final result = await _apiService.patch(ApiConstants.markNotificationRead(notifId), {});
    if (result['success'] == true) {
      final index = _notifications.indexWhere((n) => n.id == notifId);
      if (index != -1) {
        _notifications[index] = NotificationItem(
          id: _notifications[index].id,
          userId: _notifications[index].userId,
          title: _notifications[index].title,
          message: _notifications[index].message,
          notificationType: _notifications[index].notificationType,
          reportId: _notifications[index].reportId,
          isRead: true,
          createdAt: _notifications[index].createdAt,
        );
        _unreadCount = _notifications.where((n) => !n.isRead).length;
        notifyListeners();
      }
    }
  }

  Future<void> markAllRead({int? userId}) async {
    String url = ApiConstants.markAllNotificationsRead;
    if (userId != null) {
      url += '?user_id=$userId';
    }
    final result = await _apiService.patch(url, {});
    if (result['success'] == true) {
      _notifications = _notifications.map((n) => NotificationItem(
        id: n.id,
        userId: n.userId,
        title: n.title,
        message: n.message,
        notificationType: n.notificationType,
        reportId: n.reportId,
        isRead: true,
        createdAt: n.createdAt,
      )).toList();
      _unreadCount = 0;
      notifyListeners();
    }
  }
}

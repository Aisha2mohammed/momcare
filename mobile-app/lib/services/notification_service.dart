import 'package:flutter/foundation.dart';
import 'api_service.dart';

class NotificationService {
  static const int _limit = 50;

  /// Reactive unread count listenable across the whole app (e.g., top navbar badge)
  static final ValueNotifier<int> unreadCount = ValueNotifier<int>(0);

  // ── Fetch unread count from backend ──────────────────────────────────
  static Future<int> fetchUnreadCount() async {
    try {
      final response = await ApiService.get(ApiEndpoints.unreadNotificationCount);
      final data = response['data'];
      int count = 0;
      if (data is Map && data.containsKey('count')) {
        count = int.tryParse(data['count'].toString()) ?? 0;
      }
      unreadCount.value = count;
      return count;
    } catch (e) {
      debugPrint('[NotificationService] Failed to fetch unread count: $e');
      return unreadCount.value;
    }
  }

  // ── Increment unread count (e.g. on new live push / websocket message) ─
  static void incrementUnread() {
    unreadCount.value = unreadCount.value + 1;
  }

  // ── Decrement unread count (e.g. when one notification is viewed) ─────
  static void decrementUnread() {
    if (unreadCount.value > 0) {
      unreadCount.value = unreadCount.value - 1;
    }
  }

  // ── Own inbox (broadcasts + role-group + targeted to me) ─────────────
  static Future<List<dynamic>> getMyNotifications({
    int page = 1,
    int limit = _limit,
  }) async {
    final response = await ApiService.get(
      ApiEndpoints.myNotifications(page: page, limit: limit),
    );
    return response['data'] as List<dynamic>? ?? [];
  }

  // ── Mark one as read (idempotent upsert server-side) ─────────────────
  static Future<Map<String, dynamic>> markRead(String notificationId) async {
    try {
      final response = await ApiService.put(ApiEndpoints.notificationRead(notificationId));
      decrementUnread();
      return response['data'] as Map<String, dynamic>? ?? {};
    } catch (_) {
      decrementUnread();
      rethrow;
    }
  }

  // ── Mark all notifications as read ───────────────────────────────────
  static Future<void> markAllRead() async {
    try {
      await ApiService.put(ApiEndpoints.markAllNotificationsRead);
      unreadCount.value = 0;
    } catch (_) {
      unreadCount.value = 0;
      rethrow;
    }
  }
}
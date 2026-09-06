import 'api_service.dart';

class NotificationService {
  static const int _limit = 50;

  // ── Own inbox (broadcasts + role-group + targeted to me) ─────────────
  static Future<List<dynamic>> getMyNotifications({
    int page = 1,
    int limit = _limit,
  }) async {
    final response = await ApiService.get(
      '/notifications/me?page=$page&limit=$limit',
    );
    return response['data'] as List<dynamic>? ?? [];
  }

  // ── Mark one as read (idempotent upsert server-side) ─────────────────
  static Future<Map<String, dynamic>> markRead(String notificationId) async {
    final response = await ApiService.put('/notifications/$notificationId/read');
    return response['data'] as Map<String, dynamic>? ?? {};
  }
}
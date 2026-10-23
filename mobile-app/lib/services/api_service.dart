import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Centralized API endpoint registry and URL builder for the entire application.
class ApiEndpoints {
  // Base server connection
  static const String serverHost = 'http://192.168.1.6:5000';
  static const String baseUrl = '$serverHost/api/v1';

  // ── Media & Upload URL Resolver ───────────────────────────────────────────
  static String resolveUrl(String? url) {
    if (url == null || url.trim().isEmpty) return '';
    final trimmed = url.trim();
    if (trimmed.startsWith('assets/')) return trimmed;
    String resolved = trimmed;
    if (resolved.contains('localhost')) {
      resolved = resolved.replaceAll('localhost', '192.168.1.6');
    }
    if (resolved.startsWith('http://') || resolved.startsWith('https://')) {
      return resolved;
    }
    return resolved.startsWith('/') ? '$serverHost$resolved' : '$serverHost/$resolved';
  }

  // ── Auth Endpoints ────────────────────────────────────────────────────────
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String otpSend = '/auth/otp/send';
  static const String otpVerify = '/auth/otp/verify';
  static const String forgotPassword = '/auth/forgot-password';
  static const String resetPassword = '/auth/reset-password';

  // ── Mother Endpoints ──────────────────────────────────────────────────────
  static String motherProfile(String motherId) => '/mothers/$motherId/profile';
  static String motherGestationalWeek(String motherId) => '/mothers/$motherId/gestational-week';
  static String motherHealthLogs(String motherId) => '/mothers/$motherId/health-logs';
  static String motherEmergencyContacts(String motherId) => '/mothers/$motherId/emergency-contacts';
  static String motherEmergencyAlert(String motherId) => '/mothers/$motherId/emergency-alert';

  // ── Content & Wellness Endpoints ──────────────────────────────────────────
  static String fetalByWeek(int week, String lang) => '/fetal/$week?lang=$lang';

  static String nutritionTips({
    required int trimester,
    int? month,
    int? week,
    String? type,
    required String lang,
    int limit = 100,
  }) {
    final monthParam = month != null ? '&month=$month' : '';
    final weekParam = week != null ? '&week=$week' : '';
    final typeParam = type != null && type.isNotEmpty ? '&type=$type' : '';
    return '/nutrition/tips?trimester=$trimester$monthParam$weekParam$typeParam&lang=$lang&limit=$limit';
  }

  static String nutritionWeeks({
    required int trimester,
    int? month,
    int? week,
    required String lang,
    int limit = 10,
  }) {
    final monthParam = month != null ? '&month=$month' : '';
    final weekParam = week != null ? '&week=$week' : '';
    return '/nutrition/weeks?trimester=$trimester$monthParam$weekParam&lang=$lang&limit=$limit';
  }

  static String exerciseTips({
    required int trimester,
    int? month,
    int? week,
    String? type,
    required String lang,
    int limit = 100,
  }) {
    final monthParam = month != null ? '&month=$month' : '';
    final weekParam = week != null ? '&week=$week' : '';
    final typeParam = type != null && type.isNotEmpty ? '&type=$type' : '';
    return '/exercise/tips?trimester=$trimester$monthParam$weekParam$typeParam&lang=$lang&limit=$limit';
  }

  static String exerciseWeeks({
    required int trimester,
    int? month,
    int? week,
    required String lang,
    int limit = 10,
  }) {
    final monthParam = month != null ? '&month=$month' : '';
    final weekParam = week != null ? '&week=$week' : '';
    return '/exercise/weeks?trimester=$trimester$monthParam$weekParam&lang=$lang&limit=$limit';
  }

  static String sleepTips({
    required int trimester,
    int? month,
    int? week,
    String? type,
    required String lang,
    int limit = 100,
  }) {
    final monthParam = month != null ? '&month=$month' : '';
    final weekParam = week != null ? '&week=$week' : '';
    final typeParam = type != null && type.isNotEmpty ? '&type=$type' : '';
    return '/sleep/tips?trimester=$trimester$monthParam$weekParam$typeParam&lang=$lang&limit=$limit';
  }

  static String sleepWeeks({
    required int trimester,
    int? month,
    int? week,
    required String lang,
    int limit = 10,
  }) {
    final monthParam = month != null ? '&month=$month' : '';
    final weekParam = week != null ? '&week=$week' : '';
    return '/sleep/weeks?trimester=$trimester$monthParam$weekParam&lang=$lang&limit=$limit';
  }

  static String music({String? category, required String lang, int limit = 100}) {
    final query = category != null && category.isNotEmpty
        ? '?category=${Uri.encodeComponent(category)}&lang=$lang&limit=$limit'
        : '?lang=$lang&limit=$limit';
    return '/music$query';
  }

  static String healthTips({required String lang, int limit = 100}) =>
      '/health-tips?lang=$lang&limit=$limit';

  // ── Doctor & Appointment Endpoints ────────────────────────────────────────
  static const String healthProviders = '/doctors/health-providers';
  static String providerDoctors(String providerId) => '/doctors/health-providers/$providerId/doctors';
  static String doctorPublicProfile(String doctorId) => '/doctors/public/$doctorId';
  static String doctorAvailabilitySlots(String doctorId) => '/doctors/$doctorId/availability-slots';
  static const String appointments = '/appointments';
  static String appointmentById(String id) => '/appointments/$id';

  // ── Community Endpoints ───────────────────────────────────────────────────
  static const String communityGroups = '/community/groups';
  static const String communityPosts = '/community/posts';
  static const String communityRules = '/community/rules';
  static String communityFeed({int page = 1, int limit = 50, String? groupId}) {
    final groupParam = (groupId != null && groupId.isNotEmpty && groupId != 'all') ? '&groupId=$groupId' : '';
    return '/community/posts?page=$page&limit=$limit$groupParam';
  }
  static String groupPosts(String groupId, {int page = 1, int limit = 50}) =>
      '/community/groups/$groupId/posts?page=$page&limit=$limit';
  static String postComments(String postId, {int page = 1, int limit = 50}) =>
      '/community/posts/$postId/comments?page=$page&limit=$limit';
  static String postCommentsCreate(String postId) => '/community/posts/$postId/comments';
  static String postLike(String postId) => '/community/posts/$postId/like';
  static String postFlag(String postId) => '/community/posts/$postId/flag';
  static String postUpdate(String postId) => '/community/posts/$postId';
  static String postDelete(String postId) => '/community/posts/$postId';

  // ── Direct Messaging (Mother-to-Mother) ──────────────────────────────────
  static const String directMessageConversations = '/community/direct-messages/conversations';
  static String directMessages(String otherUserId, {int page = 1, int limit = 50}) =>
      '/community/direct-messages/$otherUserId?page=$page&limit=$limit';
  static String sendDirectMessage(String otherUserId) =>
      '/community/direct-messages/$otherUserId';
  static String directMessageUpdate(String messageId) =>
      '/community/direct-messages/messages/$messageId';
  static String directMessageDelete(String messageId) =>
      '/community/direct-messages/messages/$messageId';

  // ── Notification Endpoints ────────────────────────────────────────────────
  static const String notificationDevices = '/notifications/devices';
  static String myNotifications({int page = 1, int limit = 50}) =>
      '/notifications/me?page=$page&limit=$limit';
  static const String unreadNotificationCount = '/notifications/unread-count';
  static const String markAllNotificationsRead = '/notifications/read-all';
  static String notificationRead(String id) => '/notifications/$id/read';

  // ── Chat & Chatbot Endpoints ──────────────────────────────────────────────
  static String chatMessages(String motherId, String doctorId, {int page = 1, int limit = 50}) =>
      '/chat/$motherId/$doctorId/messages?page=$page&limit=$limit';
  static String chatSendMessage(String motherId, String doctorId) =>
      '/chat/$motherId/$doctorId/messages';
  static const String chatbotAsk = '/chatbot/ask';
}

class ApiService {
  static String get baseUrl => ApiEndpoints.baseUrl;
  static String get serverHost => ApiEndpoints.serverHost;
  static String resolveUrl(String? url) => ApiEndpoints.resolveUrl(url);

  static const String _tokenKey = 'jwt_token';
  static const String _userIdKey = 'user_id';
  static const String _userRoleKey = 'user_role';

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  static Future<void> saveUserId(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userIdKey, userId);
  }

  static Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userIdKey);
  }

  static Future<void> saveUserRole(String role) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userRoleKey, role);
  }

  static Future<String?> getUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    final role = prefs.getString(_userRoleKey);
    if (role != null && role.isNotEmpty) return role;

    final token = await getToken();
    if (token != null) {
      try {
        final parts = token.split('.');
        if (parts.length == 3) {
          final normalized = base64Url.normalize(parts[1]);
          final payload = utf8.decode(base64Url.decode(normalized));
          final map = jsonDecode(payload);
          final r = map['role']?.toString();
          if (r != null && r.isNotEmpty) {
            await prefs.setString(_userRoleKey, r);
            return r;
          }
        }
      } catch (_) {}
    }
    return null;
  }

  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userIdKey);
    await prefs.remove(_userRoleKey);
  }

  static Future<Map<String, String>> _headers() async {
    final token = await getToken();
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  static Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final uri = Uri.parse('$baseUrl$path');
    final response = await http.post(
      uri,
      headers: await _headers(),
      body: body != null ? jsonEncode(body) : null,
    );
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> get(String path) async {
    final uri = Uri.parse('$baseUrl$path');
    final response = await http.get(uri, headers: await _headers());
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> put(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final uri = Uri.parse('$baseUrl$path');
    final response = await http.put(
      uri,
      headers: await _headers(),
      body: body != null ? jsonEncode(body) : null,
    );
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> delete(String path) async {
    final uri = Uri.parse('$baseUrl$path');
    final response = await http.delete(uri, headers: await _headers());
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> uploadMultipart({
    required String path,
    required File file,
    required String fieldName,
    Map<String, String>? fields,
  }) async {
    final uri = Uri.parse('$baseUrl$path');
    final request = http.MultipartRequest('POST', uri);
    final token = await getToken();
    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    request.headers['Accept'] = 'application/json';
    if (fields != null) {
      request.fields.addAll(fields);
    }

    final filename = file.path.split(Platform.pathSeparator).last;
    final ext = filename.contains('.') ? filename.split('.').last.toLowerCase() : 'jpg';
    final mimeSub = (ext == 'png')
        ? 'png'
        : (ext == 'webp')
            ? 'webp'
            : (ext == 'gif')
                ? 'gif'
                : 'jpeg';

    request.files.add(
      await http.MultipartFile.fromPath(
        fieldName,
        file.path,
        contentType: MediaType('image', mimeSub),
      ),
    );
    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> _handleResponse(
    http.Response response,
  ) async {
    final Map<String, dynamic> json;
    try {
      json = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw ApiException('Invalid server response', response.statusCode);
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return json;
    }

    // Backend error format: { error: { message, code } }
    final error = json['error'];
    String message;
    if (error is Map<String, dynamic>) {
      message = error['message'] as String? ?? 'Something went wrong';
    } else {
      message = json['message'] as String? ?? 'Something went wrong';
    }
    throw ApiException(message, response.statusCode);
  }
}

class ApiException implements Exception {
  final String message;
  final int statusCode;

  ApiException(this.message, this.statusCode);

  @override
  String toString() => message;
}

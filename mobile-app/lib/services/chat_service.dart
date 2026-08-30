import 'api_service.dart';

class ChatService {
  static Future<String> _motherId() async {
    final id = await ApiService.getUserId();
    if (id == null || id.isEmpty) {
      throw ApiException('Not authenticated. Please log in again.', 401);
    }
    return id;
  }

  static Future<List<dynamic>> getMessages(
    String doctorId, {
    int page = 1,
    int limit = 50,
  }) async {
    final motherId = await _motherId();
    final response = await ApiService.get(
      '/chat/$motherId/$doctorId/messages?page=$page&limit=$limit',
    );
    return response['data'] as List<dynamic>;
  }

  static Future<Map<String, dynamic>> sendMessage(
    String doctorId,
    String messageText,
  ) async {
    final motherId = await _motherId();
    final response = await ApiService.post(
      '/chat/$motherId/$doctorId/messages',
      body: {'messageText': messageText},
    );
    return response['data'] as Map<String, dynamic>;
  }
}
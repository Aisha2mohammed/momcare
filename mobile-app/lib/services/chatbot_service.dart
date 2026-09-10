import 'api_service.dart';

class ChatbotService {
  // ── Ask the pregnancy assistant (MaternaAI) ─────────────────────────
  static Future<String> ask(String message) async {
    final response = await ApiService.post(
      '/chatbot/ask',
      body: {'message': message},
    );
    return (response['data'] as Map<String, dynamic>?)?['response'] as String? ??
        '';
  }
}
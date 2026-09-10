import 'api_service.dart';
import 'mother_service.dart';

class ContentService {
  static const int _limit = 100;

  // Language preference is per-account (am/or/en/so) from the mother's profile.
  static Future<String> _language() async {
    try {
      final profile = await MotherService.getProfile();
      final user = profile['user'];
      final lang = (user is Map<String, dynamic> ? user['language'] : null)
          as String?;
      if (lang != null &&
          (lang == 'am' || lang == 'or' || lang == 'en' || lang == 'so')) {
        return lang;
      }
    } catch (_) {
      // Fall back to Amharic (the backend default) if profile is unavailable.
    }
    return 'am';
  }

  static Future<String> getLanguage() => _language();

  // ── Fetal tracker ─────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> getFetalByWeek(int week) async {
    final lang = await _language();
    final w = week < 1 ? 1 : (week > 42 ? 42 : week);
    final response = await ApiService.get('/fetal/$w?lang=$lang');
    return response['data'] as Map<String, dynamic>;
  }

  // ── Mothers' current trimester ────────────────────────────────────────
  static Future<int> currentTrimester() async {
    try {
      final progress = await MotherService.getGestationalWeek();
      final week = (progress['currentWeek'] as num?)?.toInt() ?? 12;
      return _trimesterForWeek(week);
    } catch (_) {
      return 1;
    }
  }

  static int _trimesterForWeek(int week) {
    if (week <= 13) return 1;
    if (week <= 27) return 2;
    return 3;
  }

  // ── Nutrition ─────────────────────────────────────────────────────────
  static Future<List<dynamic>> getNutrition(int trimester) async {
    final lang = await _language();
    final response = await ApiService.get(
      '/nutrition?trimester=$trimester&lang=$lang&limit=$_limit',
    );
    return response['data'] as List<dynamic>;
  }

  // ── Exercises ─────────────────────────────────────────────────────────
  static Future<List<dynamic>> getExercises(int trimester) async {
    final lang = await _language();
    final response = await ApiService.get(
      '/exercises?trimester=$trimester&lang=$lang&limit=$_limit',
    );
    return response['data'] as List<dynamic>;
  }

  // ── Sleep tips ────────────────────────────────────────────────────────
  static Future<List<dynamic>> getSleepTips(int trimester) async {
    final lang = await _language();
    final response = await ApiService.get(
      '/sleep-tips?trimester=$trimester&lang=$lang&limit=$_limit',
    );
    return response['data'] as List<dynamic>;
  }

  // ── Music ─────────────────────────────────────────────────────────────
  static Future<List<dynamic>> getMusic({String? category}) async {
    final lang = await _language();
    final query = category != null && category.isNotEmpty
        ? '?category=${Uri.encodeComponent(category)}&lang=$lang&limit=$_limit'
        : '?lang=$lang&limit=$_limit';
    final response = await ApiService.get('/music$query');
    return response['data'] as List<dynamic>;
  }

  // ── Health tips ───────────────────────────────────────────────────────
  static Future<List<dynamic>> getHealthTips() async {
    final lang = await _language();
    final response = await ApiService.get(
      '/health-tips?lang=$lang&limit=$_limit',
    );
    return response['data'] as List<dynamic>;
  }
}
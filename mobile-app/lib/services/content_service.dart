import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';
import 'mother_service.dart';

class ContentService {
  static const int _limit = 100;

  // Language preference priority:
  // 1. Explicit override passed to the method
  // 2. Currently selected language in SharedPreferences (set by language toggle)
  // 3. User account profile setting
  // 4. Default to 'en'
  static Future<String> _language([String? overrideLang]) async {
    if (overrideLang != null && overrideLang.trim().isNotEmpty) {
      final l = overrideLang.trim();
      return l == 'or' ? 'om' : l;
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      final code = prefs.getString('language_code');
      if (code != null && code.trim().isNotEmpty) {
        final c = code.trim();
        return c == 'or' ? 'om' : c;
      }
    } catch (_) {}
    try {
      final profile = await MotherService.getProfile();
      final user = profile['user'];
      final lang = (user is Map<String, dynamic> ? user['language'] : null)
          as String?;
      if (lang != null &&
          (lang == 'am' || lang == 'or' || lang == 'om' || lang == 'en' || lang == 'so')) {
        return lang == 'or' ? 'om' : lang;
      }
    } catch (_) {}
    return 'en';
  }

  static Future<String> getLanguage([String? overrideLang]) => _language(overrideLang);

  // ── Fetal tracker ─────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> getFetalByWeek(int week, {String? lang}) async {
    final l = await _language(lang);
    final w = week < 1 ? 1 : (week > 42 ? 42 : week);
    final response = await ApiService.get(ApiEndpoints.fetalByWeek(w, l));
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
  static Future<List<dynamic>> getNutrition(int trimester, {int? week, String? type, String? lang}) async {
    final l = await _language(lang);
    final endpoint = ApiEndpoints.nutritionTips(
      trimester: trimester,
      week: week,
      type: type,
      lang: l,
      limit: _limit,
    );
    final response = await ApiService.get(endpoint);
    return response['data'] as List<dynamic>;
  }

  // ── Exercises ─────────────────────────────────────────────────────────
  static Future<List<dynamic>> getExercises(int trimester, {int? week, String? type, String? lang}) async {
    final l = await _language(lang);
    final endpoint = ApiEndpoints.exerciseTips(
      trimester: trimester,
      week: week,
      type: type,
      lang: l,
      limit: _limit,
    );
    final response = await ApiService.get(endpoint);
    return response['data'] as List<dynamic>;
  }

  // ── Sleep tips ────────────────────────────────────────────────────────
  static Future<List<dynamic>> getSleepTips(int trimester, {int? week, String? type, String? lang}) async {
    final l = await _language(lang);
    final endpoint = ApiEndpoints.sleepTips(
      trimester: trimester,
      week: week,
      type: type,
      lang: l,
      limit: _limit,
    );
    final response = await ApiService.get(endpoint);
    return response['data'] as List<dynamic>;
  }

  // ── Music ─────────────────────────────────────────────────────────────
  static Future<List<dynamic>> getMusic({String? category, String? lang}) async {
    final l = await _language(lang);
    final response = await ApiService.get(
      ApiEndpoints.music(category: category, lang: l, limit: _limit),
    );
    return response['data'] as List<dynamic>;
  }

  // ── Health tips ───────────────────────────────────────────────────────
  static Future<List<dynamic>> getHealthTips({String? lang}) async {
    final l = await _language(lang);
    final response = await ApiService.get(
      ApiEndpoints.healthTips(lang: l, limit: _limit),
    );
    return response['data'] as List<dynamic>;
  }

  // ── Weekly Nutrition Info (Hydration + Why Important) ────────────────
  static Future<Map<String, dynamic>?> getNutritionWeek(int trimester, {int? week, String? lang}) async {
    try {
      final l = await _language(lang);
      final endpoint = ApiEndpoints.nutritionWeeks(
        trimester: trimester,
        week: week,
        lang: l,
        limit: 1,
      );
      final response = await ApiService.get(endpoint);
      final list = response['data'] as List<dynamic>?;
      if (list != null && list.isNotEmpty) {
        return Map<String, dynamic>.from(list.first as Map);
      }
    } catch (_) {}
    return null;
  }

  // ── Weekly Exercise Info (Exercise Tips + Why Important) ─────────────
  static Future<Map<String, dynamic>?> getExerciseWeek(int trimester, {int? week, String? lang}) async {
    try {
      final l = await _language(lang);
      final endpoint = ApiEndpoints.exerciseWeeks(
        trimester: trimester,
        week: week,
        lang: l,
        limit: 1,
      );
      final response = await ApiService.get(endpoint);
      final list = response['data'] as List<dynamic>?;
      if (list != null && list.isNotEmpty) {
        return Map<String, dynamic>.from(list.first as Map);
      }
    } catch (_) {}
    return null;
  }

  // ── Weekly Sleep Info (Sleeping Tips + Why Important) ────────────────
  static Future<Map<String, dynamic>?> getSleepWeek(int trimester, {int? week, String? lang}) async {
    try {
      final l = await _language(lang);
      final endpoint = ApiEndpoints.sleepWeeks(
        trimester: trimester,
        week: week,
        lang: l,
        limit: 1,
      );
      final response = await ApiService.get(endpoint);
      final list = response['data'] as List<dynamic>?;
      if (list != null && list.isNotEmpty) {
        return Map<String, dynamic>.from(list.first as Map);
      }
    } catch (_) {}
    return null;
  }
}
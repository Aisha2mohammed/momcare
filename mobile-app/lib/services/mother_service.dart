import 'api_service.dart';

class MotherService {
  static Future<String> _motherId() async {
    final id = await ApiService.getUserId();
    if (id == null || id.isEmpty) {
      throw ApiException('Not authenticated. Please log in again.', 401);
    }
    return id;
  }

  static Future<Map<String, dynamic>> getProfile() async {
    final id = await _motherId();
    final response = await ApiService.get('/mothers/$id/profile');
    return response['data'] as Map<String, dynamic>;
  }

  static Future<void> updateProfile({
    String? name,
    String? language,
    String? lmpDate,
    String? city,
    String? profilePhoto,
  }) async {
    final id = await _motherId();
    final body = <String, dynamic>{};
    if (name != null && name.isNotEmpty) body['name'] = name;
    if (language != null && language.isNotEmpty) body['language'] = language;
    if (lmpDate != null && lmpDate.isNotEmpty) body['lmpDate'] = lmpDate;
    if (city != null && city.isNotEmpty) body['city'] = city;
    if (profilePhoto != null && profilePhoto.isNotEmpty) {
      body['profilePhoto'] = profilePhoto;
    }
    await ApiService.put('/mothers/$id/profile', body: body);
  }

  static Future<Map<String, dynamic>> getGestationalWeek() async {
    final id = await _motherId();
    final response = await ApiService.get('/mothers/$id/gestational-week');
    final data = response['data'] as Map<String, dynamic>;
    // Normalize numeric/date fields for easy display
    return {
      'currentWeek': (data['currentWeek'] ?? data['current_week']) as int? ?? 0,
      'currentTrimester':
          (data['currentTrimester'] ?? data['current_trimester']) as int? ?? 1,
      'daysRemaining': (data['daysRemaining'] ?? data['days_remaining']) as int? ?? 0,
      'weeksRemaining':
          (data['weeksRemaining'] ?? data['weeks_remaining']) as int? ?? 0,
      'percentageComplete':
          ((data['percentageComplete'] ?? data['percentage_complete']) as num?)?.toDouble() ?? 0.0,
      'dueDate': data['dueDate'] ?? data['due_date'],
      'lmpDate': data['lmpDate'] ?? data['lmp_date'],
      'isOverdue': data['isOverdue'] ?? false,
    };
  }

  static Future<List<dynamic>> getHealthLogs() async {
    final id = await _motherId();
    final response = await ApiService.get('/mothers/$id/health-logs');
    return response['data'] as List<dynamic>;
  }

  static Future<Map<String, dynamic>> createHealthLog({
    double? weightKg,
    String? mood,
    List<dynamic>? symptoms,
    int? symptomSeverity,
  }) async {
    final id = await _motherId();
    final body = <String, dynamic>{};
    if (weightKg != null) body['weightKg'] = weightKg;
    if (mood != null && mood.isNotEmpty) body['mood'] = mood;
    if (symptoms != null && symptoms.isNotEmpty) body['symptomsJson'] = symptoms;
    if (symptomSeverity != null) body['symptomSeverity'] = symptomSeverity;
    final response = await ApiService.post('/mothers/$id/health-logs', body: body);
    return response['data'] as Map<String, dynamic>;
  }

  static Future<List<dynamic>> getEmergencyContacts() async {
    final id = await _motherId();
    final response = await ApiService.get('/mothers/$id/emergency-contacts');
    return response['data'] as List<dynamic>;
  }

  static Future<Map<String, dynamic>> createEmergencyContact({
    required String contactName,
    required String phone,
    String? relationship,
  }) async {
    final id = await _motherId();
    final body = <String, dynamic>{
      'contactName': contactName,
      'phone': phone,
    };
    if (relationship != null && relationship.isNotEmpty) {
      body['relationship'] = relationship;
    }
    final response = await ApiService.post(
      '/mothers/$id/emergency-contacts',
      body: body,
    );
    return response['data'] as Map<String, dynamic>;
  }
}
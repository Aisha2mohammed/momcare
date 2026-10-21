import 'dart:io';
import 'package:flutter/foundation.dart';
import 'api_service.dart';

class MotherService {
  static final ValueNotifier<String?> profilePhoto = ValueNotifier<String?>(null);
  static final ValueNotifier<String?> motherName = ValueNotifier<String?>(null);

  static Future<void> loadInitialProfile() async {
    try {
      await getProfile();
    } catch (_) {}
  }

  static Future<String> _motherId() async {
    final id = await ApiService.getUserId();
    if (id == null || id.isEmpty) {
      throw ApiException('Not authenticated. Please log in again.', 401);
    }
    return id;
  }

  static Future<Map<String, dynamic>> getProfile() async {
    final id = await _motherId();
    final response = await ApiService.get(ApiEndpoints.motherProfile(id));
    final data = response['data'] as Map<String, dynamic>;
    final user = data['user'] as Map<String, dynamic>? ?? {};
    final profile = data['profile'] as Map<String, dynamic>?;
    final photo = (profile?['profile_photo'] as String?) ?? (user['profile_photo'] as String?);
    final name = user['name'] as String?;
    if (photo != null && photo.isNotEmpty) {
      profilePhoto.value = photo;
    }
    if (name != null && name.isNotEmpty) {
      motherName.value = name;
    }
    return data;
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
    if (name != null && name.isNotEmpty) {
      body['name'] = name;
      motherName.value = name;
    }
    if (language != null && language.isNotEmpty) body['language'] = language;
    if (lmpDate != null && lmpDate.isNotEmpty) body['lmpDate'] = lmpDate;
    if (city != null && city.isNotEmpty) body['city'] = city;
    if (profilePhoto != null && profilePhoto.isNotEmpty) {
      body['profilePhoto'] = profilePhoto;
      MotherService.profilePhoto.value = profilePhoto;
    }
    await ApiService.put(ApiEndpoints.motherProfile(id), body: body);
  }

  static Future<Map<String, dynamic>> getGestationalWeek() async {
    final id = await _motherId();
    final response = await ApiService.get(ApiEndpoints.motherGestationalWeek(id));
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
    final response = await ApiService.get(ApiEndpoints.motherHealthLogs(id));
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
    final response = await ApiService.post(ApiEndpoints.motherHealthLogs(id), body: body);
    return response['data'] as Map<String, dynamic>;
  }

  static Future<List<dynamic>> getEmergencyContacts() async {
    final id = await _motherId();
    final response = await ApiService.get(ApiEndpoints.motherEmergencyContacts(id));
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
      ApiEndpoints.motherEmergencyContacts(id),
      body: body,
    );
    return response['data'] as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> sendEmergencyAlert(
    double latitude,
    double longitude,
  ) async {
    final id = await _motherId();
    final response = await ApiService.post(
      ApiEndpoints.motherEmergencyAlert(id),
      body: {
        'latitude': latitude,
        'longitude': longitude,
      },
    );
    return response['data'] as Map<String, dynamic>;
  }

  static Future<String> uploadProfilePhoto(File file) async {
    final id = await _motherId();
    final response = await ApiService.uploadMultipart(
      path: '/mothers/$id/profile-photo',
      file: file,
      fieldName: 'photo',
    );
    final data = response['data'] as Map<String, dynamic>? ?? {};
    final photo = (data['profilePhoto'] ?? '').toString();
    if (photo.isNotEmpty) {
      profilePhoto.value = photo;
    }
    return photo;
  }
}
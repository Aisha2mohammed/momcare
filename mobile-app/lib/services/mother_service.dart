import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

class MotherService {
  static final ValueNotifier<String?> profilePhoto = ValueNotifier<String?>(null);
  static final ValueNotifier<String?> motherName = ValueNotifier<String?>(null);
  static final ValueNotifier<Map<String, dynamic>?> pregnancyProgress = ValueNotifier<Map<String, dynamic>?>(null);

  static const String _cachedGestationalKey = 'cached_gestational_week';
  static const String _cachedProfileKey = 'cached_mother_profile';
  static const String userLmpKey = 'user_lmp_date';

  /// Calculate gestational progress dynamically from an LMP date string.
  static Map<String, dynamic> calculateProgressFromLmp(String lmpDateStr) {
    try {
      final lmp = DateTime.tryParse(lmpDateStr);
      if (lmp == null) return {};
      final now = DateTime.now();
      final daysSinceLmp = now.difference(lmp).inDays;
      final currentWeek = ((daysSinceLmp / 7).floor() + 1).clamp(1, 42);
      final currentTrimester = currentWeek <= 13 ? 1 : (currentWeek <= 26 ? 2 : 3);
      final dueDate = lmp.add(const Duration(days: 280));
      final daysRemaining = dueDate.difference(now).inDays.clamp(0, 280);
      final weeksRemaining = (daysRemaining / 7).ceil();
      final pct = ((daysSinceLmp / 280.0) * 100).clamp(0.0, 100.0);
      final isOverdue = daysRemaining == 0 && now.isAfter(dueDate);
      return {
        'currentWeek': currentWeek,
        'currentTrimester': currentTrimester,
        'daysRemaining': daysRemaining,
        'weeksRemaining': weeksRemaining,
        'percentageComplete': double.parse(pct.toStringAsFixed(1)),
        'dueDate': dueDate.toIso8601String(),
        'lmpDate': lmpDateStr,
        'isOverdue': isOverdue,
      };
    } catch (_) {
      return {};
    }
  }

  /// Retrieve cached gestational week data, recalculating live against current date if LMP is available.
  static Future<Map<String, dynamic>?> getCachedGestationalWeek() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // 1. Direct saved LMP date key (highest reliability across sessions)
      final directLmp = prefs.getString(userLmpKey);
      if (directLmp != null && directLmp.trim().isNotEmpty) {
        final live = calculateProgressFromLmp(directLmp.trim());
        if (live.isNotEmpty) {
          pregnancyProgress.value = live;
          return live;
        }
      }

      // 2. Cached gestational week JSON
      final jsonStr = prefs.getString(_cachedGestationalKey);
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final map = jsonDecode(jsonStr) as Map<String, dynamic>;
        final lmpStr = map['lmpDate']?.toString();
        if (lmpStr != null && lmpStr.isNotEmpty) {
          final live = calculateProgressFromLmp(lmpStr);
          if (live.isNotEmpty) {
            pregnancyProgress.value = live;
            return live;
          }
        }
        pregnancyProgress.value = map;
        return map;
      }

      // 3. Check if cached profile contains an LMP date
      final profStr = prefs.getString(_cachedProfileKey);
      if (profStr != null && profStr.isNotEmpty) {
        final pMap = jsonDecode(profStr) as Map<String, dynamic>;
        final lmp = pMap['profile']?['lmp_date'] ??
            pMap['profile']?['lmpDate'] ??
            pMap['user']?['lmpDate'] ??
            pMap['user']?['lmp_date'];
        if (lmp != null && lmp.toString().isNotEmpty) {
          final live = calculateProgressFromLmp(lmp.toString());
          if (live.isNotEmpty) {
            pregnancyProgress.value = live;
            return live;
          }
        }
      }
    } catch (_) {}
    return null;
  }

  /// Retrieve cached mother profile from SharedPreferences.
  static Future<Map<String, dynamic>?> getCachedProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final str = prefs.getString(_cachedProfileKey);
      if (str != null && str.isNotEmpty) {
        return jsonDecode(str) as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
  }

  static Future<void> loadInitialProfile() async {
    try {
      // Warm up state with cached profile first for instant rendering
      final cached = await getCachedProfile();
      if (cached != null) {
        final user = cached['user'] as Map<String, dynamic>? ?? {};
        final profile = cached['profile'] as Map<String, dynamic>?;
        final photo = (profile?['profile_photo'] as String?) ?? (user['profile_photo'] as String?);
        final name = user['name'] as String?;
        if (photo != null && photo.isNotEmpty) profilePhoto.value = photo;
        if (name != null && name.isNotEmpty) motherName.value = name;
      }
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
    try {
      final id = await _motherId();
      final response = await ApiService.get(ApiEndpoints.motherProfile(id));
      final data = response['data'] as Map<String, dynamic>;
      final user = data['user'] as Map<String, dynamic>? ?? {};
      final profile = data['profile'] as Map<String, dynamic>?;
      final photo = (profile?['profile_photo'] as String?) ?? (user['profile_photo'] as String?);
      final name = user['name'] as String?;
      profilePhoto.value = (photo != null && photo.isNotEmpty) ? photo : null;
      if (name != null && name.isNotEmpty) {
        motherName.value = name;
      }
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_cachedProfileKey, jsonEncode(data));
        final lmpStr = profile?['lmp_date'] ?? profile?['lmpDate'] ?? user['lmpDate'];
        if (lmpStr != null && lmpStr.toString().isNotEmpty) {
          final live = calculateProgressFromLmp(lmpStr.toString());
          if (live.isNotEmpty) {
            pregnancyProgress.value = live;
            await prefs.setString(userLmpKey, lmpStr.toString());
            await prefs.setString(_cachedGestationalKey, jsonEncode(live));
          }
        }
      } catch (_) {}
      return data;
    } catch (e) {
      final cached = await getCachedProfile();
      if (cached != null) {
        final user = cached['user'] as Map<String, dynamic>? ?? {};
        final profile = cached['profile'] as Map<String, dynamic>?;
        final photo = (profile?['profile_photo'] as String?) ?? (user['profile_photo'] as String?);
        final name = user['name'] as String?;
        profilePhoto.value = (photo != null && photo.isNotEmpty) ? photo : null;
        if (name != null && name.isNotEmpty) {
          motherName.value = name;
        }
        return cached;
      }
      rethrow;
    }
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
    if (lmpDate != null && lmpDate.isNotEmpty) {
      body['lmpDate'] = lmpDate;
      try {
        final live = calculateProgressFromLmp(lmpDate);
        if (live.isNotEmpty) {
          pregnancyProgress.value = live;
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(userLmpKey, lmpDate);
          await prefs.setString(_cachedGestationalKey, jsonEncode(live));
          final cachedProf = prefs.getString(_cachedProfileKey);
          Map<String, dynamic> pMap;
          if (cachedProf != null && cachedProf.isNotEmpty) {
            pMap = jsonDecode(cachedProf) as Map<String, dynamic>;
          } else {
            pMap = {'profile': {}, 'user': {}};
          }
          final prof = Map<String, dynamic>.from(pMap['profile'] as Map? ?? {});
          prof['lmp_date'] = lmpDate;
          prof['lmpDate'] = lmpDate;
          prof['gestational_week'] = live['currentWeek'];
          prof['due_date'] = live['dueDate'];
          pMap['profile'] = prof;
          await prefs.setString(_cachedProfileKey, jsonEncode(pMap));
        }
      } catch (_) {}
    }
    if (city != null && city.isNotEmpty) body['city'] = city;
    if (profilePhoto != null && profilePhoto.isNotEmpty) {
      body['profilePhoto'] = profilePhoto;
      MotherService.profilePhoto.value = profilePhoto;
    }
    await ApiService.put(ApiEndpoints.motherProfile(id), body: body);
  }

  static Future<Map<String, dynamic>> getGestationalWeek() async {
    try {
      final id = await _motherId();
      final response = await ApiService.get(ApiEndpoints.motherGestationalWeek(id));
      final data = response['data'] as Map<String, dynamic>;
      final result = {
        'currentWeek': (data['currentWeek'] ?? data['current_week']) as int? ?? 0,
        'currentTrimester':
            (data['currentTrimester'] ?? data['current_trimester']) as int? ?? 1,
        'daysRemaining': (data['daysRemaining'] ?? data['days_remaining']) as int? ?? 0,
        'weeksRemaining':
            (data['weeksRemaining'] ?? data['weeks_remaining']) as int? ?? 0,
        'percentageComplete':
            ((data['percentageComplete'] ?? data['percentage_complete']) as num?)?.toDouble() ?? 0.0,
        'dueDate': (data['dueDate'] ?? data['due_date'])?.toString(),
        'lmpDate': (data['lmpDate'] ?? data['lmp_date'])?.toString(),
        'isOverdue': data['isOverdue'] ?? false,
      };
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_cachedGestationalKey, jsonEncode(result));
        final lmpVal = result['lmpDate'];
        if (lmpVal != null && lmpVal.toString().isNotEmpty) {
          await prefs.setString(userLmpKey, lmpVal.toString());
        }
      } catch (_) {}
      pregnancyProgress.value = result;
      return result;
    } catch (e) {
      final cached = await getCachedGestationalWeek();
      if (cached != null && (cached['currentWeek'] as int? ?? 0) > 0) {
        return cached;
      }
      rethrow;
    }
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

  static Future<void> deleteProfilePhoto() async {
    final id = await _motherId();
    await ApiService.delete('/mothers/$id/profile-photo');
    profilePhoto.value = null;
  }
}
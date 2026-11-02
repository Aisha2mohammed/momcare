import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SecureStorageService {
  static const _keyToken = 'auth_token';
  static const _keyUserId = 'user_id';
  static const _keyRole = 'user_role';
  static const _keyName = 'user_name';
  static const _keyPhone = 'user_phone';
  static const _keyEmail = 'user_email';
  static const _keyStatus = 'user_status';
  static const _keySpecialization = 'doctor_specialization';
  static const _keyLicense = 'doctor_license';
  static const _keyAvatarUrl = 'doctor_avatar';
  static const _keyLocation = 'doctor_location';
  static const _keyBio = 'doctor_bio';
  static const _keyIsLoggedIn = 'is_logged_in';

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // Save full session
  Future<void> saveSession({
    required String token,
    required String userId,
    required String role,
    required String name,
    String? phone,
    String? email,
    String? status,
    String? specialization,
    String? licenseNumber,
    String? avatarUrl,
    String? location,
    String? bio,
  }) async {
    // 1. Primary: Save to SharedPreferences (rock-solid, persists across app restarts)
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyToken, token);
      await prefs.setString(_keyUserId, userId);
      await prefs.setString(_keyRole, role);
      await prefs.setString(_keyName, name);
      await prefs.setBool(_keyIsLoggedIn, true);

      if (phone != null) await prefs.setString(_keyPhone, phone);
      if (email != null) await prefs.setString(_keyEmail, email);
      if (status != null) await prefs.setString(_keyStatus, status);
      if (specialization != null) await prefs.setString(_keySpecialization, specialization);
      if (licenseNumber != null) await prefs.setString(_keyLicense, licenseNumber);
      if (avatarUrl != null) await prefs.setString(_keyAvatarUrl, avatarUrl);
      if (location != null) await prefs.setString(_keyLocation, location);
      if (bio != null) await prefs.setString(_keyBio, bio);
    } catch (_) {}

    // 2. Secondary: Mirror to FlutterSecureStorage sequentially
    try {
      await _storage.write(key: _keyToken, value: token);
      await _storage.write(key: _keyUserId, value: userId);
      await _storage.write(key: _keyRole, value: role);
      await _storage.write(key: _keyName, value: name);
      if (phone != null) await _storage.write(key: _keyPhone, value: phone);
      if (email != null) await _storage.write(key: _keyEmail, value: email);
      if (status != null) await _storage.write(key: _keyStatus, value: status);
      if (specialization != null) await _storage.write(key: _keySpecialization, value: specialization);
      if (licenseNumber != null) await _storage.write(key: _keyLicense, value: licenseNumber);
      if (avatarUrl != null) await _storage.write(key: _keyAvatarUrl, value: avatarUrl);
      if (location != null) await _storage.write(key: _keyLocation, value: location);
      if (bio != null) await _storage.write(key: _keyBio, value: bio);
    } catch (_) {}
  }

  // Getters with SharedPreferences priority and SecureStorage fallback
  Future<String?> getToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final val = prefs.getString(_keyToken);
      if (val != null && val.isNotEmpty) return val;
    } catch (_) {}
    try {
      return await _storage.read(key: _keyToken);
    } catch (_) {
      return null;
    }
  }

  Future<String?> getUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final val = prefs.getString(_keyUserId);
      if (val != null && val.isNotEmpty) return val;
    } catch (_) {}
    try {
      return await _storage.read(key: _keyUserId);
    } catch (_) {
      return null;
    }
  }

  Future<String?> getRole() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final val = prefs.getString(_keyRole);
      if (val != null && val.isNotEmpty) return val;
    } catch (_) {}
    try {
      return await _storage.read(key: _keyRole);
    } catch (_) {
      return null;
    }
  }

  Future<String?> getName() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final val = prefs.getString(_keyName);
      if (val != null && val.isNotEmpty) return val;
    } catch (_) {}
    try {
      return await _storage.read(key: _keyName);
    } catch (_) {
      return null;
    }
  }

  Future<String?> getPhone() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final val = prefs.getString(_keyPhone);
      if (val != null && val.isNotEmpty) return val;
    } catch (_) {}
    try {
      return await _storage.read(key: _keyPhone);
    } catch (_) {
      return null;
    }
  }

  Future<String?> getEmail() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final val = prefs.getString(_keyEmail);
      if (val != null && val.isNotEmpty) return val;
    } catch (_) {}
    try {
      return await _storage.read(key: _keyEmail);
    } catch (_) {
      return null;
    }
  }

  Future<String?> getStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final val = prefs.getString(_keyStatus);
      if (val != null && val.isNotEmpty) return val;
    } catch (_) {}
    try {
      return await _storage.read(key: _keyStatus);
    } catch (_) {
      return null;
    }
  }

  Future<String?> getSpecialization() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final val = prefs.getString(_keySpecialization);
      if (val != null && val.isNotEmpty) return val;
    } catch (_) {}
    try {
      return await _storage.read(key: _keySpecialization);
    } catch (_) {
      return null;
    }
  }

  Future<String?> getLicenseNumber() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final val = prefs.getString(_keyLicense);
      if (val != null && val.isNotEmpty) return val;
    } catch (_) {}
    try {
      return await _storage.read(key: _keyLicense);
    } catch (_) {
      return null;
    }
  }

  Future<String?> getAvatarUrl() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final val = prefs.getString(_keyAvatarUrl);
      if (val != null && val.isNotEmpty) return val;
    } catch (_) {}
    try {
      return await _storage.read(key: _keyAvatarUrl);
    } catch (_) {
      return null;
    }
  }

  Future<String?> getLocation() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final val = prefs.getString(_keyLocation);
      if (val != null && val.isNotEmpty) return val;
    } catch (_) {}
    try {
      return await _storage.read(key: _keyLocation);
    } catch (_) {
      return null;
    }
  }

  Future<String?> getBio() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final val = prefs.getString(_keyBio);
      if (val != null && val.isNotEmpty) return val;
    } catch (_) {}
    try {
      return await _storage.read(key: _keyBio);
    } catch (_) {
      return null;
    }
  }

  // Setters for individual fields
  Future<void> saveName(String name) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyName, name);
    } catch (_) {}
    try {
      await _storage.write(key: _keyName, value: name);
    } catch (_) {}
  }

  Future<void> savePhone(String phone) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyPhone, phone);
    } catch (_) {}
    try {
      await _storage.write(key: _keyPhone, value: phone);
    } catch (_) {}
  }

  Future<void> saveStatus(String status) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyStatus, status);
    } catch (_) {}
    try {
      await _storage.write(key: _keyStatus, value: status);
    } catch (_) {}
  }

  Future<void> saveSpecialization(String spec) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keySpecialization, spec);
    } catch (_) {}
    try {
      await _storage.write(key: _keySpecialization, value: spec);
    } catch (_) {}
  }

  Future<void> saveAvatarUrl(String url) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyAvatarUrl, url);
    } catch (_) {}
    try {
      await _storage.write(key: _keyAvatarUrl, value: url);
    } catch (_) {}
  }

  // Check if session exists (checks both SharedPreferences and SecureStorage)
  Future<bool> hasSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_keyToken);
      final isLoggedIn = prefs.getBool(_keyIsLoggedIn) ?? false;
      if (token != null && token.isNotEmpty) return true;
      if (isLoggedIn) return true;
    } catch (_) {}
    try {
      final token = await _storage.read(key: _keyToken);
      return token != null && token.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  // Get current user info as a map
  Future<Map<String, String?>> getCurrentUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final uid = prefs.getString(_keyUserId) ?? await _storage.read(key: _keyUserId);
      return {
        'id': uid,
        'token': prefs.getString(_keyToken) ?? await _storage.read(key: _keyToken),
        'userId': uid,
        'role': prefs.getString(_keyRole) ?? await _storage.read(key: _keyRole),
        'name': prefs.getString(_keyName) ?? await _storage.read(key: _keyName),
        'phone': prefs.getString(_keyPhone) ?? await _storage.read(key: _keyPhone),
        'email': prefs.getString(_keyEmail) ?? await _storage.read(key: _keyEmail),
        'status': prefs.getString(_keyStatus) ?? await _storage.read(key: _keyStatus),
        'specialization': prefs.getString(_keySpecialization) ?? await _storage.read(key: _keySpecialization),
        'licenseNumber': prefs.getString(_keyLicense) ?? await _storage.read(key: _keyLicense),
        'avatarUrl': prefs.getString(_keyAvatarUrl) ?? await _storage.read(key: _keyAvatarUrl),
        'location': prefs.getString(_keyLocation) ?? await _storage.read(key: _keyLocation),
        'bio': prefs.getString(_keyBio) ?? await _storage.read(key: _keyBio),
      };
    } catch (_) {
      final uid = await _storage.read(key: _keyUserId);
      return {
        'id': uid,
        'token': await _storage.read(key: _keyToken),
        'userId': uid,
        'role': await _storage.read(key: _keyRole),
        'name': await _storage.read(key: _keyName),
        'phone': await _storage.read(key: _keyPhone),
        'email': await _storage.read(key: _keyEmail),
        'status': await _storage.read(key: _keyStatus),
        'specialization': await _storage.read(key: _keySpecialization),
        'licenseNumber': await _storage.read(key: _keyLicense),
        'avatarUrl': await _storage.read(key: _keyAvatarUrl),
        'location': await _storage.read(key: _keyLocation),
        'bio': await _storage.read(key: _keyBio),
      };
    }
  }

  // Clear session (logout)
  Future<void> clearSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
    } catch (_) {}
    try {
      await _storage.deleteAll();
    } catch (_) {}
  }
}
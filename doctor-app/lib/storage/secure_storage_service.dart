import 'package:flutter_secure_storage/flutter_secure_storage.dart';

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
    await Future.wait([
      _storage.write(key: _keyToken, value: token),
      _storage.write(key: _keyUserId, value: userId),
      _storage.write(key: _keyRole, value: role),
      _storage.write(key: _keyName, value: name),
      if (phone != null) _storage.write(key: _keyPhone, value: phone),
      if (email != null) _storage.write(key: _keyEmail, value: email),
      if (status != null) _storage.write(key: _keyStatus, value: status),
      if (specialization != null) _storage.write(key: _keySpecialization, value: specialization),
      if (licenseNumber != null) _storage.write(key: _keyLicense, value: licenseNumber),
      if (avatarUrl != null) _storage.write(key: _keyAvatarUrl, value: avatarUrl),
      if (location != null) _storage.write(key: _keyLocation, value: location),
      if (bio != null) _storage.write(key: _keyBio, value: bio),
    ]);
  }

  // Getters
  Future<String?> getToken() async => _storage.read(key: _keyToken);
  Future<String?> getUserId() async => _storage.read(key: _keyUserId);
  Future<String?> getRole() async => _storage.read(key: _keyRole);
  Future<String?> getName() async => _storage.read(key: _keyName);
  Future<String?> getPhone() async => _storage.read(key: _keyPhone);
  Future<String?> getEmail() async => _storage.read(key: _keyEmail);
  Future<String?> getStatus() async => _storage.read(key: _keyStatus);
  Future<String?> getSpecialization() async => _storage.read(key: _keySpecialization);
  Future<String?> getLicenseNumber() async => _storage.read(key: _keyLicense);
  Future<String?> getAvatarUrl() async => _storage.read(key: _keyAvatarUrl);
  Future<String?> getLocation() async => _storage.read(key: _keyLocation);
  Future<String?> getBio() async => _storage.read(key: _keyBio);

  // Setters for individual fields
  Future<void> saveName(String name) => _storage.write(key: _keyName, value: name);
  Future<void> savePhone(String phone) => _storage.write(key: _keyPhone, value: phone);
  Future<void> saveStatus(String status) => _storage.write(key: _keyStatus, value: status);
  Future<void> saveSpecialization(String spec) => _storage.write(key: _keySpecialization, value: spec);
  Future<void> saveAvatarUrl(String url) => _storage.write(key: _keyAvatarUrl, value: url);

  // Check if session exists
  Future<bool> hasSession() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  // Get current user info as a map
  Future<Map<String, String?>> getCurrentUser() async {
    return {
      'token': await getToken(),
      'userId': await getUserId(),
      'role': await getRole(),
      'name': await getName(),
      'phone': await getPhone(),
      'email': await getEmail(),
      'status': await getStatus(),
      'specialization': await getSpecialization(),
      'licenseNumber': await getLicenseNumber(),
      'avatarUrl': await getAvatarUrl(),
      'location': await getLocation(),
      'bio': await getBio(),
    };
  }

  // Clear session (logout)
  Future<void> clearSession() async {
    await Future.wait([
      _storage.delete(key: _keyToken),
      _storage.delete(key: _keyUserId),
      _storage.delete(key: _keyRole),
      _storage.delete(key: _keyName),
      _storage.delete(key: _keyPhone),
      _storage.delete(key: _keyEmail),
      _storage.delete(key: _keyStatus),
      _storage.delete(key: _keySpecialization),
      _storage.delete(key: _keyLicense),
      _storage.delete(key: _keyAvatarUrl),
      _storage.delete(key: _keyLocation),
      _storage.delete(key: _keyBio),
    ]);
  }
}
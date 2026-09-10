import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  static const _keyToken = 'auth_token';
  static const _keyUserId = 'user_id';
  static const _keyRole = 'user_role';
  static const _keyName = 'user_name';
  static const _keyPhone = 'user_phone';

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // Save full session
  Future<void> saveSession({
    required String token,
    required String userId,
    required String role,
    required String name,
    String? phone,
  }) async {
    await Future.wait([
      _storage.write(key: _keyToken, value: token),
      _storage.write(key: _keyUserId, value: userId),
      _storage.write(key: _keyRole, value: role),
      _storage.write(key: _keyName, value: name),
      if (phone != null) _storage.write(key: _keyPhone, value: phone),
    ]);
  }

  // Getters
  Future<String?> getToken() async => _storage.read(key: _keyToken);
  Future<String?> getUserId() async => _storage.read(key: _keyUserId);
  Future<String?> getRole() async => _storage.read(key: _keyRole);
  Future<String?> getName() async => _storage.read(key: _keyName);
  Future<String?> getPhone() async => _storage.read(key: _keyPhone);

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
    ]);
  }
}
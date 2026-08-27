import 'api_service.dart';

class AuthResult {
  final String token;
  final Map<String, dynamic> user;
  final bool isNewUser;

  AuthResult({required this.token, required this.user, this.isNewUser = false});
}

class AuthService {
  static Future<AuthResult> login({
    required String phone,
    String? password,
  }) async {
    final body = <String, dynamic>{'phone': phone};
    if (password != null && password.isNotEmpty) {
      body['password'] = password;
    }
    final response = await ApiService.post('/auth/login', body: body);
    final data = response['data'] as Map<String, dynamic>;
    final token = data['token'] as String;
    final user = data['user'] as Map<String, dynamic>;
    await ApiService.saveToken(token);
    if (user['id'] != null) {
      await ApiService.saveUserId(user['id'].toString());
    }
    return AuthResult(token: token, user: user);
  }

  static Future<void> register({
    required String phone,
    required String name,
    String? password,
    String language = 'am',
    String role = 'mother',
    String? email,
    String? lmpDate,
  }) async {
    final body = <String, dynamic>{
      'phone': phone,
      'name': name,
      'language': language,
      'role': role,
    };
    if (password != null && password.isNotEmpty) {
      body['password'] = password;
    }
    if (email != null && email.isNotEmpty) {
      body['email'] = email;
    }
    if (lmpDate != null && lmpDate.isNotEmpty) {
      body['lmpDate'] = lmpDate;
    }
    final response = await ApiService.post('/auth/register', body: body);
    final data = response['data'] as Map<String, dynamic>;
    final token = data['token'] as String?;
    final user = data['user'] as Map<String, dynamic>?;
    if (token != null) {
      await ApiService.saveToken(token);
    }
    if (user != null && user['id'] != null) {
      await ApiService.saveUserId(user['id'].toString());
    }
  }

  static Future<void> sendOtp({required String phone}) async {
    await ApiService.post('/auth/otp/send', body: {'phone': phone});
  }

  static Future<AuthResult> verifyOtp({
    required String phone,
    required String otp,
  }) async {
    final response = await ApiService.post(
      '/auth/otp/verify',
      body: {'phone': phone, 'otp': otp},
    );
    final data = response['data'] as Map<String, dynamic>;
    final token = data['token'] as String;
    await ApiService.saveToken(token);
    final user = data['user'] as Map<String, dynamic>?;
    if (user != null && user['id'] != null) {
      await ApiService.saveUserId(user['id'].toString());
    }
    return AuthResult(
      token: token,
      user: user ?? {},
      isNewUser: data['isNewUser'] as bool? ?? false,
    );
  }
}

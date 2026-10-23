import 'api_service.dart';

class AuthResult {
  final String token;
  final Map<String, dynamic> user;
  final bool isNewUser;

  AuthResult({required this.token, required this.user, this.isNewUser = false});

  /// Account status as returned by the backend:
  /// 'active' | 'pending' | 'rejected' | 'suspended'.
  String? get status => user['status'] as String?;

  /// Whether this user must complete the core profile (LMP date) before
  /// entering the main app.
  ///
  /// The backend includes `lmpDate` in the auth response's `user` object only
  /// for mothers that have an LMP date set (see getMotherProgress in
  /// auth.controller.js), so an absent/empty `lmpDate` means "not set yet".
  /// Non-mothers never get progress fields and must never be sent to setup.
  bool get needsProfileSetup {
    if (user['role'] != 'mother') return false;
    final lmpDate = user['lmpDate'] ?? user['lmp_date'];
    return lmpDate == null || lmpDate.toString().trim().isEmpty;
  }
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
    final response = await ApiService.post(ApiEndpoints.login, body: body);
    final data = response['data'] as Map<String, dynamic>;
    final token = data['token'] as String;
    final user = data['user'] as Map<String, dynamic>;
    await ApiService.saveToken(token);
    await ApiService.saveUserPhone(phone);
    if (user['id'] != null) {
      await ApiService.saveUserId(user['id'].toString());
    }
    if (user['role'] != null) {
      await ApiService.saveUserRole(user['role'].toString());
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
    final response = await ApiService.post(ApiEndpoints.register, body: body);
    final data = response['data'] as Map<String, dynamic>;
    final token = data['token'] as String?;
    final user = data['user'] as Map<String, dynamic>?;
    await ApiService.saveUserPhone(phone);
    if (token != null) {
      await ApiService.saveToken(token);
    }
    if (user != null && user['id'] != null) {
      await ApiService.saveUserId(user['id'].toString());
    }
    if (user != null && user['role'] != null) {
      await ApiService.saveUserRole(user['role'].toString());
    }
  }

  static Future<void> sendOtp({required String phone}) async {
    await ApiService.post(ApiEndpoints.otpSend, body: {'phone': phone});
  }

  // ── Password reset (2-step OTP flow) ─────────────────────────────────
  // Step 1: request a reset OTP for the account phone number.
  static Future<void> forgotPassword({required String phone}) async {
    await ApiService.post(ApiEndpoints.forgotPassword, body: {'phone': phone});
  }

  // Step 2: verify the reset OTP and set a new password.
  static Future<void> resetPassword({
    required String phone,
    required String otp,
    required String password,
  }) async {
    await ApiService.post(
      ApiEndpoints.resetPassword,
      body: {'phone': phone, 'otp': otp, 'password': password},
    );
  }

  static Future<AuthResult> verifyOtp({
    required String phone,
    required String otp,
  }) async {
    final response = await ApiService.post(
      ApiEndpoints.otpVerify,
      body: {'phone': phone, 'otp': otp},
    );
    final data = response['data'] as Map<String, dynamic>;
    final token = data['token'] as String;
    await ApiService.saveToken(token);
    await ApiService.saveUserPhone(phone);
    final user = data['user'] as Map<String, dynamic>?;
    if (user != null && user['id'] != null) {
      await ApiService.saveUserId(user['id'].toString());
    }
    if (user != null && user['role'] != null) {
      await ApiService.saveUserRole(user['role'].toString());
    }
    return AuthResult(
      token: token,
      user: user ?? {},
      isNewUser: data['isNewUser'] as bool? ?? false,
    );
  }

  /// Check current account status (pending, active, rejected, suspended)
  static Future<Map<String, dynamic>> checkStatus() async {
    final response = await ApiService.get(ApiEndpoints.authStatus);
    return response['data'] as Map<String, dynamic>;
  }
}

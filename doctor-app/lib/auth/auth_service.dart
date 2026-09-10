import 'package:dio/dio.dart';
import 'package:doctor_app/api/api_client.dart';
import 'package:doctor_app/api/api_endpoints.dart';
import 'package:doctor_app/storage/secure_storage_service.dart';

class AuthException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic responseData;

  AuthException(this.message, {this.statusCode, this.responseData});

  @override
  String toString() => 'AuthException: $message (status: $statusCode)';
}

class AuthService {
  final ApiClient _apiClient;
  final SecureStorageService _storage;

  AuthService(this._apiClient, this._storage);

  Future<Map<String, dynamic>> login({
    required String phone,
    required String password,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        ApiEndpoints.login,
        data: {'phone': phone, 'password': password},
      );

      final data = response.data;
      if (data == null || data['success'] != true) {
        throw AuthException(
          data?['message'] ?? 'Login failed',
          statusCode: response.statusCode,
          responseData: data,
        );
      }

      final userData = data['data'] as Map<String, dynamic>?;
      final token = userData?['token'] as String?;
      final user = userData?['user'] as Map<String, dynamic>?;

      if (token == null || user == null) {
        throw AuthException('Invalid response format from server');
      }

      final role = user['role'] as String?;
      if (role != 'doctor') {
        throw AuthException('This account is not a doctor account');
      }

      final userId = user['id'] as String?;
      if (userId == null) {
        throw AuthException('Invalid user data received from server');
      }

      // Store session
      await _storage.saveSession(
        token: token,
        userId: userId,
        role: role!,
        name: user['name'] as String? ?? '',
        phone: user['phone'] as String?,
      );

      return {
        'token': token,
        'user': user,
      };
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  Future<void> logout() async {
    await _storage.clearSession();
  }

  Future<bool> isLoggedIn() async {
    return _storage.hasSession();
  }

  Future<String?> getToken() async {
    return _storage.getToken();
  }

  Future<Map<String, String?>> getCurrentUser() async {
    return _storage.getCurrentUser();
  }

  AuthException _mapDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return AuthException('Connection timeout. Please check your internet connection.');
      case DioExceptionType.connectionError:
        return AuthException('Cannot connect to server. Please try again later.');
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        final data = e.response?.data;
        String message;
        if (data is Map && data['message'] != null) {
          message = data['message'] as String;
        } else {
          message = _defaultMessageForStatus(statusCode);
        }
        return AuthException(message, statusCode: statusCode, responseData: data);
      case DioExceptionType.cancel:
        return AuthException('Request was cancelled.');
      case DioExceptionType.unknown:
      default:
        return AuthException('An unexpected error occurred. Please try again.');
    }
  }

  String _defaultMessageForStatus(int? statusCode) {
    switch (statusCode) {
      case 400:
        return 'Invalid request. Please check your input.';
      case 401:
        return 'Invalid phone number or password.';
      case 403:
        return 'Your account has been deactivated.';
      case 404:
        return 'Account not found.';
      case 500:
        return 'Server error. Please try again later.';
      default:
        return 'Request failed with status $statusCode';
    }
  }
}
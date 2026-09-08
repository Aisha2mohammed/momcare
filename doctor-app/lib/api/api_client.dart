import 'package:dio/dio.dart';
import 'package:doctor_app/api/api_endpoints.dart';
import 'package:doctor_app/storage/secure_storage_service.dart';

class ApiClient {
  final Dio _dio;
  final SecureStorageService _storage;

  ApiClient(this._storage)
      : _dio = Dio(BaseOptions(
          baseUrl: ApiEndpoints.baseUrl,
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        )) {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.getToken();
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) {
        // Don't handle errors here - let the caller handle them
        // This keeps error handling explicit in the calling code
        handler.next(error);
      },
    ));
  }

  Dio get dio => _dio;

  Future<void> clearAuthHeader() async {
    // Token will be read fresh on next request via interceptor
  }
}
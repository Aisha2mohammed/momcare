import 'package:dio/dio.dart';
import 'package:doctor_app/api/api_client.dart';
import 'package:doctor_app/api/api_endpoints.dart';
import 'package:doctor_app/storage/secure_storage_service.dart';
import 'package:doctor_app/model/doctor_profile_model.dart';

class AuthException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic responseData;

  AuthException(this.message, {this.statusCode, this.responseData});

  @override
  String toString() => message;
}

class AuthService {
  final ApiClient _apiClient;
  final SecureStorageService _storage;

  static final SecureStorageService _defaultStorage = SecureStorageService();
  static final ApiClient _defaultApiClient = ApiClient(_defaultStorage);

  static final AuthService instance = AuthService(_defaultApiClient, _defaultStorage);

  AuthService([ApiClient? apiClient, SecureStorageService? storage])
      : _storage = storage ?? _defaultStorage,
        _apiClient = apiClient ?? _defaultApiClient;

  SecureStorageService get storage => _storage;
  ApiClient get apiClient => _apiClient;

  // ─── LOGIN ──────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> login({
    required String phone,
    String? name,
    String? password,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        ApiEndpoints.login,
        data: {
          'phone': phone.trim(),
          if (name != null && name.trim().isNotEmpty) 'name': name.trim(),
          if (password != null && password.isNotEmpty) 'password': password,
        },
      );

      final data = response.data;
      if (data == null || data['success'] != true) {
        throw AuthException(
          data?['message'] ?? 'Login failed',
          statusCode: response.statusCode,
          responseData: data,
        );
      }

      final resData = data['data'] as Map<String, dynamic>?;
      final token = resData?['token'] as String?;
      final user = resData?['user'] as Map<String, dynamic>?;

      if (token == null || user == null) {
        throw AuthException('Invalid response format from server');
      }

      final role = user['role'] as String? ?? 'doctor';
      if (role != 'doctor') {
        throw AuthException('This account is not registered as a doctor.');
      }

      final userId = user['id'] as String?;
      if (userId == null) {
        throw AuthException('Invalid user ID received from server');
      }

      final doctorProfile = user['doctorProfile'] as Map<String, dynamic>?;
      final status = (user['status'] as String? ?? 'pending').toLowerCase();
      final approvalStatus = (doctorProfile?['approval_status'] as String? ?? (status == 'active' ? 'approved' : status)).toLowerCase();
      final isApproved = status == 'active' && approvalStatus == 'approved';

      // Store session
      await _storage.saveSession(
        token: token,
        userId: userId,
        role: role,
        name: user['name'] as String? ?? (name ?? 'Dr. Unknown'),
        phone: user['phone'] as String? ?? phone,
        email: user['email'] as String?,
        status: status,
        specialization: doctorProfile?['specialization'] as String?,
        licenseNumber: doctorProfile?['license_number'] as String?,
        avatarUrl: doctorProfile?['photo_url'] as String?,
        location: doctorProfile?['location'] as String?,
        bio: doctorProfile?['bio'] as String?,
      );

      // Sync local profile model
      _syncProfileModel(user, doctorProfile);

      return {
        'token': token,
        'user': user,
        'status': status,
        'approvalStatus': approvalStatus,
        'isApproved': isApproved,
        'isPending': status == 'pending' || approvalStatus == 'pending',
      };
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  // ─── UPLOAD DOCUMENT / FILE ──────────────────────────────────────────
  Future<String> uploadFile({
    required String filePath,
    String? fileName,
  }) async {
    try {
      final name = fileName ?? filePath.split(RegExp(r'[\\/]')).last;
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          filePath,
          filename: name,
        ),
      });

      final response = await _apiClient.dio.post(
        ApiEndpoints.upload,
        data: formData,
      );

      final data = response.data;
      if (data == null || data['success'] != true) {
        throw AuthException(data?['message'] ?? 'File upload failed');
      }

      final resData = data['data'] as Map<String, dynamic>? ?? {};
      final fileUrl = resData['url']?.toString() ?? '';
      return fileUrl;
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  // ─── REGISTER ───────────────────────────────────────────────────────
  Future<Map<String, dynamic>> register({
    required String name,
    required String phone,
    String? password,
    String? email,
    String? specialization,
    String? licenseNumber,
    String? hospitalClinicName,
    String? location,
    String? yearsExperience,
    String? bio,
    String? licenseExpiryDate,
    String? nationalId,
    String? nationalIdUrl,
    String? credentialDocument,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        ApiEndpoints.register,
        data: {
          'role': 'doctor',
          'name': name.trim(),
          'phone': phone.trim(),
          if (password != null && password.isNotEmpty) 'password': password,
          if (email != null && email.isNotEmpty) 'email': email.trim(),
          'specialization': specialization?.trim() ?? 'Obstetrics & Gynecology',
          if (licenseNumber != null && licenseNumber.isNotEmpty) 'licenseNumber': licenseNumber.trim(),
          if (hospitalClinicName != null && hospitalClinicName.isNotEmpty) 'hospitalClinicName': hospitalClinicName.trim(),
          if (location != null && location.isNotEmpty) 'location': location.trim(),
          if (yearsExperience != null && yearsExperience.isNotEmpty) 'yearsExperience': yearsExperience.trim(),
          if (bio != null && bio.isNotEmpty) 'bio': bio.trim(),
          if (licenseExpiryDate != null && licenseExpiryDate.isNotEmpty) 'licenseExpiryDate': licenseExpiryDate.trim(),
          if (nationalId != null && nationalId.isNotEmpty) 'nationalId': nationalId.trim(),
          if (nationalIdUrl != null && nationalIdUrl.isNotEmpty) 'nationalIdUrl': nationalIdUrl.trim(),
          if (credentialDocument != null && credentialDocument.isNotEmpty) 'credentialDocument': credentialDocument.trim(),
        },
      );

      final data = response.data;
      if (data == null || data['success'] != true) {
        throw AuthException(
          data?['message'] ?? 'Registration failed',
          statusCode: response.statusCode,
          responseData: data,
        );
      }

      final resData = data['data'] as Map<String, dynamic>?;
      final token = resData?['token'] as String?;
      final user = resData?['user'] as Map<String, dynamic>?;

      if (token == null || user == null) {
        throw AuthException('Invalid response format from server');
      }

      final userId = user['id'] as String?;
      final doctorProfile = user['doctorProfile'] as Map<String, dynamic>?;

      // Save initial session
      await _storage.saveSession(
        token: token,
        userId: userId ?? '',
        role: 'doctor',
        name: name,
        phone: phone,
        email: email,
        status: 'pending',
        specialization: specialization,
        licenseNumber: licenseNumber,
        location: location,
        bio: bio,
      );

      _syncProfileModel(user, doctorProfile);

      return {
        'token': token,
        'user': user,
        'status': 'pending',
      };
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  // ─── CHECK ACCOUNT STATUS ──────────────────────────────────────────
  Future<Map<String, dynamic>> checkStatus() async {
    try {
      final response = await _apiClient.dio.get(ApiEndpoints.authStatus);
      final data = response.data;
      if (data == null || data['success'] != true) {
        throw AuthException(data?['message'] ?? 'Failed to check status');
      }

      final resData = data['data'] as Map<String, dynamic>? ?? {};
      final user = resData['user'] as Map<String, dynamic>? ?? {};
      final doctorProfile = user['doctorProfile'] as Map<String, dynamic>?;

      final status = (resData['status']?.toString() ?? 'pending').toLowerCase();
      final isApproved = resData['isApproved'] == true || status == 'active';
      final isPending = resData['isPending'] == true || status == 'pending';
      final isRejected = resData['isRejected'] == true || status == 'rejected';
      final isSuspended = resData['isSuspended'] == true || status == 'suspended';

      if (status.isNotEmpty) {
        await _storage.saveStatus(status);
      }

      _syncProfileModel(user, doctorProfile);

      return {
        'status': status,
        'isApproved': isApproved,
        'isPending': isPending,
        'isRejected': isRejected,
        'isSuspended': isSuspended,
        'user': user,
        'doctorProfile': doctorProfile,
      };
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  // ─── SEND OTP (AfroMessage SMS) ────────────────────────────────────
  Future<void> sendOtp({required String phone}) async {
    try {
      final response = await _apiClient.dio.post(
        ApiEndpoints.otpSend,
        data: {'phone': phone.trim()},
      );

      final data = response.data;
      if (data == null || data['success'] != true) {
        throw AuthException(data?['message'] ?? 'Failed to send OTP SMS');
      }
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  // ─── VERIFY OTP ────────────────────────────────────────────────────
  Future<Map<String, dynamic>> verifyOtp({
    required String phone,
    required String otp,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        ApiEndpoints.otpVerify,
        data: {'phone': phone.trim(), 'otp': otp.trim()},
      );

      final data = response.data;
      if (data == null || data['success'] != true) {
        throw AuthException(data?['message'] ?? 'Invalid verification code');
      }

      final resData = data['data'] as Map<String, dynamic>? ?? {};
      final token = resData['token'] as String?;
      final user = resData['user'] as Map<String, dynamic>?;

      if (token != null && user != null) {
        final userId = user['id'] as String? ?? '';
        final role = user['role'] as String? ?? 'doctor';
        final doctorProfile = user['doctorProfile'] as Map<String, dynamic>?;

        await _storage.saveSession(
          token: token,
          userId: userId,
          role: role,
          name: user['name'] as String? ?? 'Dr. Unknown',
          phone: user['phone'] as String? ?? phone,
          email: user['email'] as String?,
          status: user['status'] as String? ?? 'active',
          specialization: doctorProfile?['specialization'] as String?,
          licenseNumber: doctorProfile?['license_number'] as String?,
          avatarUrl: doctorProfile?['photo_url'] as String?,
          location: doctorProfile?['location'] as String?,
          bio: doctorProfile?['bio'] as String?,
        );

        _syncProfileModel(user, doctorProfile);
      }

      return resData;
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  // ─── GET PROFILE ───────────────────────────────────────────────────
  Future<Map<String, dynamic>> getDoctorProfile(String id) async {
    try {
      final endpoint = ApiEndpoints.doctorProfile.replaceAll(':id', id);
      final response = await _apiClient.dio.get(endpoint);
      final data = response.data;
      if (data == null || data['success'] != true) {
        throw AuthException(data?['message'] ?? 'Failed to retrieve profile');
      }

      final profile = data['data'] as Map<String, dynamic>? ?? {};
      _syncProfileModel(profile, profile);
      return profile;
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  // ─── UPDATE PROFILE ────────────────────────────────────────────────
  Future<Map<String, dynamic>> updateDoctorProfile(
    String id,
    Map<String, dynamic> updateData,
  ) async {
    try {
      final endpoint = ApiEndpoints.doctorProfile.replaceAll(':id', id);
      final response = await _apiClient.dio.put(endpoint, data: updateData);
      final data = response.data;
      if (data == null || data['success'] != true) {
        throw AuthException(data?['message'] ?? 'Failed to update profile');
      }

      final profile = data['data'] as Map<String, dynamic>? ?? {};

      // Update storage
      if (updateData['name'] != null) await _storage.saveName(updateData['name']);
      if (updateData['specialization'] != null) await _storage.saveSpecialization(updateData['specialization']);
      if (updateData['photoUrl'] != null) await _storage.saveAvatarUrl(updateData['photoUrl']);

      _syncProfileModel(profile, profile);
      return profile;
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  // ─── UPDATE PROFILE PHOTO ──────────────────────────────────────────
  Future<String> updateProfilePhoto(String id, String photoUrl) async {
    await updateDoctorProfile(id, {'photoUrl': photoUrl});
    await _storage.saveAvatarUrl(photoUrl);
    DoctorProfileModel.shared.avatarUrl = photoUrl;
    return photoUrl;
  }

  // ─── LOGOUT ────────────────────────────────────────────────────────
  Future<void> logout() async {
    await _storage.clearSession();
  }

  Future<bool> isLoggedIn() async {
    return _storage.hasSession();
  }

  Future<String?> getToken() async => _storage.getToken();

  Future<Map<String, String?>> getCurrentUser() async => _storage.getCurrentUser();

  void _syncProfileModel(Map<String, dynamic>? user, Map<String, dynamic>? docProfile) {
    if (user == null) return;
    final shared = DoctorProfileModel.shared;
    if (user['name'] != null && user['name'].toString().isNotEmpty) {
      shared.name = user['name'].toString().startsWith('Dr.') ? user['name'] : 'Dr. ${user['name']}';
    }
    if (docProfile?['specialization'] != null) {
      shared.specialization = docProfile!['specialization'].toString();
    }
    if (docProfile?['license_number'] != null) {
      shared.licenseNumber = docProfile!['license_number'].toString();
    }
    if (docProfile?['location'] != null) {
      shared.practiceLocation = docProfile!['location'].toString();
      shared.clinicAffiliation = docProfile['location'].toString();
    }
    if (docProfile?['bio'] != null) {
      shared.bio = docProfile!['bio'].toString();
    }
    if (docProfile?['hospital_clinic_name'] != null) {
      shared.hospitalClinicName = docProfile!['hospital_clinic_name'].toString();
      shared.clinicAffiliation = docProfile['hospital_clinic_name'].toString();
    }
    if (docProfile?['license_expiry_date'] != null) {
      shared.licenseExpiryDate = docProfile!['license_expiry_date'].toString();
      shared.licenseExpiry = docProfile['license_expiry_date'].toString();
    }
    if (docProfile?['national_id'] != null) {
      shared.nationalId = docProfile!['national_id'].toString();
    }
    if (docProfile?['national_id_url'] != null) {
      shared.nationalIdUrl = docProfile!['national_id_url'].toString();
    }
    if (docProfile?['credential_document_url'] != null) {
      shared.credentialDocumentUrl = docProfile!['credential_document_url'].toString();
    }
    if (docProfile?['years_experience'] != null) {
      shared.yearsExperience = '${docProfile!['years_experience']} Years Experience';
    }
    if (docProfile?['photo_url'] != null && docProfile!['photo_url'].toString().isNotEmpty) {
      final photo = docProfile['photo_url'].toString();
      shared.avatarUrl = photo.startsWith('http') ? photo : 'http://localhost:5000$photo';
    }
    shared.notify();
  }

  AuthException _mapDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return AuthException('Connection timeout. Please check your network.');
      case DioExceptionType.connectionError:
        return AuthException('Cannot connect to server. Please verify backend is running.');
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        final data = e.response?.data;
        String message;
        if (data is Map) {
          message = data['message'] as String? ?? data['error']?['message'] as String? ?? _defaultMessageForStatus(statusCode);
        } else {
          message = _defaultMessageForStatus(statusCode);
        }
        return AuthException(message, statusCode: statusCode, responseData: data);
      case DioExceptionType.cancel:
        return AuthException('Request was cancelled.');
      default:
        return AuthException('An unexpected error occurred. Please try again.');
    }
  }

  String _defaultMessageForStatus(int? statusCode) {
    switch (statusCode) {
      case 400:
        return 'Invalid request details. Please check your inputs.';
      case 401:
        return 'Invalid phone number or password.';
      case 403:
        return 'Access denied or account under review.';
      case 404:
        return 'Account not found.';
      case 409:
        return 'An account with this phone number already exists.';
      case 500:
        return 'Server encountered an error. Please try again.';
      default:
        return 'Request failed with status $statusCode';
    }
  }
}
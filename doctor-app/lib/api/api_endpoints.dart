class ApiEndpoints {
  static const String baseUrl = 'http://192.168.1.7:5000/api/v1';
  static String get baseServerUrl => baseUrl.replaceAll('/api/v1', '');

  /// Resolves relative or localhost media/avatar URLs to the real server host
  static String resolveUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http://') || path.startsWith('https://')) {
      final uri = Uri.parse(baseUrl);
      return path
          .replaceAll('http://localhost:5000', '${uri.scheme}://${uri.host}:${uri.port}')
          .replaceAll('http://127.0.0.1:5000', '${uri.scheme}://${uri.host}:${uri.port}');
    }
    final cleanPath = path.startsWith('/') ? path : '/$path';
    return '$baseServerUrl$cleanPath';
  }

  // Auth
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String upload = '/auth/upload';
  static const String authStatus = '/auth/status';
  static const String otpSend = '/auth/otp/send';
  static const String otpVerify = '/auth/otp/verify';
  static const String forgotPassword = '/auth/forgot-password';
  static const String resetPassword = '/auth/reset-password';
  static const String updateFcmToken = '/auth/fcm-token';

  // Doctor
  static const String doctorRegister = '/doctors/register';
  static const String doctorProfile = '/doctors/:id/profile';
  static const String doctorProfilePhoto = '/doctors/:id/profile-photo';
  static const String doctorAvailabilitySlots = '/doctors/:id/availability-slots';
  static const String doctorAppointments = '/doctors/:id/appointments';
  static const String doctorPatients = '/doctors/:id/patients';
  static const String doctorNotify = '/doctors/:id/notify';
  static const String healthProviders = '/doctors/health-providers';

  // Appointments
  static const String appointments = '/appointments';
  static const String appointmentById = '/appointments/:id';
  static const String appointmentStatus = '/appointments/:id/status';
  static const String appointmentRespond = '/appointments/:id/respond';
  static const String appointmentClinicalRecord = '/appointments/:id/clinical-record';

  // Chat
  static const String chatMessages = '/chat/:motherId/:doctorId/messages';

  // Notifications
  static const String notificationsMe = '/notifications/me';
  static const String notificationRead = '/notifications/:id/read';
}
import 'package:shared_preferences/shared_preferences.dart';

import 'api_service.dart';

class DoctorService {
  static const String _appointmentIdsKey = 'appointment_ids';

  // ── Doctor discovery ──────────────────────────────────────────────────
  static Future<List<dynamic>> getHealthProviders() async {
    final response = await ApiService.get('/doctors/health-providers');
    return response['data'] as List<dynamic>;
  }

  static Future<List<dynamic>> getDoctorsByProvider(String providerId) async {
    final response =
        await ApiService.get('/doctors/health-providers/$providerId/doctors');
    return response['data'] as List<dynamic>;
  }

  static Future<Map<String, dynamic>> getDoctorPublicProfile(
    String doctorId,
  ) async {
    final response = await ApiService.get('/doctors/public/$doctorId');
    return response['data'] as Map<String, dynamic>;
  }

  // ── Availability & booking ───────────────────────────────────────────
  static Future<List<dynamic>> getAvailabilitySlots(String doctorId) async {
    final response = await ApiService.get('/doctors/$doctorId/availability-slots');
    return response['data'] as List<dynamic>;
  }

  static Future<Map<String, dynamic>> bookAppointment({
    required String doctorId,
    required String slotDatetime,
  }) async {
    final response = await ApiService.post(
      '/appointments',
      body: {'doctorId': doctorId, 'slotDatetime': slotDatetime},
    );
    return response['data'] as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> getAppointment(String appointmentId) async {
    final response = await ApiService.get('/appointments/$appointmentId');
    return response['data'] as Map<String, dynamic>;
  }

  // ── Local persistence of booked appointment ids (for "My Appointments") ─
  static Future<void> saveAppointmentId(String appointmentId) async {
    final prefs = await SharedPreferences.getInstance();
    final ids = prefs.getStringList(_appointmentIdsKey) ?? <String>[];
    if (!ids.contains(appointmentId)) {
      ids.add(appointmentId);
      await prefs.setStringList(_appointmentIdsKey, ids);
    }
  }

  static Future<List<String>> getAppointmentIds() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_appointmentIdsKey) ?? <String>[];
  }
}
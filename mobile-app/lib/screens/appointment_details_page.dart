import 'package:flutter/material.dart';
import 'package:pregnancy_appp/constants/color.dart';
import 'package:pregnancy_appp/services/api_service.dart';
import 'package:pregnancy_appp/services/doctor_service.dart';

class AppointmentDetailsPage extends StatefulWidget {
  final String appointmentId;

  const AppointmentDetailsPage({super.key, required this.appointmentId});

  @override
  State<AppointmentDetailsPage> createState() => _AppointmentDetailsPageState();
}

class _AppointmentDetailsPageState extends State<AppointmentDetailsPage> {
  Map<String, dynamic>? _appointment;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final appointment = await DoctorService.getAppointment(widget.appointmentId);
      if (!mounted) return;
      setState(() => _appointment = appointment);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Network error. Please try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _formatSlot(String? iso) {
    if (iso == null || iso.isEmpty) return '--';
    final d = DateTime.tryParse(iso)?.toLocal();
    if (d == null) return iso;
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final period = d.hour >= 12 ? 'PM' : 'AM';
    final h = (d.hour % 12 == 0 ? 12 : d.hour % 12);
    return '${days[d.weekday - 1]}, ${months[d.month - 1]} ${d.day}, ${d.year} · $h:${d.minute.toString().padLeft(2, '0')} $period';
  }

  (Color, IconData, String) _statusStyle(String status) {
    switch (status) {
      case 'confirmed':
        return (Colors.green[50]!, Icons.check_circle_rounded, 'Confirmed');
      case 'rejected':
        return (Colors.red[50]!, Icons.cancel_rounded, 'Rejected');
      case 'completed':
        return (Colors.blue[50]!, Icons.verified_rounded, 'Completed');
      case 'cancelled':
        return (Colors.grey[200]!, Icons.block_rounded, 'Cancelled');
      case 'pending':
      default:
        return (Colors.orange[50]!, Icons.schedule_rounded, 'Pending');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
        title: const Text('Appointment Details'),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: _load, child: const Text('Retry')),
          ],
        ),
      );
    }

    final a = _appointment!;
    final status = (a['status'] as String?) ?? 'pending';
    final (bg, icon, label) = _statusStyle(status);
    final doctorName = (a['doctor_name'] as String?) ?? 'Doctor';
    final specialization = (a['specialization'] as String?) ?? '';
    final doctorPhone = (a['doctor_phone'] as String?) ?? '';
    final motherName = (a['mother_name'] as String?) ?? '';
    final slotText = _formatSlot(a['slot_datetime'] as String?);

    final details = <(IconData, String, String)>[
      (Icons.event_rounded, 'Date & Time', slotText),
      (Icons.local_hospital_rounded, 'Doctor', doctorName),
      (Icons.medical_services_outlined, 'Specialization', specialization.isEmpty ? 'General' : specialization),
      if (doctorPhone.isNotEmpty) (Icons.phone_rounded, 'Doctor Phone', doctorPhone),
      if (motherName.isNotEmpty) (Icons.person_outline_rounded, 'Member', motherName),
      (Icons.confirmation_number_outlined, 'Booking Ref', widget.appointmentId),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Icon(icon, color: AppColors.primary, size: 32),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Status: $label',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        status == 'pending'
                            ? 'Waiting for the doctor to confirm your appointment.'
                            : 'This appointment has been ${status == 'confirmed' ? 'confirmed' : status}.',
                        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 5)),
              ],
            ),
            child: Column(
              children: details.map((d) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(d.$1, color: AppColors.primary, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(d.$2, style: const TextStyle(color: Colors.black54, fontSize: 12)),
                            const SizedBox(height: 4),
                            Text(d.$3, style: const TextStyle(fontSize: 15)),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.06),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline_rounded, color: AppColors.primary, size: 20),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Bring your ID and any recent medical records to your appointment.',
                    style: TextStyle(fontSize: 13, color: Colors.black87, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
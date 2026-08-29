import 'package:flutter/material.dart';
import 'package:pregnancy_appp/constants/color.dart';
import 'package:pregnancy_appp/screens/appointment_details_page.dart';
import 'package:pregnancy_appp/services/api_service.dart';
import 'package:pregnancy_appp/services/doctor_service.dart';

class HealthProvider {
  final String id;
  final String name;
  final String? location;

  HealthProvider({required this.id, required this.name, this.location});
}

class DoctorSummary {
  final String id;
  final String name;
  final String? phone;
  final String? specialization;
  final String? location;
  final String? bio;
  final String? photoUrl;

  DoctorSummary({
    required this.id,
    required this.name,
    this.phone,
    this.specialization,
    this.location,
    this.bio,
    this.photoUrl,
  });
}

class ConnectClinicPage extends StatefulWidget {
  const ConnectClinicPage({super.key});

  @override
  State<ConnectClinicPage> createState() => _ConnectClinicPageState();
}

class _ConnectClinicPageState extends State<ConnectClinicPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  bool _loadingProviders = true;
  String? _providerError;
  List<HealthProvider> _providers = [];
  HealthProvider? _selectedProvider;

  bool _loadingDoctors = false;
  String? _doctorError;
  List<DoctorSummary> _doctors = [];

  List<String> _appointmentIds = [];
  bool _loadingAppointments = false;
  String? _appointmentError;
  final List<Map<String, dynamic>> _appointments = [];

  @override
  void initState() {
    super.initState();
    _loadProviders();
    _loadAppointmentIds();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ── Data loading ────────────────────────────────────────────────────
  Future<void> _loadProviders() async {
    setState(() {
      _loadingProviders = true;
      _providerError = null;
    });
    try {
      final list = await DoctorService.getHealthProviders();
      final providers = list.map((p) {
        return HealthProvider(
          id: p['id'].toString(),
          name: (p['name'] as String?) ?? 'Unknown Provider',
          location: p['location'] as String?,
        );
      }).toList();
      if (!mounted) return;
      setState(() {
        _providers = providers;
        _selectedProvider = providers.isNotEmpty ? providers.first : null;
      });
      if (providers.isNotEmpty) {
        await _loadDoctors(providers.first.id);
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _providerError = e.message);
    } catch (e) {
      if (!mounted) return;
      setState(() => _providerError = 'Network error. Please try again.');
    } finally {
      if (mounted) setState(() => _loadingProviders = false);
    }
  }

  Future<void> _loadDoctors(String providerId) async {
    setState(() {
      _loadingDoctors = true;
      _doctorError = null;
      _doctors = [];
    });
    try {
      final list = await DoctorService.getDoctorsByProvider(providerId);
      final doctors = list.map((d) {
        return DoctorSummary(
          id: d['id'].toString(),
          name: (d['name'] as String?) ?? 'Doctor',
          phone: d['phone'] as String?,
          specialization:
              (d['specialization'] as String?) ?? 'General Practitioner',
          location: d['location'] as String?,
          bio: d['bio'] as String?,
          photoUrl: d['photo_url'] as String?,
        );
      }).toList();
      if (!mounted) return;
      setState(() => _doctors = doctors);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _doctorError = e.message);
    } catch (e) {
      if (!mounted) return;
      setState(() => _doctorError = 'Network error. Please try again.');
    } finally {
      if (mounted) setState(() => _loadingDoctors = false);
    }
  }

  Future<void> _loadAppointmentIds() async {
    final ids = await DoctorService.getAppointmentIds();
    if (!mounted) return;
    setState(() => _appointmentIds = ids);
    if (ids.isNotEmpty) {
      await _fetchAppointments();
    }
  }

  Future<void> _fetchAppointments() async {
    setState(() {
      _loadingAppointments = true;
      _appointmentError = null;
    });
    final fetched = <Map<String, dynamic>>[];
    try {
      for (final id in _appointmentIds) {
        final appt = await DoctorService.getAppointment(id);
        fetched.add(appt);
      }
      if (!mounted) return;
      setState(() {
        _appointments
          ..clear()
          ..addAll(fetched);
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _appointmentError = e.message);
    } catch (e) {
      if (!mounted) return;
      setState(() => _appointmentError = 'Network error. Please try again.');
    } finally {
      if (mounted) setState(() => _loadingAppointments = false);
    }
  }

  // ── Doctor detail sheet ─────────────────────────────────────────────
  Future<void> _showDoctorDetails(DoctorSummary doc) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _DoctorDetailSheet(
        doc: doc,
        onBook: () async {
          Navigator.pop(ctx);
          if (!mounted) return;
          await _openBookingSheet(context, doc);
        },
      ),
    );
  }

  Future<void> _openBookingSheet(BuildContext ctx, DoctorSummary doc) async {
    await showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) => _BookingSheet(
        doctorId: doc.id,
        doctorName: doc.name,
        onBooked: (appointmentId) {
          Navigator.pop(sheetCtx);
          _loadAppointmentIds();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AppointmentDetailsPage(appointmentId: appointmentId),
            ),
          );
        },
      ),
    );
  }

  // ── Formatting helpers ──────────────────────────────────────────────
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

  Widget _statusChip(String status) {
    Color bg;
    Color fg;
    String label;
    switch (status) {
      case 'confirmed':
        bg = Colors.green[100]!;
        fg = Colors.green[800]!;
        label = 'Confirmed';
      case 'pending':
        bg = Colors.orange[100]!;
        fg = Colors.deepOrange;
        label = 'Pending';
      case 'rejected':
        bg = Colors.red[100]!;
        fg = Colors.red[800]!;
        label = 'Rejected';
      case 'completed':
        bg = Colors.blue[100]!;
        fg = Colors.blue[800]!;
        label = 'Completed';
      case 'cancelled':
        bg = Colors.grey[200]!;
        fg = Colors.grey[700]!;
        label = 'Cancelled';
      default:
        bg = Colors.grey[200]!;
        fg = Colors.grey[700]!;
        label = status.isEmpty ? 'Unknown' : status[0].toUpperCase() + status.substring(1);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }

  // ── UI ──────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final filteredDoctors = _doctors.where((d) {
      final q = _searchQuery;
      if (q.isEmpty) return true;
      return d.name.toLowerCase().contains(q) ||
          (d.specialization?.toLowerCase().contains(q) ?? false);
    }).toList();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: const Text('Connect Doctor', style: TextStyle(color: Colors.black)),
          backgroundColor: Colors.white,
          elevation: 1,
          iconTheme: const IconThemeData(color: Colors.black),
          bottom: const TabBar(
            labelColor: AppColors.primary,
            unselectedLabelColor: Colors.black54,
            indicatorColor: AppColors.primary,
            tabs: [
              Tab(text: 'Find Doctor'),
              Tab(text: 'My Appointments'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Tab 1: Find Doctor
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) => setState(() => _searchQuery = val.toLowerCase().trim()),
                    decoration: InputDecoration(
                      hintText: 'Search by name or specialty',
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                    ),
                  ),
                ),
                _buildProviderBar(context),
                Expanded(child: _buildDoctorsList(context, filteredDoctors)),
              ],
            ),

            // Tab 2: My Appointments
            _buildAppointmentsTab(context),
          ],
        ),
      ),
    );
  }

  Widget _buildProviderBar(BuildContext context) {
    if (_loadingProviders && _providers.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }
    if (_providerError != null && _providers.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Expanded(child: Text(_providerError!, style: const TextStyle(color: Colors.red, fontSize: 13))),
            TextButton(onPressed: _loadProviders, child: const Text('Retry')),
          ],
        ),
      );
    }
    if (_providers.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Text('No health providers available yet.', style: TextStyle(color: Colors.grey, fontSize: 13)),
      );
    }
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        itemCount: _providers.length,
        separatorBuilder: (context, i) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final p = _providers[i];
          final selected = _selectedProvider?.id == p.id;
          return ChoiceChip(
            label: Text(p.name, style: const TextStyle(fontSize: 13)),
            selected: selected,
            selectedColor: AppColors.primary,
            backgroundColor: Colors.white,
            labelStyle: TextStyle(
              color: selected ? Colors.white : Colors.black87,
              fontWeight: FontWeight.w600,
            ),
            onSelected: (_) {
              if (selected) return;
              setState(() => _selectedProvider = p);
              _loadDoctors(p.id);
            },
          );
        },
      ),
    );
  }

  Widget _buildDoctorsList(BuildContext context, List<DoctorSummary> doctors) {
    if (_loadingDoctors) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }
    if (_doctorError != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_doctorError!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => _selectedProvider != null ? _loadDoctors(_selectedProvider!.id) : _loadProviders(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    if (_providers.isEmpty && !_loadingProviders) {
      return const Center(
        child: Text(
          'No health providers available yet.',
          style: TextStyle(color: Colors.grey, fontSize: 15),
          textAlign: TextAlign.center,
        ),
      );
    }
    if (doctors.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.person_search_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isNotEmpty ? 'No doctors match your search' : 'No doctors found',
              style: TextStyle(color: Colors.grey[600], fontSize: 15),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      itemCount: doctors.length,
      itemBuilder: (context, index) {
        final doc = doctors[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 2,
          child: InkWell(
            onTap: () => _showDoctorDetails(doc),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 25,
                    backgroundColor: AppColors.primary,
                    foregroundImage: doc.photoUrl != null && doc.photoUrl!.isNotEmpty
                        ? NetworkImage(doc.photoUrl!)
                        : null,
                    child: const Icon(Icons.person, color: Colors.white),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(doc.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 4),
                        Text(
                          doc.specialization ?? '',
                          style: const TextStyle(fontSize: 13, color: Colors.black54),
                        ),
                        if (doc.location != null) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.location_on, size: 14, color: Colors.grey),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  doc.location!,
                                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.chevron_right_rounded, color: Colors.grey),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAppointmentsTab(BuildContext context) {
    if (_loadingAppointments && _appointments.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }
    if (_appointmentError != null && _appointments.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_appointmentError!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: _fetchAppointments, child: const Text('Retry')),
          ],
        ),
      );
    }
    if (_appointments.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.event_available_outlined, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text('No appointments yet', style: TextStyle(color: Colors.grey[600], fontSize: 16)),
              const SizedBox(height: 8),
              Text(
                'Book an appointment from the Find Doctor tab.',
                style: TextStyle(color: Colors.grey[500], fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _fetchAppointments,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _appointments.length,
        itemBuilder: (context, index) {
          final a = _appointments[index];
          final appointmentId = (a['id'] ?? '').toString();
          final doctorName = (a['doctor_name'] as String?) ?? 'Doctor';
          final specialization = (a['specialization'] as String?) ?? '';
          final status = (a['status'] as String?) ?? '';
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 2,
            child: InkWell(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AppointmentDetailsPage(appointmentId: appointmentId),
                ),
              ),
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 24,
                      backgroundColor: AppColors.primary,
                      child: Icon(Icons.medical_services, color: Colors.white),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(doctorName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          if (specialization.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(specialization, style: const TextStyle(fontSize: 12, color: Colors.black54)),
                          ],
                          const SizedBox(height: 4),
                          Text(
                            _formatSlot(a['slot_datetime'] as String?),
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    _statusChip(status),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Doctor details bottom sheet ────────────────────────────────────────
class _DoctorDetailSheet extends StatefulWidget {
  final DoctorSummary doc;
  final VoidCallback? onBook;

  const _DoctorDetailSheet({required this.doc, this.onBook});

  @override
  State<_DoctorDetailSheet> createState() => _DoctorDetailSheetState();
}

class _DoctorDetailSheetState extends State<_DoctorDetailSheet> {
  Map<String, dynamic>? _profile;
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
      final profile = await DoctorService.getDoctorPublicProfile(widget.doc.id);
      if (!mounted) return;
      setState(() => _profile = profile);
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

  String _formatWorkingHours(dynamic wh) {
    if (wh == null) return '';
    if (wh is String) return wh;
    if (wh is Map) {
      final parts = <String>[];
      wh.forEach((key, value) => parts.add('$key: $value'));
      return parts.join(', ');
    }
    if (wh is List) return wh.join(', ');
    return wh.toString();
  }

  @override
  Widget build(BuildContext context) {
    final doc = widget.doc;
    final profile = _profile;
    final workingHours = _formatWorkingHours(profile?['working_hours_json']);
    final hospital =
        (profile?['hospital_name'] as String?) ?? doc.location;
    final email = profile?['email'] as String?;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        top: 24,
        left: 24,
        right: 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: AppColors.primary,
                  foregroundImage: doc.photoUrl != null && doc.photoUrl!.isNotEmpty
                      ? NetworkImage(doc.photoUrl!)
                      : null,
                  child: const Icon(Icons.medical_services, color: Colors.white, size: 30),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(doc.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      Text(
                        doc.specialization ?? 'General Practitioner',
                        style: const TextStyle(color: Colors.black54),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (hospital != null && hospital.isNotEmpty)
              _buildDetailRow(Icons.location_on, 'Location', hospital),
            if (doc.phone != null && doc.phone!.isNotEmpty)
              _buildDetailRow(Icons.phone, 'Phone', doc.phone!),
            if (email != null && email.isNotEmpty)
              _buildDetailRow(Icons.email_outlined, 'Email', email),
            if (workingHours.isNotEmpty)
              _buildDetailRow(Icons.access_time, 'Working Hours', workingHours),
            if (doc.bio != null && doc.bio!.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text('About', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              Text(doc.bio!, style: const TextStyle(color: Colors.black87, height: 1.4)),
            ],
            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                    ),
                    SizedBox(width: 10),
                    Text('Loading profile...', style: TextStyle(fontSize: 13, color: Colors.grey)),
                  ],
                ),
              ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 13))),
                  TextButton(onPressed: _load, child: const Text('Retry')),
                ],
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: widget.onBook,
                icon: const Icon(Icons.event_available_rounded, color: Colors.white),
                label: const Text('Book Appointment', style: TextStyle(color: Colors.white, fontSize: 16)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            if (widget.onBook == null) const SizedBox(height: 8),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.black54, fontSize: 12)),
                const SizedBox(height: 4),
                Text(value, style: const TextStyle(fontSize: 15)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Booking bottom sheet ───────────────────────────────────────────────
class _SlotOption {
  final DateTime nextOccurrence;
  final String label;
  final String dateLabel;

  _SlotOption({required this.nextOccurrence, required this.label, required this.dateLabel});
}

class _BookingSheet extends StatefulWidget {
  final String doctorId;
  final String doctorName;
  final void Function(String appointmentId)? onBooked;

  const _BookingSheet({
    required this.doctorId,
    required this.doctorName,
    this.onBooked,
  });

  @override
  State<_BookingSheet> createState() => _BookingSheetState();
}

class _BookingSheetState extends State<_BookingSheet> {
  List<_SlotOption> _options = [];
  bool _loading = true;
  String? _error;
  _SlotOption? _selected;
  bool _submitting = false;

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
      final slots = await DoctorService.getAvailabilitySlots(widget.doctorId);
      if (!mounted) return;
      setState(() => _options = _buildSlotOptions(slots));
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

  List<_SlotOption> _buildSlotOptions(List<dynamic> slots) {
    const dayNames = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final now = DateTime.now();
    final options = <_SlotOption>[];

    for (final s in slots) {
      final dayOfWeek = s['day_of_week'] as int?;
      final start = _parseTime(s['start_time']);
      final end = _parseTime(s['end_time']);
      if (dayOfWeek == null || start == null || end == null) continue;
      final duration = (s['slot_duration_minutes'] as int?) ?? 30;
      if (duration <= 0) continue;

      for (var m = start.$1; m < end.$1; m += duration) {
        final dt = _nextOccurrence(now, dayOfWeek, m);
        final period = dt.hour >= 12 ? 'PM' : 'AM';
        final h = (dt.hour % 12 == 0 ? 12 : dt.hour % 12);
        final timeLabel = '$h:${dt.minute.toString().padLeft(2, '0')} $period';
        final dateLabel = '${dayNames[dayOfWeek]}, ${months[dt.month - 1]} ${dt.day}, ${dt.year}';
        options.add(
          _SlotOption(
            nextOccurrence: dt,
            label: timeLabel,
            dateLabel: dateLabel,
          ),
        );
      }
    }
    options.sort((a, b) => a.nextOccurrence.compareTo(b.nextOccurrence));
    return options;
  }

  (int, int)? _parseTime(dynamic value) {
    if (value == null) return null;
    final parts = value.toString().split(':');
    if (parts.length < 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return null;
    return (h, m);
  }

  DateTime _nextOccurrence(DateTime now, int dayOfWeek, int minuteOfDay) {
    // dayOfWeek: 0 (Sun) - 6 (Sat). Dart weekday: 1 (Mon) - 7 (Sun).
    final target = dayOfWeek == 0 ? 7 : dayOfWeek;
    var delta = target - now.weekday;
    if (delta < 0) delta += 7;
    var candidate = DateTime(
      now.year,
      now.month,
      now.day + delta,
      minuteOfDay ~/ 60,
      minuteOfDay % 60,
    );
    if (!candidate.isAfter(now)) {
      candidate = candidate.add(const Duration(days: 7));
    }
    return candidate;
  }

  Future<void> _confirm() async {
    final option = _selected;
    if (option == null || _submitting) return;
    setState(() => _submitting = true);
    try {
      final appointment = await DoctorService.bookAppointment(
        doctorId: widget.doctorId,
        slotDatetime: option.nextOccurrence.toUtc().toIso8601String(),
      );
      final appointmentId = appointment['id'].toString();
      await DoctorService.saveAppointmentId(appointmentId);
      if (!mounted) return;
      widget.onBooked?.call(appointmentId);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Network error. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        top: 24,
        left: 24,
        right: 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Book Appointment',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            Text(
              widget.doctorName,
              style: const TextStyle(color: Colors.black54, fontSize: 14),
            ),
            const SizedBox(height: 16),
            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
              )
            else if (_error != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Column(
                  children: [
                    Text(_error!, style: const TextStyle(color: Colors.red)),
                    const SizedBox(height: 12),
                    OutlinedButton(onPressed: _load, child: const Text('Retry')),
                  ],
                ),
              )
            else if (_options.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text(
                    'No available slots yet. Please try again later.',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            else ...[
              const Text('Select a time slot', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 12),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _options.length,
                itemBuilder: (context, index) {
                  final option = _options[index];
                  final selected = _selected?.nextOccurrence == option.nextOccurrence;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: InkWell(
                      onTap: () => setState(() => _selected = option),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: selected ? AppColors.primary.withOpacity(0.1) : Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: selected ? AppColors.primary : Colors.grey[300]!,
                            width: selected ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              selected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                              color: selected ? AppColors.primary : Colors.grey[400],
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(option.label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                                  const SizedBox(height: 2),
                                  Text(
                                    option.dateLabel,
                                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _selected == null || _submitting ? null : _confirm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _submitting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Confirm Booking', style: TextStyle(color: Colors.white, fontSize: 16)),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
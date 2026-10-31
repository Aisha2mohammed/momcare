import 'package:flutter/material.dart';
import 'package:doctor_app/constants/color.dart';
import 'package:doctor_app/model/mock_data.dart';
import 'package:doctor_app/model/doctor_profile_model.dart';
import 'package:doctor_app/widget/doctor_header_widget.dart';
import 'package:doctor_app/widget/today_appointments_widget.dart';
import 'package:doctor_app/widget/patient_risk_card_widget.dart';
import 'package:doctor_app/widget/broadcast_notification_dialog.dart';
import 'package:doctor_app/widget/status_modal.dart';
import 'package:doctor_app/chat/chat_detail_screen.dart';
import 'package:doctor_app/profile/profile_tab.dart';

enum HomeFilterTab {
  all,
  pendingRequests,
  highRisk,
  moderateRisk,
  stable,
  accepted,
  rejected,
}

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  final TextEditingController _searchController = TextEditingController();
  HomeFilterTab _selectedTab = HomeFilterTab.all;
  String _searchQuery = '';

  List<PatientModel> get _allPatients {
    final list = List<PatientModel>.from(MockData.incomingPatients);
    list.sort(PatientModel.compareByRisk);
    return list;
  }

  List<AppointmentModel> get _todayAppointments => MockData.todayAppointments;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });

    // Listen to real-time profile and availability changes
    MockData.doctorAvailabilityNotifier.addListener(_onAvailabilityChanged);
    DoctorProfileModel.shared.addListener(_onAvailabilityChanged);
  }

  void _onAvailabilityChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    MockData.doctorAvailabilityNotifier.removeListener(_onAvailabilityChanged);
    DoctorProfileModel.shared.removeListener(_onAvailabilityChanged);
    _searchController.dispose();
    super.dispose();
  }

  // Filtered patients based on search and selected tab
  List<PatientModel> get _filteredPatients {
    return _allPatients.where((patient) {
      // 1. Tab filter
      bool matchesTab = true;
      switch (_selectedTab) {
        case HomeFilterTab.all:
          matchesTab = true;
          break;
        case HomeFilterTab.pendingRequests:
          matchesTab = !patient.isAccepted && !patient.isRejected;
          break;
        case HomeFilterTab.highRisk:
          matchesTab = patient.riskLevel == RiskLevel.high;
          break;
        case HomeFilterTab.moderateRisk:
          matchesTab = patient.riskLevel == RiskLevel.moderate;
          break;
        case HomeFilterTab.stable:
          matchesTab = patient.riskLevel == RiskLevel.stable;
          break;
        case HomeFilterTab.accepted:
          matchesTab = patient.isAccepted;
          break;
        case HomeFilterTab.rejected:
          matchesTab = patient.isRejected;
          break;
      }
      if (!matchesTab) return false;

      // 2. Search query filter (Patient Name or Phone Number)
      if (_searchQuery.isEmpty) return true;
      final nameMatches = patient.name.toLowerCase().contains(_searchQuery);
      final phoneMatches = patient.phone.toLowerCase().contains(_searchQuery);
      final symptomMatches = patient.recentFlaggedSymptom.toLowerCase().contains(_searchQuery);
      return nameMatches || phoneMatches || symptomMatches;
    }).toList();
  }

  int _countForTab(HomeFilterTab tab) {
    switch (tab) {
      case HomeFilterTab.all:
        return _allPatients.length;
      case HomeFilterTab.pendingRequests:
        return _allPatients.where((p) => !p.isAccepted && !p.isRejected).length;
      case HomeFilterTab.highRisk:
        return _allPatients.where((p) => p.riskLevel == RiskLevel.high).length;
      case HomeFilterTab.moderateRisk:
        return _allPatients.where((p) => p.riskLevel == RiskLevel.moderate).length;
      case HomeFilterTab.stable:
        return _allPatients.where((p) => p.riskLevel == RiskLevel.stable).length;
      case HomeFilterTab.accepted:
        return _allPatients.where((p) => p.isAccepted).length;
      case HomeFilterTab.rejected:
        return _allPatients.where((p) => p.isRejected).length;
    }
  }

  void _acceptAppointment(AppointmentModel appt) {
    setState(() {
      appt.status = AppointmentStatus.confirmed;
    });
    AppModals.showSuccess(
      context,
      title: 'Appointment Confirmed',
      message:
          'Consultation with ${appt.patientName} scheduled for ${appt.timeSlot} has been accepted and added to your clinic roster.',
      primaryButtonText: 'Great, Continue',
    );
  }

  void _rejectAppointment(AppointmentModel appt) {
    AppModals.showFail(
      context,
      title: 'Reject Appointment?',
      message: 'Are you sure you want to decline ${appt.patientName}\'s appointment request for ${appt.timeSlot}?',
      primaryButtonText: 'Confirm Decline',
      secondaryButtonText: 'Keep Pending',
      onRetry: () {
        setState(() {
          appt.status = AppointmentStatus.rejected;
          _todayAppointments.removeWhere((a) => a.id == appt.id);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Appointment for ${appt.patientName} declined')),
        );
      },
    );
  }

  void _rescheduleAppointment(AppointmentModel appt) {
    showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    ).then((selectedTime) {
      if (selectedTime != null && mounted) {
        final formattedTime = selectedTime.format(context);
        setState(() {
          appt.status = AppointmentStatus.confirmed;
        });
        AppModals.showSuccess(
          context,
          title: 'Reschedule Sent',
          message: 'Appointment for ${appt.patientName} has been rescheduled to $formattedTime.',
          primaryButtonText: 'Done',
        );
      }
    });
  }

  void _acceptPatient(PatientModel patient) {
    setState(() {
      patient.isAccepted = true;
      patient.isRejected = false;
      if (!MockData.acceptedPatients.any((p) => p.id == patient.id)) {
        MockData.acceptedPatients.insert(0, patient);
      }
      MockData.rejectedPatients.removeWhere((p) => p.id == patient.id);
    });

    AppModals.showSuccess(
      context,
      title: 'Patient Accepted!',
      message: '${patient.name} has been enrolled in your care team. Chat channel is now active.',
      primaryButtonText: 'Open Chat',
      secondaryButtonText: 'Done',
      onConfirm: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ChatDetailScreen(patient: patient)),
        );
      },
    );
  }

  void _rejectPatient(PatientModel patient) {
    AppModals.showFail(
      context,
      title: 'Decline Patient Referral?',
      message:
          'Are you sure you want to decline intake for ${patient.name} (${patient.gestationalAge})? The mother will be notified to rebook or consult an affiliate.',
      primaryButtonText: 'Decline Intake',
      secondaryButtonText: 'Keep Pending',
      onRetry: () {
        setState(() {
          patient.isAccepted = false;
          patient.isRejected = true;
          if (!MockData.rejectedPatients.any((p) => p.id == patient.id)) {
            MockData.rejectedPatients.insert(0, patient);
          }
          MockData.acceptedPatients.removeWhere((p) => p.id == patient.id);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${patient.name}\'s intake referral declined'),
            backgroundColor: AppColors.riskHigh,
          ),
        );
      },
    );
  }

  void _redirectToProfileAvailability() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(22),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 16),
            const Icon(Icons.tune_rounded, color: AppColors.primary, size: 36),
            const SizedBox(height: 12),
            const Text(
              'Doctor Availability & Schedule',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 6),
            Text(
              'Your status is currently ${MockData.currentDoctorAvailability.label}. Manage your weekly shifts, booking capacity, and global duty toggle in your Doctor Profile.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ProfileTab()),
                  );
                },
                icon: const Icon(Icons.settings_outlined, size: 18),
                label: const Text('Open Availability & Schedule Settings', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBarWidget() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(fontSize: 13),
        decoration: InputDecoration(
          hintText: 'Search patient by name or phone...',
          hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade500),
          prefixIcon: const Icon(Icons.search, color: AppColors.primary, size: 20),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: () => _searchController.clear(),
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredList = _filteredPatients;
    final totalPatientsCount = _allPatients.length;
    final pendingApptsCount = _todayAppointments.where((a) => a.isPending).length;
    final highRiskCount = _countForTab(HomeFilterTab.highRisk);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // 1. Doctor Header Section Widget (with Search Bar placed ABOVE the 3 Cards)
          SliverToBoxAdapter(
            child: DoctorHeaderWidget(
              doctorName: DoctorProfileModel.shared.name,
              specialty: DoctorProfileModel.shared.specialization,
              avatarUrl: DoctorProfileModel.shared.avatarUrl,
              availability: DoctorProfileModel.shared.availability,
              onAvailabilityTapped: _redirectToProfileAvailability,
              searchBar: _buildSearchBarWidget(),
              totalPatients: totalPatientsCount,
              pendingAppointments: pendingApptsCount,
              highRiskAlerts: highRiskCount,
              onPatientsTapped: () => setState(() => _selectedTab = HomeFilterTab.all),
              onPendingTapped: () => setState(() => _selectedTab = HomeFilterTab.pendingRequests),
              onHighRiskTapped: () => setState(() => _selectedTab = HomeFilterTab.highRisk),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 16)),

          // 2. Today's Appointments Quick Section
          SliverToBoxAdapter(
            child: TodayAppointmentsWidget(
              appointments: _todayAppointments,
              onAccept: _acceptAppointment,
              onReject: _rejectAppointment,
              onReschedule: _rescheduleAppointment,
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 16)),

          // 3. Tab Filter Bar
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Section Title Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Patient Risk Registry",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.swap_vert_rounded, size: 14, color: AppColors.primary),
                          const SizedBox(width: 4),
                          Text(
                            "Sorted by Risk",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Filter Chips / Segmented Tabs
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: [
                        _buildFilterTabChip(
                          tab: HomeFilterTab.all,
                          label: 'All Patients',
                          count: _countForTab(HomeFilterTab.all),
                        ),
                        const SizedBox(width: 8),
                        _buildFilterTabChip(
                          tab: HomeFilterTab.pendingRequests,
                          label: 'Pending',
                          count: _countForTab(HomeFilterTab.pendingRequests),
                          activeColor: const Color(0xFF2563EB),
                        ),
                        const SizedBox(width: 8),
                        _buildFilterTabChip(
                          tab: HomeFilterTab.highRisk,
                          label: 'High Risk',
                          count: _countForTab(HomeFilterTab.highRisk),
                          activeColor: AppColors.riskHigh,
                        ),
                        const SizedBox(width: 8),
                        _buildFilterTabChip(
                          tab: HomeFilterTab.moderateRisk,
                          label: 'Moderate Risk',
                          count: _countForTab(HomeFilterTab.moderateRisk),
                          activeColor: AppColors.riskModerate,
                        ),
                        const SizedBox(width: 8),
                        _buildFilterTabChip(
                          tab: HomeFilterTab.stable,
                          label: 'Stable',
                          count: _countForTab(HomeFilterTab.stable),
                          activeColor: AppColors.riskStable,
                        ),
                        const SizedBox(width: 8),
                        _buildFilterTabChip(
                          tab: HomeFilterTab.accepted,
                          label: 'Accepted',
                          count: _countForTab(HomeFilterTab.accepted),
                          activeColor: AppColors.success,
                        ),
                        const SizedBox(width: 8),
                        _buildFilterTabChip(
                          tab: HomeFilterTab.rejected,
                          label: 'Declined',
                          count: _countForTab(HomeFilterTab.rejected),
                          activeColor: Colors.red.shade700,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 14)),

          // 4. Main Patient Cards List Sorted by Risk
          if (filteredList.isEmpty)
            SliverToBoxAdapter(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: const BoxDecoration(
                          color: AppColors.primaryLight,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.person_search_rounded,
                          size: 44,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        _searchQuery.isNotEmpty
                            ? 'No patients match "$_searchQuery"'
                            : 'No patients found under this category',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _searchQuery.isNotEmpty
                            ? 'Check spelling or clear the search query to see all patients.'
                            : 'Select another filter tab or triage new patient referrals.',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final patient = filteredList[index];
                    return PatientRiskCardWidget(
                      key: ValueKey(patient.id),
                      patient: patient,
                      onAccept: _acceptPatient,
                      onDecline: _rejectPatient,
                    );
                  },
                  childCount: filteredList.length,
                ),
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),

      // 5. Floating Action Button: Send Push Notification (Broadcast)
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 4,
        onPressed: () {
          BroadcastNotificationDialog.show(context);
        },
        icon: const Icon(Icons.campaign_rounded, size: 22),
        label: const Text(
          'Send Push Notification',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
      ),
    );
  }

  Widget _buildFilterTabChip({
    required HomeFilterTab tab,
    required String label,
    required int count,
    Color? activeColor,
  }) {
    final isSelected = _selectedTab == tab;
    final effectiveColor = activeColor ?? AppColors.primary;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedTab = tab;
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? effectiveColor : AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? effectiveColor : Colors.grey.shade300,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: effectiveColor.withValues(alpha: 0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: isSelected ? Colors.white : AppColors.textPrimary,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white.withValues(alpha: 0.25) : Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : effectiveColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

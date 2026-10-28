import 'package:flutter/material.dart';
import 'package:doctor_app/constants/color.dart';
import 'package:doctor_app/model/mock_data.dart';
import 'package:doctor_app/widget/status_modal.dart';
import 'package:doctor_app/chat/chat_detail_screen.dart';
import 'package:doctor_app/appointment/widgets/appointment_card.dart';
import 'package:doctor_app/appointment/widgets/appointment_filter_bar.dart';
import 'package:doctor_app/appointment/widgets/suggest_alternative_modal.dart';
import 'package:doctor_app/appointment/widgets/completed_session_modal.dart';
import 'package:intl/intl.dart';

class AppointmentTab extends StatefulWidget {
  const AppointmentTab({super.key});

  @override
  State<AppointmentTab> createState() => _AppointmentTabState();
}

class _AppointmentTabState extends State<AppointmentTab> {
  int _selectedTab = 0; // 0: Pending, 1: Upcoming, 2: Completed, 3: Cancelled
  DateTime? _selectedDate;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<AppointmentModel> get _allAppointments => MockData.allAppointments;

  Map<int, int> get _tabCounts {
    int pending = 0;
    int upcoming = 0;
    int completed = 0;
    int cancelled = 0;

    for (final a in _allAppointments) {
      if (a.isPending) {
        pending++;
      } else if (a.isUpcoming) {
        upcoming++;
      } else if (a.isCompleted) {
        completed++;
      } else if (a.isCancelled) {
        cancelled++;
      }
    }

    return {
      0: pending,
      1: upcoming,
      2: completed,
      3: cancelled,
    };
  }

  Set<String> get _appointmentDates {
    final set = <String>{};
    for (final a in _allAppointments) {
      set.add(DateFormat('yyyy-MM-dd').format(a.dateTime));
    }
    return set;
  }

  List<AppointmentModel> get _filteredAppointments {
    return _allAppointments.where((appt) {
      // 1. Status Filter
      bool statusMatch = false;
      switch (_selectedTab) {
        case 0:
          statusMatch = appt.isPending;
          break;
        case 1:
          statusMatch = appt.isUpcoming;
          break;
        case 2:
          statusMatch = appt.isCompleted;
          break;
        case 3:
          statusMatch = appt.isCancelled;
          break;
      }
      if (!statusMatch) return false;

      // 2. Date Filter
      if (_selectedDate != null) {
        if (!DateUtils.isSameDay(appt.dateTime, _selectedDate!)) {
          return false;
        }
      }

      // 3. Search Filter
      if (_searchQuery.trim().isNotEmpty) {
        final query = _searchQuery.toLowerCase().trim();
        final nameMatch = appt.patientName.toLowerCase().contains(query);
        final typeMatch = appt.type.toLowerCase().contains(query);
        final descMatch = appt.description.toLowerCase().contains(query);
        if (!nameMatch && !typeMatch && !descMatch) return false;
      }

      return true;
    }).toList();
  }

  void _handleAccept(AppointmentModel appt) {
    setState(() {
      appt.status = AppointmentStatus.confirmed;
    });

    AppModals.showSuccess(
      context,
      title: 'Appointment Confirmed!',
      message:
          'Consultation with ${appt.patientName} (${appt.timeSlot}) is confirmed. A push alert was dispatched to the mother.',
      primaryButtonText: 'Start Consultation',
      secondaryButtonText: 'Done',
      onConfirm: () => _handleStartConsultation(appt),
    );
  }

  void _handleRejectSuggest(AppointmentModel appt) {
    SuggestAlternativeModal.show(
      context,
      appointment: appt,
      onConfirm: (reason, alternativeSlots, message) {
        setState(() {
          appt.status = AppointmentStatus.rejected;
          appt.rejectionReason = reason;
          appt.suggestedAlternativeSlots = alternativeSlots;
          appt.doctorNote = message;
        });

        AppModals.showSuccess(
          context,
          title: 'Alternative Slots Sent!',
          message:
              'Proposed ${alternativeSlots.join(' & ')} to ${appt.patientName}. Patient received notification to rebook.',
          primaryButtonText: 'View Cancelled',
          secondaryButtonText: 'Dismiss',
          onConfirm: () {
            setState(() {
              _selectedTab = 3; // Switch to Cancelled / Rejected tab
            });
          },
        );
      },
    );
  }

  void _handleStartConsultation(AppointmentModel appt) {
    // Find matching patient or build from appointment
    PatientModel? patient;
    for (final p in MockData.acceptedPatients) {
      if (p.id == appt.patientId || p.name == appt.patientName) {
        patient = p;
        break;
      }
    }
    if (patient == null) {
      for (final p in MockData.incomingPatients) {
        if (p.id == appt.patientId || p.name == appt.patientName) {
          patient = p;
          break;
        }
      }
    }

    patient ??= PatientModel(
      id: appt.patientId,
      name: appt.patientName,
      phone: '+1 (555) 000-1122',
      imageUrl: appt.patientAvatar,
      gestationalAge: appt.gestationalAge,
      riskLevel: appt.riskLevel,
      recentFlaggedSymptom: appt.type,
      lastActivityTime: 'Booked today',
      condition: appt.description,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatDetailScreen(patient: patient!),
      ),
    );
  }

  void _handleReschedule(AppointmentModel appt) async {
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: appt.dateTime.isAfter(now) ? appt.dateTime : now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 90)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null && mounted) {
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(appt.dateTime),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.light(
                primary: AppColors.primary,
                onPrimary: Colors.white,
                onSurface: AppColors.textPrimary,
              ),
            ),
            child: child!,
          );
        },
      );

      if (pickedTime != null && mounted) {
        final newDateTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );
        final newSlotStr = DateFormat('hh:mm a').format(newDateTime);

        setState(() {
          appt.dateTime = newDateTime;
          appt.status = AppointmentStatus.rescheduled;
        });

        AppModals.showSuccess(
          context,
          title: 'Rescheduled Successfully',
          message:
              'Appointment with ${appt.patientName} moved to ${DateFormat('MMM dd').format(newDateTime)} at $newSlotStr.',
          primaryButtonText: 'Done',
        );
      }
    }
  }

  void _handleViewNotes(AppointmentModel appt) {
    CompletedSessionModal.show(context, appointment: appt);
  }

  void _pickCustomDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: now.subtract(const Duration(days: 30)),
      lastDate: now.add(const Duration(days: 90)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredList = _filteredAppointments;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // 1. Top Screen Title Header
            Padding(
              padding: const EdgeInsets.only(left: 20, right: 20, top: 16, bottom: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.calendar_month_rounded,
                          color: AppColors.primary,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Appointments & Requests',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            'MomCare Provider Clinical Schedule',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  // Clear Filters if date active
                  if (_selectedDate != null)
                    TextButton.icon(
                      onPressed: () => setState(() => _selectedDate = null),
                      icon: const Icon(Icons.clear_rounded, size: 14, color: AppColors.primary),
                      label: const Text(
                        'Clear Date',
                        style: TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.bold),
                      ),
                    ),
                ],
              ),
            ),

            // 2. Search Field
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) => setState(() => _searchQuery = val),
                  style: const TextStyle(fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Search appointments by patient name or reason...',
                    hintStyle: const TextStyle(fontSize: 13, color: Colors.grey),
                    prefixIcon: const Icon(Icons.search, color: AppColors.primary, size: 20),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close, size: 18, color: Colors.grey),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // 3. Status Tabs & Calendar Strip Filter Bar
            AppointmentFilterBar(
              selectedTab: _selectedTab,
              onTabSelected: (tab) => setState(() => _selectedTab = tab),
              tabCounts: _tabCounts,
              selectedDate: _selectedDate,
              onDateSelected: (date) => setState(() => _selectedDate = date),
              onPickCustomDate: _pickCustomDate,
              appointmentDates: _appointmentDates,
            ),
            const SizedBox(height: 10),

            // 4. Appointments List Section
            Expanded(
              child: filteredList.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      physics: const BouncingScrollPhysics(),
                      itemCount: filteredList.length,
                      itemBuilder: (context, index) {
                        final appt = filteredList[index];
                        return AppointmentCard(
                          appointment: appt,
                          onAccept: () => _handleAccept(appt),
                          onRejectSuggest: () => _handleRejectSuggest(appt),
                          onStartConsultation: () => _handleStartConsultation(appt),
                          onReschedule: () => _handleReschedule(appt),
                          onViewNotes: () => _handleViewNotes(appt),
                          onTap: () {
                            if (appt.isCompleted) {
                              _handleViewNotes(appt);
                            } else {
                              _handleStartConsultation(appt);
                            }
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    IconData emptyIcon;
    String title;
    String subtitle;

    switch (_selectedTab) {
      case 0:
        emptyIcon = Icons.inbox_outlined;
        title = 'No Pending Requests';
        subtitle = _selectedDate != null
            ? 'No pending appointment requests on ${DateFormat("MMM dd, yyyy").format(_selectedDate!)}.'
            : 'All patient consultation requests have been accepted or addressed.';
        break;
      case 1:
        emptyIcon = Icons.event_available_outlined;
        title = 'No Upcoming Appointments';
        subtitle = _selectedDate != null
            ? 'No confirmed consultations scheduled on this date.'
            : 'Your upcoming schedule is clear. Check pending requests.';
        break;
      case 2:
        emptyIcon = Icons.history_edu_outlined;
        title = 'No Completed Sessions';
        subtitle = 'Completed consultations with saved clinical notes will appear here.';
        break;
      case 3:
        emptyIcon = Icons.event_busy_outlined;
        title = 'No Cancelled / Rejected Appointments';
        subtitle = 'Declined requests with suggested alternative slots will be stored here.';
        break;
      default:
        emptyIcon = Icons.calendar_today_outlined;
        title = 'No Appointments Found';
        subtitle = 'Try adjusting your date or search filters.';
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primaryLight.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              child: Icon(emptyIcon, size: 48, color: AppColors.primary),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            if (_selectedDate != null || _searchQuery.isNotEmpty) ...[
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _selectedDate = null;
                    _searchQuery = '';
                    _searchController.clear();
                  });
                },
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('Reset Date & Search'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

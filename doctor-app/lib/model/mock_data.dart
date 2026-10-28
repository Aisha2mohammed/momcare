import 'package:flutter/material.dart';
import 'package:doctor_app/model/chat_message_model.dart';
export 'package:doctor_app/model/chat_message_model.dart';

enum RiskLevel {
  high,
  moderate,
  stable;

  // Aliases for compatibility
  static const RiskLevel medium = RiskLevel.moderate;
  static const RiskLevel low = RiskLevel.stable;
}

enum DoctorAvailability {
  online,
  away,
  offDuty;

  String get label {
    switch (this) {
      case DoctorAvailability.online:
        return 'Online';
      case DoctorAvailability.away:
        return 'Away';
      case DoctorAvailability.offDuty:
        return 'Off-Duty';
    }
  }

  Color get color {
    switch (this) {
      case DoctorAvailability.online:
        return const Color(0xFF10B981);
      case DoctorAvailability.away:
        return const Color(0xFFF59E0B);
      case DoctorAvailability.offDuty:
        return const Color(0xFF94A3B8);
    }
  }
}

enum AppointmentStatus {
  pending,
  confirmed,
  rescheduled,
  completed,
  rejected,
  cancelled;

  static const AppointmentStatus upcoming = AppointmentStatus.confirmed;

  bool get isPending => this == AppointmentStatus.pending;
  bool get isUpcoming => this == AppointmentStatus.confirmed || this == AppointmentStatus.rescheduled;
  bool get isCompleted => this == AppointmentStatus.completed;
  bool get isCancelledOrRejected => this == AppointmentStatus.rejected || this == AppointmentStatus.cancelled;
}

enum ConsultationType {
  inPerson,
  videoCall,
  emergencyTriage;

  String get label {
    switch (this) {
      case ConsultationType.inPerson:
        return 'In-Person Clinic Visit';
      case ConsultationType.videoCall:
        return 'Video Call';
      case ConsultationType.emergencyTriage:
        return 'Emergency Triage';
    }
  }

  IconData get icon {
    switch (this) {
      case ConsultationType.inPerson:
        return Icons.local_hospital_outlined;
      case ConsultationType.videoCall:
        return Icons.videocam_outlined;
      case ConsultationType.emergencyTriage:
        return Icons.warning_amber_rounded;
    }
  }

  Color get color {
    switch (this) {
      case ConsultationType.inPerson:
        return const Color(0xFF61183E);
      case ConsultationType.videoCall:
        return const Color(0xFF0284C7);
      case ConsultationType.emergencyTriage:
        return const Color(0xFFDC2626);
    }
  }
}

class PatientModel {
  final String id;
  final String name;
  final String phone;
  final String imageUrl;
  final String gestationalAge; // e.g. "Week 24"
  final RiskLevel riskLevel;
  final String recentFlaggedSymptom; // e.g. "Severe Headache (3x/week)"
  final String lastActivityTime; // e.g. "Logged 15m ago"
  final String condition;
  final String age;
  final int severityIndicator; // 1 to 5
  final int frequencyIndicator; // 1 to 5
  final bool isPendingRequest;
  bool isAccepted;
  bool isRejected;
  final List<String> symptoms;
  final Map<String, String> vitals;

  // Chat tracking
  int unreadCount;
  String? lastMessage;
  DateTime? lastMessageTime;
  bool isRead;

  PatientModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.imageUrl,
    required this.gestationalAge,
    required this.riskLevel,
    required this.recentFlaggedSymptom,
    required this.lastActivityTime,
    required this.condition,
    this.age = '28 yrs',
    this.severityIndicator = 3,
    this.frequencyIndicator = 3,
    this.isPendingRequest = false,
    this.isAccepted = false,
    this.isRejected = false,
    this.symptoms = const [],
    this.vitals = const {},
    this.unreadCount = 0,
    this.lastMessage,
    this.lastMessageTime,
    this.isRead = true,
  });

  /// Alias for backward compatibility
  String get gestationalWeek => gestationalAge;

  /// Composite Risk Indicator Score (1 to 25)
  int get riskScore => severityIndicator * frequencyIndicator;

  String get riskLabel {
    switch (riskLevel) {
      case RiskLevel.high:
        return 'High Risk';
      case RiskLevel.moderate:
        return 'Moderate Risk';
      case RiskLevel.stable:
        return 'Stable';
    }
  }

  /// Sort comparison: highest risk first (High -> Moderate -> Stable)
  static int compareByRisk(PatientModel a, PatientModel b) {
    const priority = {
      RiskLevel.high: 3,
      RiskLevel.moderate: 2,
      RiskLevel.stable: 1,
    };
    final pDiff = (priority[b.riskLevel] ?? 0).compareTo(priority[a.riskLevel] ?? 0);
    if (pDiff != 0) return pDiff;

    final scoreDiff = b.riskScore.compareTo(a.riskScore);
    if (scoreDiff != 0) return scoreDiff;

    final severityDiff = b.severityIndicator.compareTo(a.severityIndicator);
    if (severityDiff != 0) return severityDiff;

    final freqDiff = b.frequencyIndicator.compareTo(a.frequencyIndicator);
    if (freqDiff != 0) return freqDiff;

    return a.name.compareTo(b.name);
  }
}

typedef Patient = PatientModel;

class AppointmentModel {
  final String id;
  final String patientId;
  final String patientName;
  final String patientAvatar;
  final String gestationalAge;
  final String timeSlot;
  DateTime dateTime;
  final String type;
  final ConsultationType consultationType;
  final String description;
  final RiskLevel riskLevel;
  AppointmentStatus status;

  // Rejection / Alternative fields
  String? rejectionReason;
  List<String>? suggestedAlternativeSlots;
  String? doctorNote;

  // Completed session details
  String? clinicalNotesSummary;
  String? prescriptionsSummary;

  AppointmentModel({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.patientAvatar,
    required this.gestationalAge,
    required this.timeSlot,
    required this.dateTime,
    required this.type,
    this.consultationType = ConsultationType.inPerson,
    required this.description,
    this.riskLevel = RiskLevel.moderate,
    this.status = AppointmentStatus.pending,
    this.rejectionReason,
    this.suggestedAlternativeSlots,
    this.doctorNote,
    this.clinicalNotesSummary,
    this.prescriptionsSummary,
  });

  bool get isPending => status == AppointmentStatus.pending;
  bool get isConfirmed => status == AppointmentStatus.confirmed || status == AppointmentStatus.rescheduled;
  bool get isUpcoming => isConfirmed;
  bool get isCompleted => status == AppointmentStatus.completed;
  bool get isCancelled => status == AppointmentStatus.rejected || status == AppointmentStatus.cancelled;
}

typedef Appointment = AppointmentModel;

class ChatDetail {
  final String patientId;
  final List<Message> messages;

  ChatDetail({
    required this.patientId,
    required this.messages,
  });
}

class MockData {
  /// Reactive doctor availability status synchronized across Home and Profile
  static ValueNotifier<DoctorAvailability> doctorAvailabilityNotifier =
      ValueNotifier<DoctorAvailability>(DoctorAvailability.online);

  static DoctorAvailability get currentDoctorAvailability => doctorAvailabilityNotifier.value;
  static set currentDoctorAvailability(DoctorAvailability val) => doctorAvailabilityNotifier.value = val;

  /// Incoming patient triage queue - sorted by risk indicator
  static List<PatientModel> incomingPatients = [
    PatientModel(
      id: '1',
      name: 'Sarah Connor',
      phone: '+1 (555) 019-2831',
      imageUrl: 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=150',
      gestationalAge: 'Week 32',
      riskLevel: RiskLevel.high,
      recentFlaggedSymptom: 'Severe Headache (3x/week)',
      lastActivityTime: 'Logged 12m ago',
      condition: 'Pre-eclampsia & Severe Hypertension',
      age: '31 yrs',
      severityIndicator: 5,
      frequencyIndicator: 4,
      isPendingRequest: true,
      symptoms: ['BP 160/105', 'Blurred Vision', 'Persistent Frontal Headache'],
      vitals: {'BP': '160/105', 'FHR': '148 bpm', 'Weight': '+1.8 kg', 'O2': '98%'},
    ),
    PatientModel(
      id: '2',
      name: 'Jessica Alba',
      phone: '+1 (555) 482-9912',
      imageUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150',
      gestationalAge: 'Week 28',
      riskLevel: RiskLevel.high,
      recentFlaggedSymptom: 'Fasting Glucose Spike (178 mg/dL)',
      lastActivityTime: 'Logged 35m ago',
      condition: 'Gestational Diabetes Mellitus',
      age: '29 yrs',
      severityIndicator: 4,
      frequencyIndicator: 5,
      isPendingRequest: false,
      symptoms: ['Elevated Glucose', 'Extreme Thirst', 'Fatigue'],
      vitals: {'Glucose': '178 mg/dL', 'BP': '124/82', 'FHR': '142 bpm', 'Weight': '+0.5 kg'},
    ),
    PatientModel(
      id: '3',
      name: 'Maria Santos',
      phone: '+1 (555) 671-8823',
      imageUrl: 'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=150',
      gestationalAge: 'Week 30',
      riskLevel: RiskLevel.high,
      recentFlaggedSymptom: 'Preterm Uterine Tightening (4x/hour)',
      lastActivityTime: 'Logged 48m ago',
      condition: 'Threatened Preterm Contractions',
      age: '33 yrs',
      severityIndicator: 4,
      frequencyIndicator: 4,
      isPendingRequest: true,
      symptoms: ['Pelvic Pressure', 'Rhythmic Contractions', 'Lower Back Ache'],
      vitals: {'BP': '128/86', 'FHR': '152 bpm', 'Cervix': '3.2 cm', 'O2': '99%'},
    ),
    PatientModel(
      id: '4',
      name: 'Emily Rose',
      phone: '+1 (555) 392-4411',
      imageUrl: 'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?w=150',
      gestationalAge: 'Week 22',
      riskLevel: RiskLevel.moderate,
      recentFlaggedSymptom: 'Postural Dizziness & Low Iron',
      lastActivityTime: 'Logged 1h ago',
      condition: 'Orthostatic Dizziness & Mild Anemia',
      age: '26 yrs',
      severityIndicator: 3,
      frequencyIndicator: 3,
      isPendingRequest: false,
      symptoms: ['Hb 9.8 g/dL', 'Lightheadedness on Standing'],
      vitals: {'BP': '104/66', 'FHR': '138 bpm', 'Hb': '9.8 g/dL'},
    ),
    PatientModel(
      id: '5',
      name: 'Rachel Green',
      phone: '+1 (555) 881-2200',
      imageUrl: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=150',
      gestationalAge: 'Week 25',
      riskLevel: RiskLevel.moderate,
      recentFlaggedSymptom: 'Lumbar & Pelvic Girdle Pain',
      lastActivityTime: 'Logged 2h ago',
      condition: 'Pelvic Girdle Discomfort',
      age: '28 yrs',
      severityIndicator: 2,
      frequencyIndicator: 4,
      isPendingRequest: true,
      symptoms: ['Difficulty Walking', 'Sleep Disruption'],
      vitals: {'BP': '118/74', 'FHR': '140 bpm'},
    ),
    PatientModel(
      id: '6',
      name: 'Chloe Bennett',
      phone: '+1 (555) 773-1290',
      imageUrl: 'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=150',
      gestationalAge: 'Week 31',
      riskLevel: RiskLevel.moderate,
      recentFlaggedSymptom: 'Bilateral Ankle Swelling (Pitting +1)',
      lastActivityTime: 'Logged 3h ago',
      condition: 'Ankle Edema & Hydration Monitoring',
      age: '27 yrs',
      severityIndicator: 3,
      frequencyIndicator: 2,
      isPendingRequest: false,
      symptoms: ['Pitting Ankle Edema', 'Foot Heaviness'],
      vitals: {'BP': '126/80', 'FHR': '144 bpm'},
    ),
    PatientModel(
      id: '7',
      name: 'Diana Evans',
      phone: '+1 (555) 304-7711',
      imageUrl: 'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?w=150',
      gestationalAge: 'Week 20',
      riskLevel: RiskLevel.stable,
      recentFlaggedSymptom: 'Mild Back Ache (After Exercise)',
      lastActivityTime: 'Logged 4h ago',
      condition: 'Routine 2nd Trimester Wellness',
      age: '27 yrs',
      severityIndicator: 1,
      frequencyIndicator: 2,
      isPendingRequest: false,
      symptoms: ['Normal Fetal Movement Felt', 'Vitals Normal'],
      vitals: {'BP': '112/70', 'FHR': '136 bpm'},
    ),
    PatientModel(
      id: '8',
      name: 'Amanda Waller',
      phone: '+1 (555) 902-1134',
      imageUrl: 'https://images.unsplash.com/photo-1508214751196-bcfd4ca60f91?w=150',
      gestationalAge: 'Week 14',
      riskLevel: RiskLevel.stable,
      recentFlaggedSymptom: 'Morning Nausea Well Controlled',
      lastActivityTime: 'Logged Yesterday',
      condition: 'Early 2nd Trimester Transition',
      age: '34 yrs',
      severityIndicator: 1,
      frequencyIndicator: 1,
      isPendingRequest: false,
      symptoms: ['Stable Energy', 'Adequate Hydration'],
      vitals: {'BP': '116/72', 'FHR': '150 bpm'},
    ),
    PatientModel(
      id: '9',
      name: 'Clara Oswald',
      phone: '+1 (555) 123-9988',
      imageUrl: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=150',
      gestationalAge: 'Week 36',
      riskLevel: RiskLevel.stable,
      recentFlaggedSymptom: 'Normal Kick Count (12/2hrs)',
      lastActivityTime: 'Logged 2 days ago',
      condition: 'Term Birth Plan Review',
      age: '29 yrs',
      severityIndicator: 1,
      frequencyIndicator: 1,
      isPendingRequest: false,
      symptoms: ['Healthy Active Kicks', 'Prepared for Labor'],
      vitals: {'BP': '118/76', 'FHR': '140 bpm'},
    ),
  ];

  /// Active accepted patients for the Doctor
  static List<PatientModel> acceptedPatients = [
    PatientModel(
      id: '10',
      name: 'Diana Prince',
      phone: '+1 (555) 402-9901',
      imageUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150',
      gestationalAge: 'Week 34',
      riskLevel: RiskLevel.high,
      recentFlaggedSymptom: 'Post-Meal Glycemic Spike (168 mg/dL)',
      lastActivityTime: 'Logged 12m ago',
      condition: 'Gestational Diabetes & Glycemic Spikes',
      age: '32 yrs',
      severityIndicator: 5,
      frequencyIndicator: 4,
      isAccepted: true,
      unreadCount: 2,
      isRead: false,
      lastMessage: 'Doctor, my post-meal glucose spiked to 168 mg/dL. Should I adjust insulin?',
      lastMessageTime: DateTime.now().subtract(const Duration(minutes: 12)),
      vitals: {'Glucose': '168 mg/dL', 'BP': '128/84', 'FHR': '145 bpm'},
    ),
    PatientModel(
      id: '11',
      name: 'Natasha Romanoff',
      phone: '+1 (555) 512-8800',
      imageUrl: 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=150',
      gestationalAge: 'Week 27',
      riskLevel: RiskLevel.moderate,
      recentFlaggedSymptom: 'Fatigue & Low Serum Ferritin',
      lastActivityTime: 'Logged 1h ago',
      condition: 'Iron Deficiency & Dietary Adjustments',
      age: '30 yrs',
      severityIndicator: 3,
      frequencyIndicator: 3,
      isAccepted: true,
      unreadCount: 1,
      isRead: false,
      lastMessage: 'Should I take the iron supplements with orange juice or with meals?',
      lastMessageTime: DateTime.now().subtract(const Duration(hours: 1, minutes: 25)),
      vitals: {'Hb': '10.1 g/dL', 'BP': '114/72', 'FHR': '140 bpm'},
    ),
    PatientModel(
      id: '12',
      name: 'Chloe Bennett',
      phone: '+1 (555) 773-1290',
      imageUrl: 'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=150',
      gestationalAge: 'Week 31',
      riskLevel: RiskLevel.moderate,
      recentFlaggedSymptom: 'Bilateral Ankle Swelling',
      lastActivityTime: 'Logged 2h ago',
      condition: 'Bilateral Ankle Edema Monitoring',
      age: '27 yrs',
      severityIndicator: 4,
      frequencyIndicator: 2,
      isAccepted: true,
      unreadCount: 3,
      isRead: false,
      lastMessage: 'The swelling in my ankles feels tighter today after standing at work.',
      lastMessageTime: DateTime.now().subtract(const Duration(hours: 2, minutes: 40)),
      vitals: {'BP': '124/80', 'FHR': '142 bpm'},
    ),
    PatientModel(
      id: '13',
      name: 'Maya Lin',
      phone: '+1 (555) 609-3321',
      imageUrl: 'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?w=150',
      gestationalAge: 'Week 29',
      riskLevel: RiskLevel.high,
      recentFlaggedSymptom: 'Pelvic Heaviness on Exertion',
      lastActivityTime: 'Logged 5h ago',
      condition: 'Prior Cervical Insufficiency Care',
      age: '35 yrs',
      severityIndicator: 4,
      frequencyIndicator: 4,
      isAccepted: true,
      unreadCount: 0,
      isRead: true,
      lastMessage: 'Understood Dr. Smith, I am staying in bed rest. Thank you so much!',
      lastMessageTime: DateTime.now().subtract(const Duration(hours: 5)),
      vitals: {'Cervix': '3.1 cm', 'BP': '118/76', 'FHR': '146 bpm'},
    ),
    PatientModel(
      id: '14',
      name: 'Elena Rostova',
      phone: '+1 (555) 902-8822',
      imageUrl: 'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?w=150',
      gestationalAge: 'Week 20',
      riskLevel: RiskLevel.stable,
      recentFlaggedSymptom: 'Anatomy Scan Scheduled',
      lastActivityTime: 'Logged Yesterday',
      condition: 'Routine Ultrasound & Anatomy Scan',
      age: '28 yrs',
      severityIndicator: 2,
      frequencyIndicator: 1,
      isAccepted: true,
      unreadCount: 0,
      isRead: true,
      lastMessage: 'Confirmed appointment for the 20-week anatomy scan this Thursday.',
      lastMessageTime: DateTime.now().subtract(const Duration(days: 1)),
      vitals: {'BP': '112/68', 'FHR': '138 bpm'},
    ),
  ];

  /// Patients whose consultations/intake were declined or closed
  static List<PatientModel> rejectedPatients = [
    PatientModel(
      id: '20',
      name: 'Wanda Maximoff',
      phone: '+1 (555) 555-0199',
      imageUrl: 'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=150',
      gestationalAge: 'Week 31',
      riskLevel: RiskLevel.moderate,
      recentFlaggedSymptom: 'Request declined due to emergency surgery',
      lastActivityTime: 'Declined Yesterday',
      condition: 'Emergency C-Section schedule conflict',
      age: '30 yrs',
      severityIndicator: 3,
      frequencyIndicator: 3,
      isPendingRequest: false,
      isAccepted: false,
      isRejected: true,
      lastMessage: 'Alternative consultation slots were offered. Pending patient rebooking.',
      lastMessageTime: DateTime.now().subtract(const Duration(days: 1)),
      unreadCount: 0,
      isRead: true,
    ),
    PatientModel(
      id: '21',
      name: 'Carol Danvers',
      phone: '+1 (555) 777-3311',
      imageUrl: 'https://images.unsplash.com/photo-1508214751196-bcfd4ca60f91?w=150',
      gestationalAge: 'Week 24',
      riskLevel: RiskLevel.stable,
      recentFlaggedSymptom: 'Referral re-routed to Clinic B',
      lastActivityTime: 'Declined 2d ago',
      condition: 'Requested out-of-region specialist',
      age: '32 yrs',
      severityIndicator: 1,
      frequencyIndicator: 1,
      isPendingRequest: false,
      isAccepted: false,
      isRejected: true,
      lastMessage: 'Patient advised to re-schedule at nearest regional affiliate.',
      lastMessageTime: DateTime.now().subtract(const Duration(days: 2)),
      unreadCount: 0,
      isRead: true,
    ),
  ];

  /// All system appointments across statuses
  static List<AppointmentModel> allAppointments = [
    AppointmentModel(
      id: 'apt-1',
      patientId: '1',
      patientName: 'Sarah Connor',
      patientAvatar: 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=150',
      gestationalAge: 'Week 32',
      timeSlot: '09:30 AM',
      dateTime: DateTime.now().add(const Duration(hours: 1)),
      type: 'Urgent Pre-eclampsia & BP Triage',
      consultationType: ConsultationType.emergencyTriage,
      description: 'Review blood pressure spike (160/105) and urine protein lab test',
      riskLevel: RiskLevel.high,
      status: AppointmentStatus.pending,
    ),
    AppointmentModel(
      id: 'apt-2',
      patientId: '2',
      patientName: 'Jessica Alba',
      patientAvatar: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150',
      gestationalAge: 'Week 28',
      timeSlot: '11:15 AM',
      dateTime: DateTime.now().add(const Duration(hours: 2, minutes: 45)),
      type: 'Glucose Tolerance & Insulin Review',
      consultationType: ConsultationType.videoCall,
      description: 'Adjust meal insulin dosage following 178 mg/dL fasting spike',
      riskLevel: RiskLevel.high,
      status: AppointmentStatus.pending,
    ),
    AppointmentModel(
      id: 'apt-3',
      patientId: '4',
      patientName: 'Emily Rose',
      patientAvatar: 'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?w=150',
      gestationalAge: 'Week 22',
      timeSlot: '02:00 PM',
      dateTime: DateTime.now().add(const Duration(hours: 5, minutes: 30)),
      type: 'Anemia & Nutrition Consultation',
      consultationType: ConsultationType.inPerson,
      description: 'Review updated hemoglobin levels and oral iron response',
      riskLevel: RiskLevel.moderate,
      status: AppointmentStatus.confirmed,
    ),
    AppointmentModel(
      id: 'apt-4',
      patientId: '7',
      patientName: 'Diana Evans',
      patientAvatar: 'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?w=150',
      gestationalAge: 'Week 20',
      timeSlot: '04:15 PM',
      dateTime: DateTime.now().add(const Duration(hours: 7, minutes: 45)),
      type: 'Routine 2nd Trimester Ultrasound',
      consultationType: ConsultationType.inPerson,
      description: 'Standard mid-pregnancy anatomical survey and growth velocity',
      riskLevel: RiskLevel.stable,
      status: AppointmentStatus.pending,
    ),
    AppointmentModel(
      id: 'apt-5',
      patientId: '3',
      patientName: 'Maria Santos',
      patientAvatar: 'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=150',
      gestationalAge: 'Week 30',
      timeSlot: '10:00 AM',
      dateTime: DateTime.now().add(const Duration(days: 1, hours: 2)),
      type: 'Threatened Preterm Contractions Triage',
      consultationType: ConsultationType.emergencyTriage,
      description: 'Pelvic pressure and rhythmic tightening (4x/hour)',
      riskLevel: RiskLevel.high,
      status: AppointmentStatus.pending,
    ),
    AppointmentModel(
      id: 'apt-6',
      patientId: '5',
      patientName: 'Chloe Bennet',
      patientAvatar: 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=150',
      gestationalAge: 'Week 18',
      timeSlot: '03:30 PM',
      dateTime: DateTime.now().add(const Duration(days: 1, hours: 7)),
      type: 'Elevated BP Check-in & Pedal Edema',
      consultationType: ConsultationType.videoCall,
      description: 'Home log review of mild ankle swelling and BP reading 134/86',
      riskLevel: RiskLevel.moderate,
      status: AppointmentStatus.pending,
    ),
    AppointmentModel(
      id: 'apt-7',
      patientId: '10',
      patientName: 'Diana Prince',
      patientAvatar: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150',
      gestationalAge: 'Week 34',
      timeSlot: '09:00 AM',
      dateTime: DateTime.now().add(const Duration(days: 1, hours: 1)),
      type: 'Glycemic Profiling & Biweekly NST',
      consultationType: ConsultationType.inPerson,
      description: 'Evaluation of post-meal glucose logs and fetal non-stress test',
      riskLevel: RiskLevel.high,
      status: AppointmentStatus.confirmed,
    ),
    AppointmentModel(
      id: 'apt-8',
      patientId: '13',
      patientName: 'Maya Lin',
      patientAvatar: 'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?w=150',
      gestationalAge: 'Week 29',
      timeSlot: '11:30 AM',
      dateTime: DateTime.now().add(const Duration(days: 2, hours: 3)),
      type: 'Cervical Length Ultrasound Follow-up',
      consultationType: ConsultationType.inPerson,
      description: 'Transvaginal sonogram to evaluate cervical integrity & bed rest status',
      riskLevel: RiskLevel.high,
      status: AppointmentStatus.confirmed,
    ),
    AppointmentModel(
      id: 'apt-9',
      patientId: '14',
      patientName: 'Elena Rostova',
      patientAvatar: 'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?w=150',
      gestationalAge: 'Week 20',
      timeSlot: '01:15 PM',
      dateTime: DateTime.now().add(const Duration(days: 3, hours: 5)),
      type: 'Mid-Trimester Wellness & Anatomy Review',
      consultationType: ConsultationType.videoCall,
      description: 'Follow-up on routine anatomy scan findings and nutrient optimization',
      riskLevel: RiskLevel.stable,
      status: AppointmentStatus.rescheduled,
    ),
    AppointmentModel(
      id: 'apt-10',
      patientId: '8',
      patientName: 'Amanda Waller',
      patientAvatar: 'https://images.unsplash.com/photo-1508214751196-bcfd4ca60f91?w=150',
      gestationalAge: 'Week 14',
      timeSlot: '10:00 AM',
      dateTime: DateTime.now().subtract(const Duration(days: 1, hours: 2)),
      type: 'Early 2nd Trimester Transition & NIPT',
      consultationType: ConsultationType.inPerson,
      description: 'Routine second-trimester intake, NIPT review, and antiemetic tapering',
      riskLevel: RiskLevel.stable,
      status: AppointmentStatus.completed,
      clinicalNotesSummary:
          'NIPT low risk across all major aneuploidies. FHR 150 bpm regular rhythm. Fundal height matches gestational dates. Nausea is resolved; successfully tapered off ondansetron.',
      prescriptionsSummary:
          '1. MomCare Prenatal Multivitamin with DHA (1 capsule PO daily)\n2. Calcium Carbonate 500mg Chewable (1 tablet BID with meals)',
    ),
    AppointmentModel(
      id: 'apt-11',
      patientId: '9',
      patientName: 'Clara Oswald',
      patientAvatar: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=150',
      gestationalAge: 'Week 36',
      timeSlot: '02:30 PM',
      dateTime: DateTime.now().subtract(const Duration(days: 2, hours: 4)),
      type: 'Term Birth Plan & GBS Screening',
      consultationType: ConsultationType.inPerson,
      description: 'Term clinical assessment, GBS swab, and labor signs review',
      riskLevel: RiskLevel.stable,
      status: AppointmentStatus.completed,
      clinicalNotesSummary:
          'GBS rectovaginal screening swab obtained. Cephalic presentation confirmed by Leopold maneuvers. FHR 140 bpm with robust accelerations. Discussed 5-1-1 labor contraction rule.',
      prescriptionsSummary:
          '1. Ferrous Bisglycinate 28mg Gentle Iron (1 tablet daily)\n2. Docusate Sodium 100mg (as needed for mild constipation)',
    ),
    AppointmentModel(
      id: 'apt-12',
      patientId: '11',
      patientName: 'Natasha Romanoff',
      patientAvatar: 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=150',
      gestationalAge: 'Week 26',
      timeSlot: '11:00 AM',
      dateTime: DateTime.now().subtract(const Duration(days: 3, hours: 6)),
      type: 'Gestational Anemia Response Review',
      consultationType: ConsultationType.videoCall,
      description: 'Follow-up lab evaluation for therapeutic oral iron tolerance',
      riskLevel: RiskLevel.moderate,
      status: AppointmentStatus.completed,
      clinicalNotesSummary:
          'Repeat CBC demonstrates hemoglobin improved from 9.4 to 10.8 g/dL over 4 weeks. No GI intolerance reported. Advised to continue current regimen with vitamin C booster.',
      prescriptionsSummary:
          '1. Ferrous Fumarate 210mg (Twice daily with citrus juice)\n2. Ascorbic Acid (Vitamin C) 500mg (1 tablet with iron dose)',
    ),
    AppointmentModel(
      id: 'apt-13',
      patientId: '12',
      patientName: 'Wanda Maximoff',
      patientAvatar: 'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=150',
      gestationalAge: 'Week 31',
      timeSlot: '04:00 PM',
      dateTime: DateTime.now().subtract(const Duration(days: 1, hours: 5)),
      type: 'Edema & Fluid Retention Review',
      consultationType: ConsultationType.videoCall,
      description: 'Video consult for lower extremity swelling and compression therapy',
      riskLevel: RiskLevel.moderate,
      status: AppointmentStatus.rejected,
      rejectionReason: 'Doctor called into emergency C-Section surgery',
      suggestedAlternativeSlots: ['Tomorrow 11:00 AM', 'Friday 02:30 PM'],
      doctorNote:
          'I was called urgently into the delivery suite for an emergency cesarean delivery. Please choose one of the alternative slots above and we will consult right away.',
    ),
    AppointmentModel(
      id: 'apt-14',
      patientId: '6',
      patientName: 'Carol Danvers',
      patientAvatar: 'https://images.unsplash.com/photo-1508214751196-bcfd4ca60f91?w=150',
      gestationalAge: 'Week 24',
      timeSlot: '09:00 AM',
      dateTime: DateTime.now().subtract(const Duration(days: 2, hours: 1)),
      type: 'Routine Mid-Pregnancy Clinical Exam',
      consultationType: ConsultationType.inPerson,
      description: 'Routine wellness check, gestational weight gain review, and glucose challenge prep',
      riskLevel: RiskLevel.stable,
      status: AppointmentStatus.cancelled,
      rejectionReason: 'Patient requested cancellation due to travel schedule',
      suggestedAlternativeSlots: ['Next Monday 10:00 AM', 'Next Tuesday 03:00 PM'],
      doctorNote: 'Rescheduled at mother’s request to accommodate her out-of-town work schedule.',
    ),
  ];

  /// Active today appointments list (references instances from allAppointments)
  static List<AppointmentModel> todayAppointments = [
    allAppointments[0],
    allAppointments[1],
    allAppointments[2],
    allAppointments[3],
  ];

  static List<AppointmentModel> get appointments => allAppointments;

  static Map<String, ChatDetail> chats = {
    '1': ChatDetail(
      patientId: '1',
      messages: [
        ChatMessage(
          text: 'Hello Dr. Sarah, I have been experiencing a persistent headache since morning, and I just checked my BP: 160/105 mmHg.',
          isMe: false,
          timestamp: DateTime.now().subtract(const Duration(hours: 3, minutes: 20)),
        ),
        ChatMessage(
          text: 'Here is the home blood pressure log and lab report from yesterday.',
          isMe: false,
          timestamp: DateTime.now().subtract(const Duration(hours: 3, minutes: 18)),
          type: MessageType.attachment,
          attachment: AttachmentData(
            fileName: 'BP_Log_and_UrineProtein_Lab.pdf',
            fileSize: '1.8 MB',
            fileType: 'pdf',
          ),
        ),
        ChatMessage(
          text: 'Sarah, thank you for alerting me immediately. A systolic over 160 requires immediate clinical action to protect both you and baby.',
          isMe: true,
          timestamp: DateTime.now().subtract(const Duration(hours: 3, minutes: 10)),
        ),
        ChatMessage(
          text: 'Clinical Triage Evaluation',
          isMe: true,
          timestamp: DateTime.now().subtract(const Duration(hours: 3, minutes: 5)),
          type: MessageType.clinicalNote,
          clinicalNote: ClinicalNoteData(
            symptomsObserved: 'Frontal headache (3x/week), BP spike 160/105 mmHg, blurred vision.',
            diagnosis: 'Gestational Hypertension with Pre-eclampsia risk at Week 32.',
            nextSteps: 'Initiate oral Labetalol, modified bed rest, twice-daily BP tracking, repeat urine protein.',
            notes: 'Patient advised on red-flag emergency symptoms (epigastric pain, severe visual changes).',
            doctorName: 'Dr. Sarah Jenkins, MD',
          ),
        ),
        ChatMessage(
          text: 'Digital Prescription Issued',
          isMe: true,
          timestamp: DateTime.now().subtract(const Duration(hours: 3)),
          type: MessageType.prescription,
          prescription: PrescriptionData(
            rxNumber: 'RX-PRE-44910',
            drugName: 'Labetalol Hydrochloride',
            dosage: '200 mg Tablets',
            frequency: 'Twice daily (every 12 hours after meals)',
            duration: '14 days (Refills: 1)',
            instructions: 'Take with a full glass of water. Recheck BP 1 hour post dose and log in MomCare app.',
            doctorName: 'Dr. Sarah Jenkins, MD',
            doctorLicense: 'LIC-OBGYN-884219',
          ),
        ),
        ChatMessage(
          text: 'I have issued your digital prescription above. Please take your first dose with lunch and keep me updated in 2 hours.',
          isMe: true,
          timestamp: DateTime.now().subtract(const Duration(hours: 2, minutes: 55)),
        ),
        ChatMessage(
          text: 'Understood Dr. Sarah! My husband is picking it up now. Resting in bed.',
          isMe: false,
          timestamp: DateTime.now().subtract(const Duration(minutes: 25)),
        ),
      ],
    ),
    '2': ChatDetail(
      patientId: '2',
      messages: [
        ChatMessage(text: 'Doctor, my fasting blood sugar was 178 mg/dL this morning.', isMe: false, timestamp: DateTime.now().subtract(const Duration(minutes: 40))),
      ],
    ),
    '10': ChatDetail(
      patientId: '10',
      messages: [
        ChatMessage(text: 'Hello Dr. Sarah, I have a quick question about my diet.', isMe: false, timestamp: DateTime.now().subtract(const Duration(hours: 3))),
        ChatMessage(text: 'Hello Diana, please go ahead. How are you feeling today?', isMe: true, timestamp: DateTime.now().subtract(const Duration(hours: 2, minutes: 50))),
        ChatMessage(text: 'Doctor, my post-meal glucose spiked to 168 mg/dL. Should I adjust insulin?', isMe: false, timestamp: DateTime.now().subtract(const Duration(minutes: 12))),
      ],
    ),
    '11': ChatDetail(
      patientId: '11',
      messages: [
        ChatMessage(text: 'Should I take the iron supplements with orange juice or with meals?', isMe: false, timestamp: DateTime.now().subtract(const Duration(hours: 1, minutes: 25))),
      ],
    ),
    '12': ChatDetail(
      patientId: '12',
      messages: [
        ChatMessage(text: 'The swelling in my ankles feels tighter today after standing at work.', isMe: false, timestamp: DateTime.now().subtract(const Duration(hours: 2, minutes: 40))),
      ],
    ),
  };
}

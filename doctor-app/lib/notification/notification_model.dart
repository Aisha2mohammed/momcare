import 'package:flutter/material.dart';
import 'package:doctor_app/constants/color.dart';
import 'package:doctor_app/model/mock_data.dart';

enum NotificationType {
  criticalAlert,
  appointment,
  prescription,
  labResult,
  general,
}

class DoctorNotification {
  final String id;
  final String title;
  final String message;
  final String patientName;
  final String patientAvatar;
  final String patientId;
  final DateTime timestamp;
  final NotificationType type;
  final RiskLevel? riskLevel;
  bool isRead;

  DoctorNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.patientName,
    required this.patientAvatar,
    required this.patientId,
    required this.timestamp,
    required this.type,
    this.riskLevel,
    this.isRead = false,
  });

  IconData get icon {
    switch (type) {
      case NotificationType.criticalAlert:
        return Icons.warning_amber_rounded;
      case NotificationType.appointment:
        return Icons.calendar_month_rounded;
      case NotificationType.prescription:
        return Icons.medication_rounded;
      case NotificationType.labResult:
        return Icons.biotech_rounded;
      case NotificationType.general:
        return Icons.notifications_rounded;
    }
  }

  Color get color {
    switch (type) {
      case NotificationType.criticalAlert:
        return AppColors.riskHigh;
      case NotificationType.appointment:
        return const Color(0xFF2563EB);
      case NotificationType.prescription:
        return AppColors.primary;
      case NotificationType.labResult:
        return const Color(0xFF7C3AED);
      case NotificationType.general:
        return AppColors.textSecondary;
    }
  }
}

class NotificationRepository {
  static List<DoctorNotification> notifications = [
    DoctorNotification(
      id: 'notif-1',
      title: 'CRITICAL: Severe BP Spike Logged',
      message: 'Sarah Connor recorded home blood pressure: 160/105 mmHg with frontal headache. Immediate clinical review advised.',
      patientName: 'Sarah Connor (Week 32)',
      patientAvatar: 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=150',
      patientId: '1',
      timestamp: DateTime.now().subtract(const Duration(minutes: 8)),
      type: NotificationType.criticalAlert,
      riskLevel: RiskLevel.high,
      isRead: false,
    ),
    DoctorNotification(
      id: 'notif-2',
      title: 'New Consultation Request',
      message: 'Maria Santos requested an emergency appointment for preterm contractions evaluation tomorrow at 09:30 AM.',
      patientName: 'Maria Santos (Week 30)',
      patientAvatar: 'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=150',
      patientId: '3',
      timestamp: DateTime.now().subtract(const Duration(minutes: 32)),
      type: NotificationType.appointment,
      riskLevel: RiskLevel.high,
      isRead: false,
    ),
    DoctorNotification(
      id: 'notif-3',
      title: 'Post-Meal Glycemic Alert',
      message: 'Jessica Alba logged 2-hr postprandial glucose: 178 mg/dL following breakfast.',
      patientName: 'Jessica Alba (Week 28)',
      patientAvatar: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150',
      patientId: '2',
      timestamp: DateTime.now().subtract(const Duration(hours: 1, minutes: 15)),
      type: NotificationType.criticalAlert,
      riskLevel: RiskLevel.high,
      isRead: false,
    ),
    DoctorNotification(
      id: 'notif-4',
      title: 'Digital Prescription Filled',
      message: 'Diana Prince\'s digital Rx for Labetalol 200mg was dispensed by St. Paul Hospital Pharmacy.',
      patientName: 'Diana Prince (Week 34)',
      patientAvatar: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150',
      patientId: '10',
      timestamp: DateTime.now().subtract(const Duration(hours: 3)),
      type: NotificationType.prescription,
      riskLevel: RiskLevel.high,
      isRead: true,
    ),
    DoctorNotification(
      id: 'notif-5',
      title: 'Lab Report Available: Urinalysis & CBC',
      message: 'Lab results for Natasha Romanoff have been uploaded. Hemoglobin: 10.1 g/dL, Ferritin: 14 ng/mL.',
      patientName: 'Natasha Romanoff (Week 27)',
      patientAvatar: 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=150',
      patientId: '11',
      timestamp: DateTime.now().subtract(const Duration(hours: 6)),
      type: NotificationType.labResult,
      riskLevel: RiskLevel.moderate,
      isRead: true,
    ),
    DoctorNotification(
      id: 'notif-6',
      title: 'Upcoming Appointment Reminder',
      message: 'Scheduled 2nd Trimester Anatomy Ultrasound with Emily Rose in 2 hours at 02:00 PM.',
      patientName: 'Emily Rose (Week 22)',
      patientAvatar: 'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?w=150',
      patientId: '4',
      timestamp: DateTime.now().subtract(const Duration(hours: 8)),
      type: NotificationType.appointment,
      riskLevel: RiskLevel.moderate,
      isRead: true,
    ),
  ];

  static int get unreadCount => notifications.where((n) => !n.isRead).length;

  static void markAllAsRead() {
    for (var n in notifications) {
      n.isRead = true;
    }
  }

  static void clearAll() {
    notifications.clear();
  }
}

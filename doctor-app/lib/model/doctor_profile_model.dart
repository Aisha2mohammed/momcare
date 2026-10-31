import 'package:flutter/foundation.dart';
import 'package:doctor_app/model/mock_data.dart';

class AvailabilitySlotModel {
  final String id;
  String period; // 'Morning', 'Afternoon', 'Evening'
  String timeRange; // e.g. '09:00 AM - 12:00 PM'
  int capacity; // max patients per slot

  AvailabilitySlotModel({
    required this.id,
    required this.period,
    required this.timeRange,
    this.capacity = 5,
  });
}

class DayScheduleModel {
  final String dayName;
  final String shortDay;
  bool isEnabled;
  List<AvailabilitySlotModel> slots;

  DayScheduleModel({
    required this.dayName,
    required this.shortDay,
    this.isEnabled = true,
    required this.slots,
  });
}

class VerificationDocModel {
  final String title;
  final String fileType;
  final String issueDate;
  final String status;

  VerificationDocModel({
    required this.title,
    required this.fileType,
    required this.issueDate,
    this.status = 'Verified & Active',
  });
}

class DoctorProfileModel extends ChangeNotifier {
  String name;
  String specialization;
  String clinicAffiliation;
  String hospitalClinicName;
  String avatarUrl;
  bool isVerified;
  String licenseNumber;
  String licenseExpiry;
  String licenseExpiryDate;
  String nationalId;
  String nationalIdUrl;
  String credentialDocumentUrl;
  String yearsExperience;
  String practiceLocation;
  List<String> languages;
  String bio;
  DoctorAvailability availability;
  List<VerificationDocModel> documents;
  List<DayScheduleModel> weeklySchedule;

  void notify() {
    notifyListeners();
  }

  DoctorProfileModel({
    required this.name,
    required this.specialization,
    required this.clinicAffiliation,
    String? hospitalClinicName,
    required this.avatarUrl,
    this.isVerified = true,
    required this.licenseNumber,
    required this.licenseExpiry,
    String? licenseExpiryDate,
    this.nationalId = '',
    this.nationalIdUrl = '',
    this.credentialDocumentUrl = '',
    required this.yearsExperience,
    required this.practiceLocation,
    required this.languages,
    required this.bio,
    this.availability = DoctorAvailability.online,
    required this.documents,
    required this.weeklySchedule,
  })  : hospitalClinicName = hospitalClinicName ?? clinicAffiliation,
        licenseExpiryDate = licenseExpiryDate ?? licenseExpiry;

  static final DoctorProfileModel shared = sampleDoctor();

  static DoctorProfileModel sampleDoctor() {
    return DoctorProfileModel(
      name: 'Dr. Sarah Jenkins, MD',
      specialization: 'Senior Obstetrician & Maternal-Fetal Specialist',
      clinicAffiliation: 'St. Paul Maternal Hospital & MomCare Clinic',
      avatarUrl: 'https://images.unsplash.com/photo-1559839734-2b71ea197ec2?w=200',
      isVerified: true,
      licenseNumber: 'LIC-OBGYN-884219',
      licenseExpiry: 'Nov 2028',
      yearsExperience: '12+ Years Experience',
      practiceLocation: 'Addis Ababa, Ethiopia (Wing A, Floor 3)',
      languages: ['English', 'Amharic', 'Afan Oromo', 'Somali'],
      bio: 'Dedicated Maternal-Fetal Medicine (MFM) specialist focusing on high-risk prenatal triage, pre-eclampsia management, gestational glycemic regulation, and safe delivery planning for expectant mothers.',
      availability: DoctorAvailability.online,
      documents: [
        VerificationDocModel(
          title: 'Specialist Medical License Certificate',
          fileType: 'PDF Document',
          issueDate: 'Issued: Dec 2023',
        ),
        VerificationDocModel(
          title: 'Maternal Hospital Facility Accreditation',
          fileType: 'Certified ID',
          issueDate: 'Valid thru: 2028',
        ),
      ],
      weeklySchedule: [
        DayScheduleModel(
          dayName: 'Monday',
          shortDay: 'Mon',
          isEnabled: true,
          slots: [
            AvailabilitySlotModel(id: 'mon-1', period: 'Morning', timeRange: '09:00 AM - 12:00 PM', capacity: 6),
            AvailabilitySlotModel(id: 'mon-2', period: 'Afternoon', timeRange: '02:00 PM - 05:00 PM', capacity: 5),
          ],
        ),
        DayScheduleModel(
          dayName: 'Tuesday',
          shortDay: 'Tue',
          isEnabled: true,
          slots: [
            AvailabilitySlotModel(id: 'tue-1', period: 'Morning', timeRange: '09:30 AM - 01:00 PM', capacity: 7),
          ],
        ),
        DayScheduleModel(
          dayName: 'Wednesday',
          shortDay: 'Wed',
          isEnabled: true,
          slots: [
            AvailabilitySlotModel(id: 'wed-1', period: 'Morning', timeRange: '09:00 AM - 12:00 PM', capacity: 5),
            AvailabilitySlotModel(id: 'wed-2', period: 'Evening', timeRange: '05:00 PM - 07:30 PM', capacity: 4),
          ],
        ),
        DayScheduleModel(
          dayName: 'Thursday',
          shortDay: 'Thu',
          isEnabled: true,
          slots: [
            AvailabilitySlotModel(id: 'thu-1', period: 'Morning', timeRange: '09:00 AM - 12:30 PM', capacity: 6),
            AvailabilitySlotModel(id: 'thu-2', period: 'Afternoon', timeRange: '02:00 PM - 04:30 PM', capacity: 4),
          ],
        ),
        DayScheduleModel(
          dayName: 'Friday',
          shortDay: 'Fri',
          isEnabled: true,
          slots: [
            AvailabilitySlotModel(id: 'fri-1', period: 'Morning', timeRange: '08:30 AM - 12:00 PM', capacity: 6),
          ],
        ),
        DayScheduleModel(
          dayName: 'Saturday',
          shortDay: 'Sat',
          isEnabled: false,
          slots: [
            AvailabilitySlotModel(id: 'sat-1', period: 'Morning', timeRange: '10:00 AM - 01:00 PM', capacity: 3),
          ],
        ),
        DayScheduleModel(
          dayName: 'Sunday',
          shortDay: 'Sun',
          isEnabled: false,
          slots: [],
        ),
      ],
    );
  }
}

enum MessageType {
  text,
  clinicalNote,
  prescription,
  attachment,
}

class ClinicalNoteData {
  final String symptomsObserved;
  final String diagnosis;
  final String nextSteps;
  final String notes;
  final String doctorName;
  final DateTime timestamp;

  ClinicalNoteData({
    required this.symptomsObserved,
    required this.diagnosis,
    required this.nextSteps,
    required this.notes,
    this.doctorName = 'Dr. Sarah Jenkins, MD',
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

class PrescriptionData {
  final String rxNumber;
  final String drugName;
  final String dosage;
  final String frequency;
  final String duration;
  final String instructions;
  final String doctorName;
  final String doctorLicense;
  final DateTime timestamp;

  PrescriptionData({
    required this.rxNumber,
    required this.drugName,
    required this.dosage,
    required this.frequency,
    required this.duration,
    required this.instructions,
    this.doctorName = 'Dr. Sarah Jenkins, MD',
    this.doctorLicense = 'LIC-OBGYN-884219',
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

class AttachmentData {
  final String fileName;
  final String fileSize;
  final String fileType; // 'pdf', 'image', 'scan'
  final String? imageUrl;
  final bool isImage;

  AttachmentData({
    required this.fileName,
    required this.fileSize,
    required this.fileType,
    this.imageUrl,
    this.isImage = false,
  });
}

class ChatMessage {
  final String text;
  final bool isMe;
  final DateTime timestamp;
  final MessageType type;
  final ClinicalNoteData? clinicalNote;
  final PrescriptionData? prescription;
  final AttachmentData? attachment;

  ChatMessage({
    required this.text,
    required this.isMe,
    required this.timestamp,
    this.type = MessageType.text,
    this.clinicalNote,
    this.prescription,
    this.attachment,
  });
}

typedef Message = ChatMessage;

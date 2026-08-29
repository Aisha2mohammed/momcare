class Patient {
  final String id;
  final String name;
  final int severityIndicator; // 1 to 5 (5 is highest)
  final int frequencyIndicator; // 1 to 5 (5 is highest)
  final String condition;
  final String imageUrl;
  bool isAccepted;

  Patient({
    required this.id,
    required this.name,
    required this.severityIndicator,
    required this.frequencyIndicator,
    required this.condition,
    required this.imageUrl,
    this.isAccepted = false,
  });
}

class Message {
  final String text;
  final bool isMe;
  final DateTime timestamp;

  Message({
    required this.text,
    required this.isMe,
    required this.timestamp,
  });
}

class ChatDetail {
  final String patientId;
  final List<Message> messages;

  ChatDetail({
    required this.patientId,
    required this.messages,
  });
}

class Appointment {
  final String patientName;
  final DateTime dateTime;
  final String description;

  Appointment({
    required this.patientName,
    required this.dateTime,
    required this.description,
  });
}

class MockData {
  static List<Patient> incomingPatients = [
    Patient(
      id: '1',
      name: 'Sarah Connor',
      severityIndicator: 5,
      frequencyIndicator: 4,
      condition: 'High Blood Pressure',
      imageUrl: 'https://i.pravatar.cc/150?img=1',
    ),
    Patient(
      id: '2',
      name: 'Emily Rose',
      severityIndicator: 3,
      frequencyIndicator: 2,
      condition: 'Routine Checkup',
      imageUrl: 'https://i.pravatar.cc/150?img=5',
    ),
    Patient(
      id: '3',
      name: 'Jessica Alba',
      severityIndicator: 4,
      frequencyIndicator: 5,
      condition: 'Gestational Diabetes',
      imageUrl: 'https://i.pravatar.cc/150?img=9',
    ),
    Patient(
      id: '4',
      name: 'Amanda Waller',
      severityIndicator: 2,
      frequencyIndicator: 1,
      condition: 'Mild Nausea',
      imageUrl: 'https://i.pravatar.cc/150?img=10',
    ),
  ];

  static List<Patient> acceptedPatients = [
    Patient(
      id: '10',
      name: 'Diana Prince',
      severityIndicator: 1,
      frequencyIndicator: 1,
      condition: '3rd Trimester Follow-up',
      imageUrl: 'https://i.pravatar.cc/150?img=20',
      isAccepted: true,
    ),
  ];

  static List<Appointment> appointments = [
    Appointment(
      patientName: 'Diana Prince',
      dateTime: DateTime.now().add(const Duration(days: 1, hours: 2)),
      description: 'Follow-up Ultrasound',
    ),
    Appointment(
      patientName: 'Natasha Romanoff',
      dateTime: DateTime.now().add(const Duration(days: 3, hours: -1)),
      description: 'Routine Blood Test',
    ),
  ];

  static Map<String, ChatDetail> chats = {
    '10': ChatDetail(
      patientId: '10',
      messages: [
        Message(text: 'Hello Dr., I have a question about my diet.', isMe: false, timestamp: DateTime.now().subtract(const Duration(minutes: 30))),
        Message(text: 'Hello Diana, please go ahead.', isMe: true, timestamp: DateTime.now().subtract(const Duration(minutes: 28))),
      ],
    ),
  };
}

import 'package:flutter/material.dart';
import 'package:doctor_app/model/mock_data.dart';
import 'package:doctor_app/chat/chat_detail_screen.dart';

class ChatListTab extends StatelessWidget {
  const ChatListTab({super.key});

  @override
  Widget build(BuildContext context) {
    if (MockData.acceptedPatients.isEmpty) {
      return const Center(child: Text("No active chats yet."));
    }

    return ListView.builder(
      itemCount: MockData.acceptedPatients.length,
      itemBuilder: (context, index) {
        final patient = MockData.acceptedPatients[index];
        return ListTile(
          leading: CircleAvatar(
            backgroundImage: NetworkImage(patient.imageUrl),
            radius: 25,
          ),
          title: Text(patient.name, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: const Text('Tap to open chat...'), // Mock preview
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ChatDetailScreen(patient: patient)),
            );
          },
        );
      },
    );
  }
}

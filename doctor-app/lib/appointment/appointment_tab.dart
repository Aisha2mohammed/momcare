import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:doctor_app/constants/color.dart';
import 'package:doctor_app/model/mock_data.dart';

class AppointmentTab extends StatelessWidget {
  const AppointmentTab({super.key});

  @override
  Widget build(BuildContext context) {
    if (MockData.appointments.isEmpty) {
      return const Center(child: Text("No upcoming appointments."));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: MockData.appointments.length,
      itemBuilder: (context, index) {
        final appt = MockData.appointments[index];
        final timeStr = DateFormat('MMM dd, yyyy - hh:mm a').format(appt.dateTime);

        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: const Icon(Icons.calendar_month, color: AppColors.primary, size: 40),
            title: Text(appt.patientName, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(timeStr, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
                Text(appt.description),
              ],
            ),
            isThreeLine: true,
          ),
        );
      },
    );
  }
}

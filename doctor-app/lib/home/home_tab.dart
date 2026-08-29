import 'package:flutter/material.dart';
import 'package:doctor_app/constants/color.dart';
import 'package:doctor_app/model/mock_data.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  List<Patient> _patients = [];

  @override
  void initState() {
    super.initState();
    _loadAndSortPatients();
  }
  
  void _loadAndSortPatients() {
    // Sort by severity (high to low) then by frequency (high to low)
    var list = List<Patient>.from(MockData.incomingPatients);
    list.sort((a, b) {
      if (a.severityIndicator != b.severityIndicator) {
        return b.severityIndicator.compareTo(a.severityIndicator);
      }
      return b.frequencyIndicator.compareTo(a.frequencyIndicator);
    });
    setState(() {
      _patients = list;
    });
  }

  void _acceptPatient(Patient patient) {
    setState(() {
      patient.isAccepted = true;
      _patients.removeWhere((p) => p.id == patient.id);
      MockData.incomingPatients.removeWhere((p) => p.id == patient.id);
      MockData.acceptedPatients.add(patient);
      
      // Initialize an empty chat history
      MockData.chats[patient.id] = ChatDetail(patientId: patient.id, messages: []);
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Accepted ${patient.name}')));
  }

  @override
  Widget build(BuildContext context) {
    return _patients.isEmpty 
        ? const Center(child: Text("No incoming patients right now"))
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _patients.length,
            itemBuilder: (context, index) {
              final patient = _patients[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundImage: NetworkImage(patient.imageUrl),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(patient.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                                Text(patient.condition, style: const TextStyle(color: Colors.grey)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildIndicator("Severity", patient.severityIndicator, Colors.red),
                          _buildIndicator("Frequency", patient.frequencyIndicator, Colors.orange),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => _acceptPatient(patient),
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                          child: const Text('Accept Patient', style: TextStyle(color: Colors.white)),
                        ),
                      )
                    ],
                  ),
                ),
              );
            },
          );
  }

  Widget _buildIndicator(String label, int value, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Row(
          children: List.generate(5, (index) => Icon(
            Icons.star,
            size: 16,
            color: index < value ? color : Colors.grey.shade300,
          )),
        )
      ],
    );
  }
}

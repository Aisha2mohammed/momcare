import 'package:flutter/material.dart';
import 'package:pregnancy_appp/l10n/l10n.dart';

class EmergencyPage extends StatelessWidget {
  const EmergencyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Emergency & Health",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              "Immediate help and vital precautions",
              style: TextStyle(fontSize: 15, color: Colors.grey[600]),
            ),
            const SizedBox(height: 25),
            
            // Emergency Actions
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(25),
                border: Border.all(color: Colors.red[100]!),
              ),
              child: Column(
                children: [
                   Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                        child: const Icon(Icons.emergency_rounded, color: Colors.white, size: 28),
                      ),
                      const SizedBox(width: 15),
                      const Expanded(
                        child: Text(
                          "Feeling severe pain or unusual signs?",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () {}, // Implementation for calling emergency
                    icon: const Icon(Icons.phone_rounded),
                    label: Text(AppStrings.of(context, 'emergency_call')),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 55),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      elevation: 0,
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.location_on_rounded),
                    label: Text(AppStrings.of(context, 'gps_share')),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 30),
            
            // Warning Signs
            const Text(
              "Warning Signs (Seek Medical Help)",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),
            _buildWarningItem("Severe headache that won't go away"),
            _buildWarningItem("Changes in your vision (blurring, flashes)"),
            _buildWarningItem("Sudden swelling of face, hands or feet"),
            _buildWarningItem("Vaginal bleeding or leaking fluid"),
            _buildWarningItem("Persistent abdominal pain"),
            _buildWarningItem("Baby moving less than usual"),
            
            const SizedBox(height: 30),

            // Health Tips
            const Text(
              "Vital Health Tips",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),
            _buildHealthTipCard(
              context,
              Icons.healing_rounded, 
              AppStrings.of(context, 'first_aid'),
              "Learn what to do in case of fainting or falls.",
              Colors.blue[50]!,
              Colors.blue[700]!,
            ),
            const SizedBox(height: 15),
            _buildHealthTipCard(
              context,
              Icons.vaccines_rounded, 
              "Check-ups",
              "Never miss your prenatal appointments.",
              Colors.teal[50]!,
              Colors.teal[700]!,
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildWarningItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.report_problem_rounded, color: Colors.orange, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 14, color: Colors.grey[800]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHealthTipCard(BuildContext context, IconData icon, String title, String subtitle, Color bgColor, Color iconColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 30),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 4),
                Text(subtitle, style: TextStyle(fontSize: 13, color: Colors.grey[700])),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: iconColor.withOpacity(0.5)),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:pregnancy_appp/constants/color.dart';

class FetalDetailsPage extends StatelessWidget {
  const FetalDetailsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text("Fetal Details"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Baby Image
            Container(
              height: 250,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.secondary,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10))
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: Image.asset(
                  'assets/images/baby-image.jpg', // Placeholder
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return const Center(child: Icon(Icons.child_care_rounded, size: 80, color: AppColors.primary));
                  },
                ),
              ),
            ),
            const SizedBox(height: 30),

            // Top Stats
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatItem("Weight", "14g", Icons.monitor_weight_rounded),
                _buildStatItem("Length", "5.4cm", Icons.straighten_rounded),
                _buildStatItem("Days Left", "196", Icons.calendar_month_rounded),
              ],
            ),
            
            const SizedBox(height: 35),
            
            // Text Details
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 5))
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Week 12 Development", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Text(
                    "Your baby's reflexes are starting to develop! They may curl their toes, close their fingers, and make sucking movements.",
                    style: TextStyle(fontSize: 14, color: Colors.grey[700], height: 1.5),
                  ),
                  const SizedBox(height: 15),
                  const Text("Fun Fact", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.primary)),
                  const SizedBox(height: 5),
                  Text(
                    "Your little one is roughly the size of a plum this week.",
                    style: TextStyle(fontSize: 14, color: Colors.grey[700], height: 1.5),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppColors.primary, size: 28),
        ),
        const SizedBox(height: 10),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
      ],
    );
  }
}

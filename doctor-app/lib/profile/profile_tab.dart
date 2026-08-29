import 'package:flutter/material.dart';
import 'package:doctor_app/constants/color.dart';
import 'package:doctor_app/auth/login_screen.dart';

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          const CircleAvatar(
            radius: 60,
            backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=33'),
          ),
          const SizedBox(height: 16),
          const Text('Dr. Smith', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const Text('OB/GYN Specialist', style: TextStyle(color: Colors.grey, fontSize: 16)),
          
          const SizedBox(height: 32),
          _buildProfileItem(Icons.credit_card, 'License No.', 'LIC-987654321A'),
          const Divider(),
          _buildProfileItem(Icons.local_hospital, 'Clinic', 'General Hospital, NYC'),
          const Divider(),
          _buildProfileItem(Icons.access_time, 'Working Hours', '9:00 AM - 5:00 PM'),
          const Divider(),
          
          const SizedBox(height: 48),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.logout, color: Colors.red),
              label: const Text('Logout', style: TextStyle(color: Colors.red)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              onPressed: () {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false,
                );
              },
            ),
          )
        ],
      ),
    );
  }

  Widget _buildProfileItem(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary),
          const SizedBox(width: 16),
          Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold))),
          Text(value, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}

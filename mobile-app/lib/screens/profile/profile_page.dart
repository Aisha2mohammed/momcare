import 'package:flutter/material.dart';
import 'package:pregnancy_appp/constants/color.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 10),
            // Profile Header
            Center(
              child: Column(
                children: [
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundColor: AppColors.primary.withOpacity(0.1),
                        child: const Icon(Icons.person_rounded, size: 80, color: AppColors.primary),
                      ),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                        child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 18),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "Sarah Johnson",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const Text(
                    "12 Weeks Pregnant",
                    style: TextStyle(color: Colors.grey, fontSize: 15),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 35),
            
            // Stats Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatItem("Weight", "62 kg"),
                _buildStatItem("Blood", "A+"),
                _buildStatItem("Due Date", "Oct 25"),
              ],
            ),
            
            const SizedBox(height: 35),

            // Settings List
            _buildSettingsSection("Account Settings", [
              _buildSettingsTile(Icons.person_outline_rounded, "Personal Information"),
              _buildSettingsTile(Icons.calendar_month_rounded, "Pregnancy Details"),
            ]),
            
            const SizedBox(height: 25),
            
            _buildSettingsSection("App Settings", [
              _buildSettingsTile(Icons.notifications_none_rounded, "Notifications"),
              _buildSettingsTile(Icons.language_rounded, "Language Settings"),
              _buildSettingsTile(Icons.security_rounded, "Privacy & Security"),
            ]),
            
            const SizedBox(height: 30),
            
            // Logout
            TextButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.logout_rounded, color: Colors.red),
              label: const Text("Log Out", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
              style: TextButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                backgroundColor: Colors.red[50],
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary)),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildSettingsSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 5, bottom: 12),
          child: Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey[800])),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
            ],
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildSettingsTile(IconData icon, String title) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary, size: 22),
      title: Text(title, style: const TextStyle(fontSize: 15)),
      trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
      onTap: () {},
    );
  }
}

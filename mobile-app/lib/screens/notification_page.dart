import 'package:flutter/material.dart';
import 'package:pregnancy_appp/constants/color.dart';

class NotificationPage extends StatelessWidget {
  const NotificationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text("Notifications", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildNotificationItem(
            "Appointment Reminder",
            "Your next prenatal check-up is tomorrow at 10:00 AM.",
            "1h ago",
            Icons.calendar_today_rounded,
            Colors.blue[100]!,
            Colors.blue[700]!,
            isUnread: true,
          ),
          _buildNotificationItem(
            "Hydration Alert",
            "Time to drink a glass of water! Stay hydrated for your baby.",
            "3h ago",
            Icons.water_drop_rounded,
            Colors.teal[100]!,
            Colors.teal[700]!,
            isUnread: true,
          ),
          _buildNotificationItem(
            "New Community Post",
            "Abeba T. just posted in the Health category.",
            "5h ago",
            Icons.groups_rounded,
            Colors.purple[100]!,
            Colors.purple[700]!,
            isUnread: false,
          ),
          _buildNotificationItem(
            "Daily Tip",
            "Your baby is now the size of a lime! Read more about development.",
            "Yesterday",
            Icons.child_care_rounded,
            Colors.orange[100]!,
            Colors.orange[700]!,
            isUnread: false,
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationItem(String title, String body, String time, IconData icon, Color bgColor, Color iconColor, {required bool isUnread}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isUnread ? Colors.white : Colors.grey[50],
        borderRadius: BorderRadius.circular(20),
        boxShadow: isUnread ? [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ] : [],
        border: isUnread ? Border.all(color: AppColors.primary.withOpacity(0.1)) : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(title, style: TextStyle(fontWeight: isUnread ? FontWeight.bold : FontWeight.w600, fontSize: 15)),
                    Text(time, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  body,
                  style: TextStyle(color: Colors.grey[700], fontSize: 14, height: 1.3),
                ),
              ],
            ),
          ),
          if (isUnread)
            Container(
              margin: const EdgeInsets.only(left: 10, top: 4),
              width: 10,
              height: 10,
              decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
            ),
        ],
      ),
    );
  }
}

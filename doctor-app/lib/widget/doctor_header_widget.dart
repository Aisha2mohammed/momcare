import 'package:flutter/material.dart';
import 'package:doctor_app/constants/color.dart';
import 'package:doctor_app/model/mock_data.dart';

class DoctorHeaderWidget extends StatelessWidget {
  final String doctorName;
  final String specialty;
  final String avatarUrl;
  final DoctorAvailability availability;
  final ValueChanged<DoctorAvailability>? onAvailabilityChanged;
  final VoidCallback? onAvailabilityTapped;
  final Widget? searchBar;
  final int totalPatients;
  final int pendingAppointments;
  final int highRiskAlerts;
  final VoidCallback? onPatientsTapped;
  final VoidCallback? onPendingTapped;
  final VoidCallback? onHighRiskTapped;

  const DoctorHeaderWidget({
    super.key,
    this.doctorName = 'Dr. Sarah Jenkins, MD',
    this.specialty = 'Maternal-Fetal Medicine & OB/GYN',
    this.avatarUrl = 'https://images.unsplash.com/photo-1559839734-2b71ea197ec2?w=150',
    required this.availability,
    this.onAvailabilityChanged,
    this.onAvailabilityTapped,
    this.searchBar,
    required this.totalPatients,
    required this.pendingAppointments,
    required this.highRiskAlerts,
    this.onPatientsTapped,
    this.onPendingTapped,
    this.onHighRiskTapped,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Greeting & Doctor Profile Info Row
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.primaryLight,
                backgroundImage: avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
                onBackgroundImageError: (_, __) {},
                child: avatarUrl.isEmpty ? const Icon(Icons.person, color: AppColors.primary) : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      doctorName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      specialty,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              // Static Availability Status Badge (No dropdown)
              _buildStaticAvailabilityBadge(context),
            ],
          ),

          // Search Bar placed ABOVE the 3 Stat Cards
          if (searchBar != null) ...[
            const SizedBox(height: 14),
            searchBar!,
          ],

          const SizedBox(height: 16),

          // Quick Stat Cards
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  title: 'Active Patients',
                  count: totalPatients.toString(),
                  icon: Icons.people_outline_rounded,
                  accentColor: AppColors.primary,
                  bgColor: AppColors.primaryLight,
                  onTap: onPatientsTapped,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildStatCard(
                  title: 'Pending Appts',
                  count: pendingAppointments.toString(),
                  icon: Icons.calendar_today_outlined,
                  accentColor: const Color(0xFF2563EB),
                  bgColor: const Color(0xFFEFF6FF),
                  onTap: onPendingTapped,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildStatCard(
                  title: 'High-Risk Alerts',
                  count: highRiskAlerts.toString(),
                  icon: Icons.warning_amber_rounded,
                  accentColor: AppColors.riskHigh,
                  bgColor: AppColors.riskHighBg,
                  onTap: onHighRiskTapped,
                  isAlert: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStaticAvailabilityBadge(BuildContext context) {
    final badge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: availability.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: availability.color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: availability.color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            availability.label,
            style: TextStyle(
              color: availability.color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );

    if (onAvailabilityTapped != null) {
      return InkWell(
        onTap: onAvailabilityTapped,
        borderRadius: BorderRadius.circular(20),
        child: badge,
      );
    }
    return badge;
  }

  Widget _buildStatCard({
    required String title,
    required String count,
    required IconData icon,
    required Color accentColor,
    required Color bgColor,
    VoidCallback? onTap,
    bool isAlert = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
          decoration: BoxDecoration(
            color: isAlert ? AppColors.riskHighBg.withValues(alpha: 0.5) : AppColors.background,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isAlert ? AppColors.riskHigh.withValues(alpha: 0.3) : Colors.grey.shade200,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: accentColor, size: 16),
                  ),
                  if (isAlert && int.tryParse(count) != null && int.parse(count) > 0)
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.riskHigh,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                count,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isAlert ? AppColors.riskHigh : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

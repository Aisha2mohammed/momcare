import 'package:flutter/material.dart';
import 'package:doctor_app/constants/color.dart';
import 'package:doctor_app/model/mock_data.dart';

class PatientCard extends StatelessWidget {
  final Patient patient;
  final ValueChanged<Patient> onAccept;
  final ValueChanged<Patient>? onDecline;
  final ValueChanged<Patient>? onTap;

  const PatientCard({
    super.key,
    required this.patient,
    required this.onAccept,
    this.onDecline,
    this.onTap,
  });

  Color _getRiskColor() {
    switch (patient.riskLevel) {
      case RiskLevel.high:
        return AppColors.riskHigh;
      case RiskLevel.moderate:
        return AppColors.riskModerate;
      case RiskLevel.stable:
        return AppColors.riskStable;
    }
  }

  Color _getRiskBgColor() {
    switch (patient.riskLevel) {
      case RiskLevel.high:
        return AppColors.riskHighBg;
      case RiskLevel.moderate:
        return AppColors.riskModerateBg;
      case RiskLevel.stable:
        return AppColors.riskStableBg;
    }
  }

  IconData _getRiskIcon() {
    switch (patient.riskLevel) {
      case RiskLevel.high:
        return Icons.warning_amber_rounded;
      case RiskLevel.moderate:
        return Icons.info_outline_rounded;
      case RiskLevel.stable:
        return Icons.check_circle_outline_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final riskColor = _getRiskColor();
    final riskBgColor = _getRiskBgColor();

    return InkWell(
      onTap: onTap != null ? () => onTap!(patient) : null,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: patient.riskLevel == RiskLevel.high
                ? AppColors.riskHigh.withValues(alpha: 0.35)
                : Colors.grey.shade200,
            width: patient.riskLevel == RiskLevel.high ? 1.5 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: patient.riskLevel == RiskLevel.high
                  ? AppColors.riskHigh.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Row: Avatar, Info, and Risk Indicator Badge
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: AppColors.primaryLight,
                        backgroundImage: NetworkImage(patient.imageUrl),
                        onBackgroundImageError: (_, __) {},
                        child: Text(
                          patient.name.isNotEmpty ? patient.name[0] : 'P',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            color: riskColor,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          patient.name,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Text(
                              patient.gestationalWeek,
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const Text(' • ', style: TextStyle(color: Colors.grey)),
                            Text(
                              patient.age,
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Risk Indicator Pill
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: riskBgColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: riskColor.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(_getRiskIcon(), size: 14, color: riskColor),
                        const SizedBox(width: 4),
                        Text(
                          patient.riskLabel,
                          style: TextStyle(
                            color: riskColor,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Condition description
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.medical_services_outlined, size: 16, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        patient.condition,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),

              // Symptoms tags if available
              if (patient.symptoms.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: patient.symptoms.map((symptom) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Text(
                        symptom,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],

              const SizedBox(height: 14),
              const Divider(height: 1),
              const SizedBox(height: 12),

              // Risk Indicator Details: Severity & Frequency Gauges
              Row(
                children: [
                  Expanded(
                    child: _buildRiskGauge(
                      label: 'Severity',
                      value: patient.severityIndicator,
                      color: AppColors.riskHigh,
                      icon: Icons.speed_rounded,
                    ),
                  ),
                  Container(
                    height: 28,
                    width: 1,
                    color: Colors.grey.shade200,
                  ),
                  Expanded(
                    child: _buildRiskGauge(
                      label: 'Frequency',
                      value: patient.frequencyIndicator,
                      color: AppColors.riskMedium,
                      icon: Icons.repeat_rounded,
                    ),
                  ),
                  Container(
                    height: 28,
                    width: 1,
                    color: Colors.grey.shade200,
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        const Text(
                          'Risk Score',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${patient.riskScore}/25',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: riskColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Action Buttons: Accept & Decline
              Row(
                children: [
                  if (onDecline != null) ...[
                    Expanded(
                      flex: 1,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          side: BorderSide(color: Colors.grey.shade300),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () => onDecline!(patient),
                        child: const Text(
                          'Decline',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],

                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        elevation: 1,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () => onAccept(patient),
                      icon: const Icon(Icons.check_circle_outline, size: 18),
                      label: const Text(
                        'Accept Patient',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRiskGauge({
    required String label,
    required int value,
    required Color color,
    required IconData icon,
  }) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 12, color: AppColors.textSecondary),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (index) {
            final isFilled = index < value;
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 1.5),
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: isFilled ? color : Colors.grey.shade300,
                shape: BoxShape.circle,
              ),
            );
          }),
        ),
      ],
    );
  }
}

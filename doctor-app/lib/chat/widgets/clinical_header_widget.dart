import 'package:flutter/material.dart';
import 'package:doctor_app/constants/color.dart';
import 'package:doctor_app/model/mock_data.dart';
import 'package:doctor_app/widget/patient_chart_dialog.dart';

class ClinicalHeaderWidget extends StatelessWidget {
  final PatientModel patient;
  final VoidCallback? onNotesHistoryPressed;

  const ClinicalHeaderWidget({
    super.key,
    required this.patient,
    this.onNotesHistoryPressed,
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
        return Icons.verified_user_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final riskColor = _getRiskColor();
    final riskBgColor = _getRiskBgColor();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Primary Clinical Info Row
          Row(
            children: [
              // Patient Avatar with Risk Badge
              Stack(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: AppColors.primaryLight,
                    backgroundImage: NetworkImage(patient.imageUrl),
                    onBackgroundImageError: (_, __) {},
                    child: Text(
                      patient.name.isNotEmpty ? patient.name[0] : 'P',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: riskColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 10),

              // Patient Name & Gestational Week
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      patient.name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            patient.gestationalAge,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            patient.recentFlaggedSymptom,
                            style: TextStyle(
                              fontSize: 11,
                              color: patient.riskLevel == RiskLevel.high
                                  ? AppColors.riskHigh
                                  : AppColors.textSecondary,
                              fontWeight: patient.riskLevel == RiskLevel.high
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Risk Indicator Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: riskBgColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: riskColor.withValues(alpha: 0.35)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_getRiskIcon(), size: 12, color: riskColor),
                    const SizedBox(width: 4),
                    Text(
                      patient.riskLabel,
                      style: TextStyle(
                        color: riskColor,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Quick Action Links: "Vitals & Symptom Summary" & "Clinical Notes History"
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => PatientChartDialog.show(context, patient),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.monitor_heart_outlined, size: 14, color: AppColors.primary),
                        SizedBox(width: 6),
                        Text(
                          'Vitals & Symptom Summary',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: onNotesHistoryPressed,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.history_edu_rounded, size: 14, color: AppColors.primary),
                      SizedBox(width: 4),
                      Text(
                        'Notes History',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

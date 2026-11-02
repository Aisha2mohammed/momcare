import 'package:flutter/material.dart';
import 'package:doctor_app/constants/color.dart';
import 'package:doctor_app/model/mock_data.dart';
import 'package:doctor_app/chat/chat_detail_screen.dart';
import 'package:doctor_app/widget/patient_chart_dialog.dart';
import 'package:doctor_app/l10n/l10n.dart';

class PatientRiskCardWidget extends StatelessWidget {
  final PatientModel patient;
  final VoidCallback? onChatPressed;
  final VoidCallback? onViewChartPressed;

  const PatientRiskCardWidget({
    super.key,
    required this.patient,
    this.onChatPressed,
    this.onViewChartPressed,
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
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: patient.riskLevel == RiskLevel.high
              ? AppColors.riskHigh.withValues(alpha: 0.35)
              : Colors.grey.shade200,
          width: patient.riskLevel == RiskLevel.high ? 1.4 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: patient.riskLevel == RiskLevel.high
                ? AppColors.riskHigh.withValues(alpha: 0.06)
                : Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Avatar, Patient Name, Phone, Gestational Age, and Risk Badge
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar with Risk ring
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 26,
                      backgroundColor: AppColors.primaryLight,
                      backgroundImage: NetworkImage(patient.imageUrl),
                      onBackgroundImageError: (_, __) {},
                      child: Text(
                        patient.name.isNotEmpty ? patient.name[0] : 'P',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 13,
                        height: 13,
                        decoration: BoxDecoration(
                          color: riskColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 12),

                // Name, Phone, Gestational Age
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        patient.name,
                        style: const TextStyle(
                          fontSize: 16,
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
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              patient.gestationalAge,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              patient.phone,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
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

                // Risk Level Badge (High, Moderate, Stable)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: riskBgColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: riskColor.withValues(alpha: 0.35)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_getRiskIcon(), size: 13, color: riskColor),
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

            const SizedBox(height: 12),

            // Recent Flagged Symptom snippet
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                color: patient.riskLevel == RiskLevel.high
                    ? AppColors.riskHighBg.withValues(alpha: 0.6)
                    : AppColors.background,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: patient.riskLevel == RiskLevel.high
                      ? AppColors.riskHigh.withValues(alpha: 0.25)
                      : Colors.grey.shade200,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    size: 16,
                    color: patient.riskLevel == RiskLevel.high
                        ? AppColors.riskHigh
                        : AppColors.riskModerate,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: RichText(
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      text: TextSpan(
                        children: [
                          const TextSpan(
                            text: 'Flagged: ',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          TextSpan(
                            text: patient.recentFlaggedSymptom,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: patient.riskLevel == RiskLevel.high
                                  ? AppColors.riskHigh
                                  : AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // Last Activity / Logged Symptom Timestamp & Risk Score
            Row(
              children: [
                const Icon(Icons.access_time_rounded, size: 14, color: AppColors.textMuted),
                const SizedBox(width: 4),
                Text(
                  patient.lastActivityTime,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                Text(
                  'Risk Score: ${patient.riskScore}/25',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: riskColor,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),
            const Divider(height: 1),
            const SizedBox(height: 12),

            // Primary Clinical Action Buttons: "Chat Now" and "View Chart"
            Row(
              children: [
                // "Chat Now" icon button
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      visualDensity: VisualDensity.compact,
                    ),
                    onPressed: onChatPressed ??
                        () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ChatDetailScreen(patient: patient),
                            ),
                          );
                        },
                    icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16),
                    label: Text(
                      LocaleNotifier.shared.t('chat_now'),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                // "View Chart" button
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 1,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      visualDensity: VisualDensity.compact,
                    ),
                    onPressed: onViewChartPressed ??
                        () {
                          PatientChartDialog.show(context, patient);
                        },
                    icon: const Icon(Icons.insert_chart_outlined_rounded, size: 16),
                    label: Text(
                      LocaleNotifier.shared.t('view_chart'),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

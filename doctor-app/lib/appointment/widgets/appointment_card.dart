import 'package:flutter/material.dart';
import 'package:doctor_app/constants/color.dart';
import 'package:doctor_app/model/mock_data.dart';
import 'package:intl/intl.dart';

class AppointmentCard extends StatelessWidget {
  final AppointmentModel appointment;
  final VoidCallback onAccept;
  final VoidCallback onRejectSuggest;
  final VoidCallback onStartConsultation;
  final VoidCallback onReschedule;
  final VoidCallback onViewNotes;
  final VoidCallback? onTap;

  const AppointmentCard({
    super.key,
    required this.appointment,
    required this.onAccept,
    required this.onRejectSuggest,
    required this.onStartConsultation,
    required this.onReschedule,
    required this.onViewNotes,
    this.onTap,
  });

  Color _getRiskColor(RiskLevel level) {
    switch (level) {
      case RiskLevel.high:
        return AppColors.riskHigh;
      case RiskLevel.moderate:
        return AppColors.riskModerate;
      case RiskLevel.stable:
        return AppColors.riskStable;
    }
  }

  String _getRiskLabel(RiskLevel level) {
    switch (level) {
      case RiskLevel.high:
        return 'High Risk';
      case RiskLevel.moderate:
        return 'Moderate Risk';
      case RiskLevel.stable:
        return 'Stable';
    }
  }

  @override
  Widget build(BuildContext context) {
    final riskColor = _getRiskColor(appointment.riskLevel);
    final riskText = _getRiskLabel(appointment.riskLevel);
    final dateStr = DateFormat('EEE, MMM d').format(appointment.dateTime);
    final isToday = DateUtils.isSameDay(appointment.dateTime, DateTime.now());
    final displayDate = isToday ? 'Today, ${appointment.timeSlot}' : '$dateStr • ${appointment.timeSlot}';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(
          color: appointment.riskLevel == RiskLevel.high && appointment.isPending
              ? AppColors.riskHigh.withValues(alpha: 0.3)
              : Colors.grey.shade200,
          width: appointment.riskLevel == RiskLevel.high && appointment.isPending ? 1.5 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Identity & Risk Header (Clickable to open Chat Room)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    InkWell(
                      onTap: onStartConsultation,
                      borderRadius: BorderRadius.circular(24),
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundImage: NetworkImage(appointment.patientAvatar),
                            onBackgroundImageError: (_, __) {},
                            child: appointment.patientAvatar.isEmpty
                                ? const Icon(Icons.person, color: Colors.grey)
                                : null,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(3),
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.chat_bubble_rounded, size: 9, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: InkWell(
                        onTap: onStartConsultation,
                        borderRadius: BorderRadius.circular(8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    appointment.patientName,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(Icons.arrow_forward_ios_rounded, size: 11, color: AppColors.primary),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'Gestational: ${appointment.gestationalAge} • Tap to Chat',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Risk Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: riskColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: riskColor.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: riskColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            riskText,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: riskColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 10),

                // Requested Date & Time + Consultation Type Strip
                Row(
                  children: [
                    // Consultation Type Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: appointment.consultationType.color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            appointment.consultationType.icon,
                            size: 14,
                            color: appointment.consultationType.color,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            appointment.consultationType.label,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: appointment.consultationType.color,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Date & Time Slot Badge
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.access_time_rounded, size: 14, color: AppColors.primary),
                            const SizedBox(width: 5),
                            Flexible(
                              child: Text(
                                displayDate,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Clinical Type & Description
                Text(
                  appointment.type,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  appointment.description,
                  style: const TextStyle(
                    fontSize: 12,
                    height: 1.4,
                    color: AppColors.textSecondary,
                  ),
                ),

                // If Cancelled or Rejected: Show Rejection details & suggested alternatives
                if (appointment.isCancelled) ...[
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.cancel_outlined, size: 16, color: Colors.red),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Reason: ${appointment.rejectionReason ?? "Appointment cancelled"}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red.shade900,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (appointment.suggestedAlternativeSlots != null &&
                            appointment.suggestedAlternativeSlots!.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          const Text(
                            'Alternative Slots Offered to Mother:',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: appointment.suggestedAlternativeSlots!.map((slot) {
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: Colors.red.shade200),
                                ),
                                child: Text(
                                  slot,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.red.shade800,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],

                // If Completed: Show completed badge indicator
                if (appointment.isCompleted) ...[
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.riskStable.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: const [
                        Icon(Icons.check_circle_rounded, size: 16, color: AppColors.riskStable),
                        SizedBox(width: 6),
                        Text(
                          'Consultation Completed & Clinical Notes Stored',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.riskStable,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 14),

                // Interactive Action Buttons by Status
                _buildActionButtons(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    if (appointment.isPending) {
      return Row(
        children: [
          // [Reject / Suggest Alternative] Button
          Expanded(
            child: OutlinedButton(
              onPressed: onRejectSuggest,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                side: BorderSide(color: Colors.red.shade200),
                foregroundColor: Colors.red.shade700,
              ),
              child: const Text(
                'Reject / Suggest Alt',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(width: 10),

          // [Accept] Button
          Expanded(
            child: ElevatedButton(
              onPressed: onAccept,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: const Text(
                'Accept',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      );
    } else if (appointment.isUpcoming) {
      return Row(
        children: [
          // [Reschedule] Button
          Expanded(
            child: OutlinedButton.icon(
              onPressed: onReschedule,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                side: BorderSide(color: Colors.grey.shade300),
                foregroundColor: AppColors.textPrimary,
              ),
              icon: const Icon(Icons.edit_calendar_rounded, size: 16),
              label: const Text(
                'Reschedule',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(width: 10),

          // [Start Consultation / Chat] Button
          Expanded(
            child: ElevatedButton.icon(
              onPressed: onStartConsultation,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              icon: Icon(
                appointment.consultationType == ConsultationType.videoCall
                    ? Icons.videocam_rounded
                    : Icons.chat_rounded,
                size: 16,
              ),
              label: Text(
                appointment.consultationType == ConsultationType.videoCall ? 'Start Call' : 'Start Consult',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      );
    } else if (appointment.isCompleted) {
      return SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: onViewNotes,
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            side: const BorderSide(color: AppColors.primary),
            foregroundColor: AppColors.primary,
          ),
          icon: const Icon(Icons.description_outlined, size: 18),
          label: const Text(
            'View Clinical Notes & Prescriptions',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ),
      );
    } else {
      // Cancelled / Rejected: Option to contact mother
      return SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: onStartConsultation,
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            side: BorderSide(color: Colors.grey.shade300),
            foregroundColor: AppColors.textSecondary,
          ),
          icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16),
          label: const Text(
            'Message Patient / Follow-up',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ),
      );
    }
  }
}

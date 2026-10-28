import 'package:flutter/material.dart';
import 'package:doctor_app/constants/color.dart';
import 'package:doctor_app/model/mock_data.dart';
import 'package:doctor_app/widget/patient_risk_card_widget.dart';
import 'package:doctor_app/chat/chat_detail_screen.dart';
import 'package:doctor_app/widget/patient_chart_dialog.dart';

class PatientListWidget extends StatelessWidget {
  final List<PatientModel> patients;
  final ValueChanged<PatientModel>? onAccept;
  final ValueChanged<PatientModel>? onDecline;
  final ValueChanged<PatientModel>? onChat;
  final ValueChanged<PatientModel>? onViewChart;
  final String emptyTitle;
  final String emptySubtitle;
  final EdgeInsetsGeometry padding;
  final bool shrinkWrap;
  final ScrollPhysics? physics;

  const PatientListWidget({
    super.key,
    required this.patients,
    this.onAccept,
    this.onDecline,
    this.onChat,
    this.onViewChart,
    this.emptyTitle = 'No Patients Found',
    this.emptySubtitle = 'There are no patients matching the selected filter.',
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    this.shrinkWrap = false,
    this.physics,
  });

  @override
  Widget build(BuildContext context) {
    if (patients.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: const BoxDecoration(
                  color: AppColors.primaryLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person_search_rounded,
                  size: 44,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                emptyTitle,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                emptySubtitle,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: padding,
      shrinkWrap: shrinkWrap,
      physics: physics ?? const BouncingScrollPhysics(),
      itemCount: patients.length,
      itemBuilder: (context, index) {
        final patient = patients[index];
        return PatientRiskCardWidget(
          key: ValueKey(patient.id),
          patient: patient,
          onChatPressed: () {
            if (onChat != null) {
              onChat!(patient);
            } else {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatDetailScreen(patient: patient),
                ),
              );
            }
          },
          onViewChartPressed: () {
            if (onViewChart != null) {
              onViewChart!(patient);
            } else {
              PatientChartDialog.show(context, patient);
            }
          },
          onAccept: onAccept,
          onDecline: onDecline,
        );
      },
    );
  }
}

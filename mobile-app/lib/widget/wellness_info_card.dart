import 'package:flutter/material.dart';
import 'package:pregnancy_appp/constants/color.dart';
import 'package:pregnancy_appp/l10n/l10n.dart';

class WellnessInfoCard extends StatelessWidget {
  final String icon;
  final String title;
  final String content;
  final Color backgroundColor;
  final Color borderColor;
  final Color titleColor;
  final Color contentColor;

  const WellnessInfoCard({
    super.key,
    required this.icon,
    required this.title,
    required this.content,
    required this.backgroundColor,
    required this.borderColor,
    required this.titleColor,
    required this.contentColor,
  });

  /// Specialized constructor for "Why This Is Important"
  factory WellnessInfoCard.whyImportant({
    Key? key,
    required BuildContext context,
    required String content,
  }) {
    return WellnessInfoCard(
      key: key,
      icon: '💡',
      title: AppStrings.of(context, 'why_this_is_important'),
      content: content,
      backgroundColor: AppColors.primary.withValues(alpha: 0.07),
      borderColor: AppColors.primary.withValues(alpha: 0.22),
      titleColor: AppColors.primary,
      contentColor: const Color(0xFF424242),
    );
  }

  /// Specialized constructor for "Hydration"
  factory WellnessInfoCard.hydration({
    Key? key,
    required BuildContext context,
    required String content,
  }) {
    return WellnessInfoCard(
      key: key,
      icon: '💧',
      title: AppStrings.of(context, 'hydration'),
      content: content,
      backgroundColor: const Color(0xFFE3F2FD),
      borderColor: const Color(0xFF90CAF9),
      titleColor: const Color(0xFF1565C0),
      contentColor: const Color(0xFF0D47A1),
    );
  }

  /// Specialized constructor for "Exercise Tips"
  factory WellnessInfoCard.exerciseTips({
    Key? key,
    required BuildContext context,
    required String content,
  }) {
    return WellnessInfoCard(
      key: key,
      icon: '🏃‍♀️',
      title: AppStrings.of(context, 'exercise_tips'),
      content: content,
      backgroundColor: const Color(0xFFE8F5E9),
      borderColor: const Color(0xFFA5D6A7),
      titleColor: const Color(0xFF2E7D32),
      contentColor: const Color(0xFF1B5E20),
    );
  }

  /// Specialized constructor for "Sleeping Tips"
  factory WellnessInfoCard.sleepingTips({
    Key? key,
    required BuildContext context,
    required String content,
  }) {
    return WellnessInfoCard(
      key: key,
      icon: '🌙',
      title: AppStrings.of(context, 'sleeping_tips'),
      content: content,
      backgroundColor: const Color(0xFFEDE7F6),
      borderColor: const Color(0xFFD1C4E9),
      titleColor: const Color(0xFF512DA8),
      contentColor: const Color(0xFF311B92),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (content.trim().isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(icon, style: const TextStyle(fontSize: 22)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14.5,
                    color: titleColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  content,
                  style: TextStyle(
                    fontSize: 13,
                    color: contentColor,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

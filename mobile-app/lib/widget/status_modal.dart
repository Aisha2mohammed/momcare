import 'package:flutter/material.dart';
import 'package:pregnancy_appp/constants/color.dart';

/// Highly polished, reusable modal dialog for Success and Failure states
/// Used across authentication, profile updates, and action confirmations.
class AppStatusModal extends StatelessWidget {
  final bool isSuccess;
  final String title;
  final String message;
  final String buttonText;
  final VoidCallback? onDismiss;

  const AppStatusModal({
    super.key,
    required this.isSuccess,
    required this.title,
    required this.message,
    required this.buttonText,
    this.onDismiss,
  });

  /// Show Success Modal Dialog
  static Future<void> showSuccess({
    required BuildContext context,
    required String title,
    required String message,
    String buttonText = 'Continue',
    VoidCallback? onDismiss,
  }) {
    return show(
      context: context,
      isSuccess: true,
      title: title,
      message: message,
      buttonText: buttonText,
      onDismiss: onDismiss,
    );
  }

  /// Show Error/Fail Modal Dialog
  static Future<void> showError({
    required BuildContext context,
    required String title,
    required String message,
    String buttonText = 'Try Again',
    VoidCallback? onDismiss,
  }) {
    return show(
      context: context,
      isSuccess: false,
      title: title,
      message: message,
      buttonText: buttonText,
      onDismiss: onDismiss,
    );
  }

  /// Show generic status dialog (Success or Fail)
  static Future<void> show({
    required BuildContext context,
    required bool isSuccess,
    required String title,
    required String message,
    String? buttonText,
    VoidCallback? onDismiss,
  }) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'StatusDialog',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 250),
      transitionBuilder: (context, anim1, anim2, child) {
        final curve = CurvedAnimation(parent: anim1, curve: Curves.easeOutBack);
        return ScaleTransition(
          scale: curve,
          child: FadeTransition(opacity: anim1, child: child),
        );
      },
      pageBuilder: (dialogContext, _, __) {
        return AppStatusModal(
          isSuccess: isSuccess,
          title: title,
          message: message,
          buttonText: buttonText ?? (isSuccess ? 'Continue' : 'Close'),
          onDismiss: onDismiss,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = isSuccess ? const Color(0xFF10B981) : const Color(0xFFEF4444);
    final bgTint = isSuccess ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2);
    final iconData = isSuccess ? Icons.check_rounded : Icons.priority_high_rounded;

    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.86,
          constraints: const BoxConstraints(maxWidth: 380),
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: themeColor.withValues(alpha: 0.15),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
              const BoxShadow(
                color: Colors.black12,
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Animated Icon Ring
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  color: bgTint,
                  shape: BoxShape.circle,
                  border: Border.all(color: themeColor.withValues(alpha: 0.25), width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: themeColor.withValues(alpha: 0.2),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: themeColor,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      iconData,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 22),

              // Title
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                  letterSpacing: -0.3,
                ),
              ),

              const SizedBox(height: 10),

              // Message
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14.5,
                  color: Colors.grey[600],
                  height: 1.45,
                ),
              ),

              const SizedBox(height: 26),

              // Action Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isSuccess ? AppColors.primary : const Color(0xFFEF4444),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    shadowColor: Colors.transparent,
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                    if (onDismiss != null) {
                      onDismiss!();
                    }
                  },
                  child: Text(
                    buttonText,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:doctor_app/constants/color.dart';

/// Modal types supported by the feedback dialog system
enum ModalType { success, fail }

class StatusModalDialog extends StatelessWidget {
  final ModalType type;
  final String title;
  final String message;
  final String? primaryButtonText;
  final String? secondaryButtonText;
  final VoidCallback? onPrimaryPressed;
  final VoidCallback? onSecondaryPressed;
  final Widget? customContent;

  const StatusModalDialog({
    super.key,
    required this.type,
    required this.title,
    required this.message,
    this.primaryButtonText,
    this.secondaryButtonText,
    this.onPrimaryPressed,
    this.onSecondaryPressed,
    this.customContent,
  });

  bool get isSuccess => type == ModalType.success;

  @override
  Widget build(BuildContext context) {
    final themeColor = isSuccess ? AppColors.success : AppColors.error;
    final bgColor = isSuccess ? AppColors.successBg : AppColors.errorBg;
    final defaultPrimaryText = isSuccess ? 'Continue' : 'Try Again';

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 12,
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon with concentric decorative rings
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: bgColor,
                shape: BoxShape.circle,
                border: Border.all(
                  color: themeColor.withValues(alpha: 0.2),
                  width: 3,
                ),
                boxShadow: [
                  BoxShadow(
                    color: themeColor.withValues(alpha: 0.15),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Icon(
                isSuccess ? Icons.check_circle_rounded : Icons.error_outline_rounded,
                size: 54,
                color: themeColor,
              ),
            ),
            const SizedBox(height: 20),

            // Modal Title
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 10),

            // Modal Message
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.45,
              ),
            ),

            if (customContent != null) ...[
              const SizedBox(height: 16),
              customContent!,
            ],

            const SizedBox(height: 28),

            // Action Buttons
            Row(
              children: [
                if (secondaryButtonText != null) ...[
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(color: Colors.grey.shade300),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () {
                        Navigator.of(context).pop(false);
                        onSecondaryPressed?.call();
                      },
                      child: Text(
                        secondaryButtonText!,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],

                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isSuccess ? AppColors.primary : AppColors.error,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 2,
                      shadowColor: (isSuccess ? AppColors.primary : AppColors.error).withValues(alpha: 0.4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop(true);
                      onPrimaryPressed?.call();
                    },
                    child: Text(
                      primaryButtonText ?? defaultPrimaryText,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
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

/// Standalone Success Modal Widget
class AppSuccessModal extends StatelessWidget {
  final String title;
  final String message;
  final String? primaryButtonText;
  final String? secondaryButtonText;
  final VoidCallback? onPrimaryPressed;
  final VoidCallback? onSecondaryPressed;
  final Widget? customContent;

  const AppSuccessModal({
    super.key,
    required this.title,
    required this.message,
    this.primaryButtonText = 'Done',
    this.secondaryButtonText,
    this.onPrimaryPressed,
    this.onSecondaryPressed,
    this.customContent,
  });

  @override
  Widget build(BuildContext context) {
    return StatusModalDialog(
      type: ModalType.success,
      title: title,
      message: message,
      primaryButtonText: primaryButtonText,
      secondaryButtonText: secondaryButtonText,
      onPrimaryPressed: onPrimaryPressed,
      onSecondaryPressed: onSecondaryPressed,
      customContent: customContent,
    );
  }
}

/// Standalone Fail / Error Modal Widget
class AppFailModal extends StatelessWidget {
  final String title;
  final String message;
  final String? primaryButtonText;
  final String? secondaryButtonText;
  final VoidCallback? onPrimaryPressed;
  final VoidCallback? onSecondaryPressed;
  final Widget? customContent;

  const AppFailModal({
    super.key,
    required this.title,
    required this.message,
    this.primaryButtonText = 'Try Again',
    this.secondaryButtonText = 'Dismiss',
    this.onPrimaryPressed,
    this.onSecondaryPressed,
    this.customContent,
  });

  @override
  Widget build(BuildContext context) {
    return StatusModalDialog(
      type: ModalType.fail,
      title: title,
      message: message,
      primaryButtonText: primaryButtonText,
      secondaryButtonText: secondaryButtonText,
      onPrimaryPressed: onPrimaryPressed,
      onSecondaryPressed: onSecondaryPressed,
      customContent: customContent,
    );
  }
}

/// Global helper for quickly showing success and fail modals across the app
class AppModals {
  /// Displays a smooth animated Success Modal
  static Future<bool?> showSuccess(
    BuildContext context, {
    required String title,
    required String message,
    String? primaryButtonText = 'Great, Continue',
    String? secondaryButtonText,
    VoidCallback? onConfirm,
    VoidCallback? onDismiss,
    Widget? customContent,
  }) {
    return showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Success Modal',
      barrierColor: Colors.black.withValues(alpha: 0.5),
      transitionDuration: const Duration(milliseconds: 280),
      transitionBuilder: (context, anim1, anim2, child) {
        return Transform.scale(
          scale: Curves.easeOutBack.transform(anim1.value),
          child: Opacity(
            opacity: anim1.value,
            child: child,
          ),
        );
      },
      pageBuilder: (context, anim1, anim2) {
        return AppSuccessModal(
          title: title,
          message: message,
          primaryButtonText: primaryButtonText,
          secondaryButtonText: secondaryButtonText,
          onPrimaryPressed: onConfirm,
          onSecondaryPressed: onDismiss,
          customContent: customContent,
        );
      },
    );
  }

  /// Displays a smooth animated Fail / Error Modal
  static Future<bool?> showFail(
    BuildContext context, {
    required String title,
    required String message,
    String? primaryButtonText = 'Try Again',
    String? secondaryButtonText = 'Cancel',
    VoidCallback? onRetry,
    VoidCallback? onCancel,
    Widget? customContent,
  }) {
    return showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Fail Modal',
      barrierColor: Colors.black.withValues(alpha: 0.5),
      transitionDuration: const Duration(milliseconds: 280),
      transitionBuilder: (context, anim1, anim2, child) {
        return Transform.scale(
          scale: Curves.easeOutBack.transform(anim1.value),
          child: Opacity(
            opacity: anim1.value,
            child: child,
          ),
        );
      },
      pageBuilder: (context, anim1, anim2) {
        return AppFailModal(
          title: title,
          message: message,
          primaryButtonText: primaryButtonText,
          secondaryButtonText: secondaryButtonText,
          onPrimaryPressed: onRetry,
          onSecondaryPressed: onCancel,
          customContent: customContent,
        );
      },
    );
  }
}

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:doctor_app/constants/color.dart';
import 'package:doctor_app/auth/auth_service.dart';
import 'package:doctor_app/auth/otp_screen.dart';
import 'package:doctor_app/auth/login_screen.dart';
import 'package:doctor_app/widget/status_modal.dart';

class PendingApprovalScreen extends StatefulWidget {
  final String? phone;
  final String? name;
  final String? licenseNumber;
  final String? specialization;

  const PendingApprovalScreen({
    super.key,
    this.phone,
    this.name,
    this.licenseNumber,
    this.specialization,
  });

  @override
  State<PendingApprovalScreen> createState() => _PendingApprovalScreenState();
}

class _PendingApprovalScreenState extends State<PendingApprovalScreen>
    with SingleTickerProviderStateMixin {
  bool _isChecking = false;
  bool _isLoggingOut = false;
  String _accountStatus = 'pending'; // 'pending' | 'active' | 'rejected'
  String? _userPhone;
  String? _userName;
  String? _licenseNumber;
  String? _specialization;

  Timer? _pollTimer;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _userPhone = widget.phone;
    _userName = widget.name;
    _licenseNumber = widget.licenseNumber;
    _specialization = widget.specialization;

    _resolveUserDetails();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.92, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Auto poll backend every 5 seconds for admin approval
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted && _accountStatus == 'pending') {
        _checkApprovalStatus(silent: true);
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkApprovalStatus(silent: true);
    });
  }

  Future<void> _resolveUserDetails() async {
    final cur = await AuthService.instance.getCurrentUser();
    if (mounted) {
      setState(() {
        _userPhone ??= cur['phone'];
        _userName ??= cur['name'];
        _licenseNumber ??= cur['licenseNumber'];
        _specialization ??= cur['specialization'];
      });
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _checkApprovalStatus({bool silent = false}) async {
    if (_isChecking) return;
    if (!silent) setState(() => _isChecking = true);

    try {
      final data = await AuthService.instance.checkStatus();
      if (!mounted) return;

      final isApproved = data['isApproved'] == true;
      final isRejected = data['isRejected'] == true;
      _accountStatus = data['status']?.toString() ?? 'pending';

      final user = data['user'] as Map<String, dynamic>? ?? {};
      final phone = user['phone']?.toString() ?? _userPhone;
      if (phone != null && phone.isNotEmpty) {
        _userPhone = phone;
      }

      if (isApproved) {
        _onAccountApproved(targetPhone: phone);
        return;
      }

      if (isRejected) {
        setState(() => _accountStatus = 'rejected');
        _pollTimer?.cancel();
        if (!silent) {
          AppModals.showFail(
            context,
            title: 'Application Not Approved',
            message: 'Your doctor registration was reviewed and could not be approved at this time. Please contact MomCare administration.',
          );
        }
        return;
      }

      // Still pending
      setState(() => _accountStatus = 'pending');
      if (!silent) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            content: const Text(
              'Your profile is still under admin review. Once approved, an OTP will be dispatched via AfroMessage to your phone!',
              style: TextStyle(color: Colors.white),
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (!silent && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not check status: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted && !silent) {
        setState(() => _isChecking = false);
      }
    }
  }

  void _onAccountApproved({String? targetPhone}) async {
    _pollTimer?.cancel();
    setState(() => _accountStatus = 'active');

    final phone = targetPhone ?? _userPhone ?? '';

    // Request AfroMessage OTP automatically upon approval
    if (phone.isNotEmpty) {
      try {
        await AuthService.instance.sendOtp(phone: phone);
      } catch (e) {
        debugPrint('[PendingApproval] Note sending OTP: $e');
      }
    }

    if (!mounted) return;

    AppModals.showSuccess(
      context,
      title: 'Doctor Account Approved! 🎉',
      message: phone.isNotEmpty
          ? 'Your doctor account has been approved by the MomCare administrator! A 6-digit login verification code was sent to $phone via AfroMessage SMS.\n\nPlease verify your login to access your clinical dashboard.'
          : 'Your doctor account has been approved! Please verify your login to continue.',
      primaryButtonText: 'Verify OTP & Enter',
      onConfirm: () {
        if (!mounted) return;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => OtpScreen(
              phone: phone,
              isLogin: true,
            ),
          ),
          (route) => false,
        );
      },
    );
  }

  Future<void> _handleLogout() async {
    setState(() => _isLoggingOut = true);
    _pollTimer?.cancel();
    await AuthService.instance.logout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isRejected = _accountStatus == 'rejected';

    return Scaffold(
      backgroundColor: const Color(0xFFFAF7F5),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () => _checkApprovalStatus(silent: false),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),

                // Pulsing Status Icon
                ScaleTransition(
                  scale: _pulseAnimation,
                  child: Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isRejected ? AppColors.errorBg : const Color(0xFFFBF0F5),
                      border: Border.all(
                        color: isRejected ? AppColors.error : AppColors.primary,
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (isRejected ? AppColors.error : AppColors.primary).withValues(alpha: 0.15),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Icon(
                      isRejected ? Icons.cancel_outlined : Icons.verified_user_rounded,
                      size: 56,
                      color: isRejected ? AppColors.error : AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                // Main Heading
                Text(
                  isRejected ? 'Application Not Approved' : 'Waiting for Admin Approval',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isRejected ? AppColors.error : AppColors.primary,
                    letterSpacing: -0.3,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),

                // Subtitle
                Text(
                  isRejected
                      ? 'Your registration was reviewed and could not be approved at this time. Please contact support.'
                      : 'Your doctor profile and medical credentials have been submitted. An administrator will review and verify your application shortly.',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),

                // Credentials Summary Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey.shade200),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.badge_rounded, color: AppColors.primary, size: 20),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Submitted Credentials',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      _buildDetailRow(Icons.person_outline, 'Doctor Name', _userName ?? 'Doctor'),
                      if (_specialization != null && _specialization!.isNotEmpty)
                        _buildDetailRow(Icons.local_hospital_outlined, 'Specialization', _specialization!),
                      if (_licenseNumber != null && _licenseNumber!.isNotEmpty)
                        _buildDetailRow(Icons.credit_card_outlined, 'License Number', _licenseNumber!),
                      if (_userPhone != null && _userPhone!.isNotEmpty)
                        _buildDetailRow(Icons.phone_outlined, 'Registered Phone', _userPhone!),
                      _buildDetailRow(
                        Icons.hourglass_top_rounded,
                        'Verification Status',
                        isRejected ? 'Rejected' : 'Under Review (Pending)',
                        valueColor: isRejected ? AppColors.error : const Color(0xFFD97706),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // What Happens Next Card
                if (!isRejected)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFBFDBFE)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.info_outline_rounded, color: Color(0xFF2563EB), size: 22),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'What happens next?',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1E40AF),
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                '1. Admin verifies your license in the dashboard.\n2. Once approved, AfroMessage sends a 6-digit verification code to your phone.\n3. Verify your OTP to enter your clinical dashboard.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF1E3A8A),
                                  height: 1.45,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 32),

                // Check Status Button
                if (!isRejected) ...[
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isChecking ? null : () => _checkApprovalStatus(silent: false),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: _isChecking
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                            )
                          : const Text(
                              'Check Approval Status',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // Logout / Back to Login
                TextButton.icon(
                  onPressed: _isLoggingOut ? null : _handleLogout,
                  icon: const Icon(Icons.logout_rounded, size: 18, color: AppColors.textSecondary),
                  label: _isLoggingOut
                      ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text(
                          'Back to Login',
                          style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade500),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                const SizedBox(height: 1),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: valueColor ?? AppColors.textPrimary,
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

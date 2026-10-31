import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:doctor_app/constants/color.dart';
import 'package:doctor_app/auth/auth_service.dart';
import 'package:doctor_app/auth/login_screen.dart';
import 'package:doctor_app/auth/pending_approval_screen.dart';
import 'package:doctor_app/home/main_screen.dart';
import 'package:doctor_app/widget/status_modal.dart';

class OtpScreen extends StatefulWidget {
  final String phone;
  final bool isLogin;
  final bool isAdminVerification;

  const OtpScreen({
    super.key,
    this.phone = '',
    this.isLogin = true,
    this.isAdminVerification = false,
  });

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  bool _isLoading = false;
  bool _isResending = false;
  int _resendCountdown = 60;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() {
    _resendCountdown = 60;
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_resendCountdown > 0) {
        setState(() => _resendCountdown--);
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  String get _otpCode => _controllers.map((c) => c.text.trim()).join();

  Future<void> _handleVerify() async {
    final otp = _otpCode;
    if (otp.length != 6) {
      AppModals.showFail(
        context,
        title: 'Incomplete Code',
        message: 'Please enter all 6 digits of the verification code.',
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final res = await AuthService.instance.verifyOtp(
        phone: widget.phone,
        otp: otp,
      );

      if (!mounted) return;

      final user = res['user'] as Map<String, dynamic>? ?? {};
      final status = (user['status'] as String? ?? 'active').toLowerCase();
      final doctorProfile = user['doctorProfile'] as Map<String, dynamic>?;
      final approvalStatus = (doctorProfile?['approval_status'] as String? ?? 'approved').toLowerCase();

      AppModals.showSuccess(
        context,
        title: 'Verified Successfully! 🎉',
        message: 'Your phone number has been verified via AfroMessage.',
        primaryButtonText: 'Enter Dashboard',
        onConfirm: () {
          if (!mounted) return;
          if (status == 'pending' || approvalStatus == 'pending') {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => PendingApprovalScreen(phone: widget.phone)),
              (route) => false,
            );
          } else {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const MainScreen()),
              (route) => false,
            );
          }
        },
      );
    } catch (e) {
      if (!mounted) return;
      AppModals.showFail(
        context,
        title: 'Verification Failed',
        message: e.toString(),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleResend() async {
    if (_resendCountdown > 0 || _isResending) return;

    setState(() => _isResending = true);
    try {
      await AuthService.instance.sendOtp(phone: widget.phone);
      if (!mounted) return;
      _startCountdown();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('A new 6-digit code was sent to ${widget.phone} via AfroMessage SMS.'),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      AppModals.showFail(
        context,
        title: 'Could Not Resend Code',
        message: e.toString(),
      );
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF7F5),
      appBar: AppBar(
        title: const Text('Phone Verification', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0.5,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // AfroMessage Shield Icon
              Center(
                child: Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.mark_email_read_rounded,
                    size: 46,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              const Text(
                'Enter Verification Code',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                  letterSpacing: -0.3,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),

              Text(
                widget.phone.isNotEmpty
                    ? 'A 6-digit verification code was sent via AfroMessage SMS to:\n${widget.phone}'
                    : 'Enter the 6-digit code sent to your registered phone number via AfroMessage.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 36),

              // 6 PIN Input Boxes
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(6, (index) => _buildDigitBox(index)),
              ),
              const SizedBox(height: 36),

              // Verify Button
              ElevatedButton(
                onPressed: _isLoading ? null : _handleVerify,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  elevation: 1,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                      )
                    : const Text(
                        'Verify Code & Continue',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
              ),
              const SizedBox(height: 24),

              // Resend Timer Row
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Didn't receive the SMS? ", style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                  if (_resendCountdown > 0)
                    Text(
                      'Resend in ${_resendCountdown}s',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    )
                  else
                    GestureDetector(
                      onTap: _isResending ? null : _handleResend,
                      child: _isResending
                          ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text(
                              'Resend Code',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                    ),
                ],
              ),
              const SizedBox(height: 16),

              // Change Phone / Login link
              TextButton(
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                    (route) => false,
                  );
                },
                child: const Text('Back to Login', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDigitBox(int index) {
    return SizedBox(
      width: 46,
      height: 56,
      child: TextFormField(
        controller: _controllers[index],
        focusNode: _focusNodes[index],
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primary),
        inputFormatters: [
          LengthLimitingTextInputFormatter(1),
          FilteringTextInputFormatter.digitsOnly,
        ],
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white,
          counterText: '',
          contentPadding: EdgeInsets.zero,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primary, width: 2),
          ),
        ),
        onChanged: (val) {
          if (val.isNotEmpty && index < 5) {
            _focusNodes[index + 1].requestFocus();
          } else if (val.isEmpty && index > 0) {
            _focusNodes[index - 1].requestFocus();
          }
          if (index == 5 && val.isNotEmpty && _otpCode.length == 6) {
            _handleVerify();
          }
        },
      ),
    );
  }
}

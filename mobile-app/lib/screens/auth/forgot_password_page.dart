import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pregnancy_appp/constants/color.dart';
import 'package:pregnancy_appp/services/api_service.dart';
import 'package:pregnancy_appp/services/auth_service.dart';
import 'package:pregnancy_appp/widget/status_modal.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();

  bool _isSending = false;
  bool _isSubmitting = false;
  bool _otpSent = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _requestReset() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      AppStatusModal.showError(
        context: context,
        title: 'Phone Required',
        message: 'Please enter your phone number to receive a reset code.',
      );
      return;
    }

    setState(() => _isSending = true);
    try {
      await AuthService.forgotPassword(phone: phone);
      if (!mounted) return;
      setState(() => _otpSent = true);
      AppStatusModal.showSuccess(
        context: context,
        title: 'Reset Code Sent',
        message: 'A 6-digit verification code was sent to $phone.',
        buttonText: 'Enter Code',
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      AppStatusModal.showError(
        context: context,
        title: 'Request Failed',
        message: e.message,
      );
    } catch (e) {
      if (!mounted) return;
      AppStatusModal.showError(
        context: context,
        title: 'Connection Error',
        message: 'Network error. Please try again.',
      );
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _submitReset() async {
    final otp = _otpController.text.trim();
    final password = _passwordController.text;
    if (otp.isEmpty || otp.length != 6) {
      AppStatusModal.showError(
        context: context,
        title: 'Invalid Code',
        message: 'Please enter the complete 6-digit code received.',
      );
      return;
    }
    if (password.length < 6) {
      AppStatusModal.showError(
        context: context,
        title: 'Short Password',
        message: 'Password must be at least 6 characters long.',
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await AuthService.resetPassword(
        phone: _phoneController.text.trim(),
        otp: otp,
        password: password,
      );
      if (!mounted) return;
      AppStatusModal.showSuccess(
        context: context,
        title: 'Password Updated!',
        message: 'Your password was reset successfully. Please log in with your new password.',
        buttonText: 'Back to Login',
        onDismiss: () {
          if (!mounted) return;
          Navigator.pop(context);
        },
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      AppStatusModal.showError(
        context: context,
        title: 'Reset Failed',
        message: e.message,
      );
    } catch (e) {
      if (!mounted) return;
      AppStatusModal.showError(
        context: context,
        title: 'Connection Error',
        message: 'Network error. Please try again.',
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                Text(
                  _otpSent ? 'Reset Password' : 'Forgot Password',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  _otpSent
                      ? 'Enter the 6-digit reset code sent to ${_phoneController.text.trim()} and choose a new password.'
                      : 'Enter your phone number and we will send you a 6-digit reset code.',
                  style: const TextStyle(fontSize: 16, color: Colors.black54),
                ),
                const SizedBox(height: 40),

                if (!_otpSent) ...[
                  const Text('Phone number', style: TextStyle(fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      hintText: '+2519XXXXXXXX',
                      hintStyle: const TextStyle(color: Colors.black38),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.primary),
                      ),
                      suffixIcon: const Icon(Icons.phone_outlined, color: Colors.black54),
                    ),
                  ),
                ] else ...[
                  const Text('Reset code', style: TextStyle(fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _otpController,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 8),
                    decoration: InputDecoration(
                      counterText: "",
                      hintText: '------',
                      hintStyle: const TextStyle(color: Colors.black26, letterSpacing: 8),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.primary),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('New password', style: TextStyle(fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      hintText: 'At least 6 characters',
                      hintStyle: const TextStyle(color: Colors.black38),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.primary),
                      ),
                      suffixIcon: const Icon(Icons.lock_outline, color: Colors.black54),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _isSending ? null : _requestReset,
                      child: _isSending
                          ? const SizedBox(
                              height: 14,
                              width: 14,
                              child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2),
                            )
                          : const Text('Resend code', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],

                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: (_isSending || _isSubmitting)
                      ? null
                      : (_otpSent ? _submitReset : _requestReset),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSending || _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : Text(
                          _otpSent ? 'Reset Password' : 'Send Reset Code',
                          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
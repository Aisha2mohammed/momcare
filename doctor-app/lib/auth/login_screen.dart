import 'package:flutter/material.dart';
import 'package:doctor_app/constants/color.dart';
import 'package:doctor_app/auth/auth_service.dart';
import 'package:doctor_app/auth/register_screen.dart';
import 'package:doctor_app/auth/pending_approval_screen.dart';
import 'package:doctor_app/auth/otp_screen.dart';
import 'package:doctor_app/home/main_screen.dart';
import 'package:doctor_app/widget/status_modal.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final name = _nameController.text.trim();
      final phone = _phoneController.text.trim();

      final result = await AuthService.instance.login(
        phone: phone,
        name: name,
      );

      if (!mounted) return;

      final isPending = result['isPending'] == true;
      final user = result['user'] as Map<String, dynamic>? ?? {};

      if (isPending) {
        // Pending approval in admin -> direct to PendingApprovalScreen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => PendingApprovalScreen(
              phone: phone,
              name: user['name'] as String?,
            ),
          ),
        );
      } else {
        // Approved and active -> Home Page
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainScreen()),
        );
      }
    } catch (e) {
      if (!mounted) return;
      AppModals.showFail(
        context,
        title: 'Login Failed',
        message: e.toString(),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleLoginWithOtp() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      AppModals.showFail(
        context,
        title: 'Phone Required',
        message: 'Please enter your phone number to receive a login verification code via AfroMessage SMS.',
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await AuthService.instance.sendOtp(phone: phone);
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => OtpScreen(phone: phone, isLogin: true),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      AppModals.showFail(
        context,
        title: 'Could Not Send OTP',
        message: e.toString(),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF7F5),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo / Icon
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
                      child: const Icon(Icons.local_hospital_rounded, size: 48, color: AppColors.primary),
                    ),
                  ),
                  const SizedBox(height: 24),

                  const Text(
                    'Welcome Back, Doctor',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                      letterSpacing: -0.3,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Sign in to access clinical appointments, patient triage, and maternal consultations.',
                    style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 36),

                  // Doctor Full Name input
                  TextFormField(
                    controller: _nameController,
                    keyboardType: TextInputType.name,
                    textCapitalization: TextCapitalization.words,
                    style: const TextStyle(fontSize: 14),
                    decoration: InputDecoration(
                      labelText: 'Doctor Full Name',
                      hintText: 'e.g. Dr. Sarah Jenkins',
                      prefixIcon: const Icon(Icons.person_outline, color: AppColors.primary, size: 22),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
                    ),
                    validator: (value) => value == null || value.trim().isEmpty ? 'Doctor full name is required' : null,
                  ),
                  const SizedBox(height: 16),

                  // Phone input
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    style: const TextStyle(fontSize: 14),
                    decoration: InputDecoration(
                      labelText: 'Phone Number',
                      hintText: 'e.g. 0912345678 or +2519...',
                      prefixIcon: const Icon(Icons.phone_outlined, color: AppColors.primary, size: 22),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
                    ),
                    validator: (value) => value == null || value.trim().isEmpty ? 'Phone number is required' : null,
                  ),
                  const SizedBox(height: 12),

                  // Login with OTP option
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _isLoading ? null : _handleLoginWithOtp,
                      child: const Text(
                        'Login with AfroMessage OTP SMS',
                        style: TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Login Button
                  ElevatedButton(
                    onPressed: _isLoading ? null : _handleLogin,
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
                            'Log In to Clinical Dashboard',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                  ),
                  const SizedBox(height: 28),

                  // Register Link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Don't have a doctor account? ", style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                      GestureDetector(
                        onTap: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (context) => const RegisterScreen()),
                          );
                        },
                        child: const Text(
                          'Register Here',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

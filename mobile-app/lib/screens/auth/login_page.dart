import 'package:flutter/material.dart';
import 'package:pregnancy_appp/constants/color.dart';
import 'package:pregnancy_appp/screens/auth/signup_page.dart';
import 'package:pregnancy_appp/screens/auth/otp_verification_page.dart';
import 'package:pregnancy_appp/screens/auth/forgot_password_page.dart';
import 'package:pregnancy_appp/screens/home/mainscreen.dart';
import 'package:pregnancy_appp/services/auth_service.dart';
import 'package:pregnancy_appp/services/api_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _isEmail = true;
  bool _obscurePassword = true;
  bool _isLoading = false;

  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your phone number')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final password = _passwordController.text.trim();
      await AuthService.login(phone: phone, password: password.isNotEmpty ? password : null);
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainScreen()),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Network error. Please try again.')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleSendOtp() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your phone number')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await AuthService.sendOtp(phone: phone);
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => OtpVerificationPage(isLogin: true, phone: phone),
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Network error. Please try again.')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Image.asset(
                    'assets/images/white-pregnancy-logo.png',
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        alignment: Alignment.center,
                        child: const Icon(Icons.pregnant_woman, color: Colors.white, size: 50),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: RichText(
                  text: const TextSpan(
                    text: 'Enat ',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                    children: [
                      TextSpan(
                        text: 'Circle',
                        style: TextStyle(color: AppColors.primary),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              Container(
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _isEmail = true),
                        child: Container(
                          decoration: BoxDecoration(
                            color: _isEmail ? Colors.white : Colors.transparent,
                            borderRadius: BorderRadius.circular(22),
                            boxShadow: _isEmail
                                ? [const BoxShadow(color: Colors.black12, blurRadius: 4)]
                                : null,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Phone + Password',
                            style: TextStyle(
                              fontWeight: _isEmail ? FontWeight.bold : FontWeight.normal,
                              color: _isEmail ? AppColors.primary : Colors.black54,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _isEmail = false),
                        child: Container(
                          decoration: BoxDecoration(
                            color: !_isEmail ? Colors.white : Colors.transparent,
                            borderRadius: BorderRadius.circular(22),
                            boxShadow: !_isEmail
                                ? [const BoxShadow(color: Colors.black12, blurRadius: 4)]
                                : null,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'OTP Login',
                            style: TextStyle(
                              fontWeight: !_isEmail ? FontWeight.bold : FontWeight.normal,
                              color: !_isEmail ? AppColors.primary : Colors.black54,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              const Text('Enter your phone number', style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  hintText: '+251 911 234 567',
                  hintStyle: const TextStyle(color: Colors.black38),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
                    borderSide: const BorderSide(color: AppColors.primary),
                  ),
                  suffixIcon: const Icon(Icons.phone_outlined, color: Colors.black54),
                ),
              ),

              if (_isEmail) ...[
                const SizedBox(height: 20),
                const Text('Enter your password', style: TextStyle(fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                TextField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    hintText: '************',
                    hintStyle: const TextStyle(color: Colors.black38),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
                      borderSide: const BorderSide(color: AppColors.primary),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off : Icons.visibility,
                        color: Colors.black54,
                      ),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const ForgotPasswordPage()),
                      );
                    },
                    child: const Text(
                      'Forgot password?',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isLoading
                    ? null
                    : () {
                        if (_isEmail) {
                          _handleLogin();
                        } else {
                          _handleSendOtp();
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('Login', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 16),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Don't have an account? "),
                  GestureDetector(
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => const SignupPage()),
                      );
                    },
                    child: const Text(
                      "Sign Up",
                      style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),
              const Row(
                children: [
                  Expanded(child: Divider()),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text("OR", style: TextStyle(color: Colors.black54)),
                  ),
                  Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: 24),

              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {},
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const _GoogleIcon(),
                          const SizedBox(width: 8),
                          const Text(
                            'Sign in with Google',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
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

class _GoogleIcon extends StatelessWidget {
  const _GoogleIcon();
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 24,
      height: 24,
      child: CustomPaint(painter: _GooglePainter()),
    );
  }
}

class _GooglePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final bgPaint = Paint()..color = Colors.white;
    canvas.drawOval(rect, bgPaint);
    final textStyle = TextStyle(
      fontSize: size.width * 0.75,
      fontWeight: FontWeight.bold,
      foreground: Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFF4285F4), Color(0xFF34A853), Color(0xFFFBBC05), Color(0xFFEA4335)],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );
    final textSpan = TextSpan(text: 'G', style: textStyle);
    final painter = TextPainter(text: textSpan, textDirection: TextDirection.ltr);
    painter.layout();
    painter.paint(canvas, Offset((size.width - painter.width) / 2, (size.height - painter.height) / 2));
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

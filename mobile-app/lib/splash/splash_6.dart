import 'package:flutter/material.dart';
import 'package:pregnancy_appp/constants/color.dart';
import 'package:pregnancy_appp/provider/onboarding_service.dart';
import 'package:pregnancy_appp/screens/home/mainscreen.dart';
import 'package:pregnancy_appp/screens/auth/login_page.dart';

class Splash6 extends StatelessWidget {
  const Splash6({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
          child: Column(
            children: [
              const SizedBox(height: 20),
              // Enat Circle
              RichText(
                text: const TextSpan(
                  text: 'Enat ',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                  children: [
                    TextSpan(
                      text: 'Circle',
                      style: TextStyle(
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              // Image
              Image.asset(
                'assets/images/splash6-image.png',
                height: MediaQuery.of(context).size.height * 0.35,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: MediaQuery.of(context).size.height * 0.35,
                    alignment: Alignment.center,
                    child: Container(
                      width: 180,
                      height: 180,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.people,
                        size: 90,
                        color: AppColors.primary,
                      ),
                    ),
                  );
                },
              ),
              const Spacer(),
              // Title
              const Text(
                'Caring Hands, Healthy Journey',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              // Subtitle
              const Text(
                'You are not alone. Get the care, guidance, and support you need for a safe and happy pregnancy.',
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              // Bottom Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                TextButton(
  onPressed: () async {
    await OnboardingService.markOnboardingComplete();
    if (!context.mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const MainScreen()),
    );
  },
  child: const Text(
    'SKIP',
    style: TextStyle(
      color: Colors.black,
      fontWeight: FontWeight.w600,
      fontSize: 12,
    ),
  ),
),
                  Row(
                    children: List.generate(5, (index) {
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: index == 4 ? AppColors.primary : Colors.grey[300],
                        ),
                      );
                    }),
                  ),
               TextButton(
  onPressed: () async {
    await OnboardingService.markOnboardingComplete();
    if (!context.mounted) return;
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const LoginPage(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  },
  child: const Text(
    'NEXT',
    style: TextStyle(
      color: Colors.black,
      fontWeight: FontWeight.w600,
      fontSize: 12,
    ),
  ),
),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
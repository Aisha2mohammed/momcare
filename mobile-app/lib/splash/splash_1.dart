import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pregnancy_appp/constants/color.dart'; // Make sure path is correct
import 'package:pregnancy_appp/provider/onboarding_service.dart';
import 'package:pregnancy_appp/screens/home/mainscreen.dart';
import 'package:pregnancy_appp/splash/splash_2.dart';

class Splash1 extends StatefulWidget {
  const Splash1({super.key});

  @override
  State<Splash1> createState() => _Splash1State();
}

// SingleTickerProviderStateMixin is needed for animations
class _Splash1State extends State<Splash1> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<RelativeRect> _rectAnimationTop;
  late Animation<RelativeRect> _rectAnimationBottom;

  @override
  void initState() {
    super.initState();

    // 1. Initialize the Animation Controller
    // The duration determines how fast the screen "fills" with color
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400), 
    );

    // 2. Define Animations that move the shapes from "corners" to "fullscreen"
    
    // Scale the center logo slightly down as the background expands
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.7).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    // 3. Trigger the navigation flow
    _startNavigationSequence();
  }

 void _startNavigationSequence() async {
  // Stage 1: Wait 2.5 seconds showing the static splash
  await Future.delayed(const Duration(milliseconds: 2500));

  // Stage 2: Start the animation that fills the screen
  if (mounted) {
    _controller.forward();
  }

  // Stage 3: Wait for animation to finish
  await Future.delayed(const Duration(milliseconds: 1500));

  if (!mounted) return;

  final bool completed = await OnboardingService.hasCompletedOnboarding();

  Navigator.pushReplacement(
    context,
    PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) =>
          completed ? const MainScreen() : const Splash2(),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(opacity: animation, child: child);
      },
    ),
  );
}

  @override
  void dispose() {
    _controller.dispose(); // Always dispose animations
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    final double maxSize = size.height * 1.5; // Circle must be larger than height

    // Define the moving rectangles (corners to fullscreen)
    _rectAnimationTop = RelativeRectTween(
      begin: const RelativeRect.fromLTRB(-80, -120, -120, -80), // From image_0.png position
      end: RelativeRect.fromLTRB(size.width / 2 - maxSize / 2, -maxSize / 2, -size.width / 2, maxSize / 2),
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic));

    _rectAnimationBottom = RelativeRectTween(
      begin: const RelativeRect.fromLTRB(-60, -90, -90, -60), // From image_0.png position
      end: RelativeRect.fromLTRB(-size.width / 2, maxSize / 2, size.width / 2 - maxSize / 2, -maxSize / 2),
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic));

    return Scaffold(
      backgroundColor: AppColors.secondary,
      body: Stack(
        children: [
          // We use an empty container to establish the white background first
          Container(color: AppColors.secondary),

          // 1. Top-Left circle border animation (expanding)
          PositionedTransition(
            rect: _rectAnimationTop,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.primary, // Using Color(0xFF61183e)
                shape: BoxShape.circle,
              ),
            ),
          ),

          // 2. Bottom-Right circle border animation (expanding)
          PositionedTransition(
            rect: _rectAnimationBottom,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
            ),
          ),

          // 3. The Centered Logo (Animated Scale)
          Center(
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Image.asset(
                'assets/images/white-pregnancy-logo.png',
                width: 350,
                height: 400,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
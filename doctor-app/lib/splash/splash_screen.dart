import 'dart:async';
import 'package:flutter/material.dart';
import 'package:doctor_app/constants/color.dart';
import 'package:doctor_app/auth/register_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<Color?> _contentColor;
  late Animation<RelativeRect> _rectTopRight;
  late Animation<RelativeRect> _rectBottomLeft;

  double _contentOpacity = 0.0;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    // Logo shrinks slightly while the background expands
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.85).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    // Logo/text color: primary (on light bg) -> secondary (on dark bg)
    _contentColor = ColorTween(
      begin: AppColors.primary,
      end: AppColors.secondary,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 0.7, curve: Curves.easeInOut),
      ),
    );

    // Fade in the content after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _contentOpacity = 1.0);
    });

    _startNavigationSequence();
  }

  Future<void> _startNavigationSequence() async {
    // Stage 1: show static splash
    await Future.delayed(const Duration(milliseconds: 2200));

    // Stage 2: expand circles to fill the screen
    if (!mounted) return;
    _controller.forward();

    // Stage 3: wait for animation to finish
    await Future.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (context, animation, secondaryAnimation) =>
            const RegisterScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    final double maxSize = size.height * 1.6; // bigger than the screen
    const double circle = 240;

    // Circle 1: top-right corner -> fullscreen
    _rectTopRight = RelativeRectTween(
      begin: RelativeRect.fromLTRB(
        size.width - circle * 0.65,
        -circle * 0.35,
        -circle * 0.35,
        size.height - circle * 0.65,
      ),
      end: RelativeRect.fromLTRB(
        size.width / 2 - maxSize / 2,
        size.height / 2 - maxSize / 2,
        size.width / 2 - maxSize / 2,
        size.height / 2 - maxSize / 2,
      ),
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic),
    );

    // Circle 2: bottom-left corner -> fullscreen
    _rectBottomLeft = RelativeRectTween(
      begin: RelativeRect.fromLTRB(
        -circle * 0.35,
        size.height - circle * 0.65,
        size.width - circle * 0.65,
        -circle * 0.35,
      ),
      end: RelativeRect.fromLTRB(
        size.width / 2 - maxSize / 2,
        size.height / 2 - maxSize / 2,
        size.width / 2 - maxSize / 2,
        size.height / 2 - maxSize / 2,
      ),
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic),
    );

    return Scaffold(
      backgroundColor: AppColors.secondary,
      body: Stack(
        children: [
          Container(color: AppColors.secondary),

          // Top-right circle
          PositionedTransition(
            rect: _rectTopRight,
            child: Container(
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
            ),
          ),

          // Bottom-left circle
          PositionedTransition(
            rect: _rectBottomLeft,
            child: Container(
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
            ),
          ),

          // Center content (logo image + texts)
          Center(
            child: AnimatedOpacity(
              opacity: _contentOpacity,
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeIn,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: AnimatedBuilder(
                  animation: _contentColor,
                  builder: (context, _) {
                    final color = _contentColor.value ?? AppColors.primary;
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset(
                          'assets/images/purple-doctor-app.png',
                          width: 160,
                          height: 160,
                          fit: BoxFit.contain,
                          color: color, // tints a single-color logo
                          colorBlendMode: BlendMode.srcIn,
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Doctor App',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                            color: color,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Care for Pregnant Women',
                          style: TextStyle(
                            fontSize: 16,
                            color: color,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
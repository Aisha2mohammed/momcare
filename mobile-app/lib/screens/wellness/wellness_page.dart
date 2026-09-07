import 'package:flutter/material.dart';
import 'package:pregnancy_appp/constants/color.dart';
import 'package:pregnancy_appp/l10n/l10n.dart';
import 'package:pregnancy_appp/screens/wellness/music_page.dart';
import 'package:pregnancy_appp/screens/wellness/exercise_page.dart';
import 'package:pregnancy_appp/screens/wellness/sleep_tips_page.dart';
import 'package:pregnancy_appp/screens/wellness/nutrition_guide_page.dart';
import 'package:pregnancy_appp/screens/wellness/video_page.dart';
// import 'package:pregnancy_appp/screens/wellness/health_tips_page.dart';
// import 'package:pregnancy_appp/screens/wellness/journal_page.dart';
// import 'package:pregnancy_appp/screens/wellness/birth_plan_page.dart';

class WellnessPage extends StatefulWidget {
  const WellnessPage({super.key});

  @override
  State<WellnessPage> createState() => _WellnessPageState();
}

class _WellnessPageState extends State<WellnessPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Wellness Hub",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              "Take care of yourself and your baby",
              style: TextStyle(fontSize: 15, color: Colors.grey[600]),
            ),
            const SizedBox(height: 25),
            
            // Grid of Wellness Categories
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 15,
              mainAxisSpacing: 15,
              childAspectRatio: 0.9,
              children: [
                _buildWellnessCard(
                  context,
                  AppStrings.of(context, 'music'),
                  Icons.audiotrack_rounded,
                  () => Navigator.push(context, MaterialPageRoute(builder: (context) => const MusicPage())),
                ),
                _buildWellnessCard(
                  context,
                  AppStrings.of(context, 'exercise'),
                  Icons.fitness_center_rounded,
                  () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ExercisePage())),
                ),
                _buildWellnessCard(
                  context,
                  AppStrings.of(context, 'sleeping'),
                  Icons.bedtime_rounded,
                  () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SleepTipsPage())),
                ),
                _buildWellnessCard(
                  context,
                  AppStrings.of(context, 'nutrition'),
                  Icons.restaurant_rounded,
                  () => Navigator.push(context, MaterialPageRoute(builder: (context) => const NutritionGuidePage())),
                ),
                // _buildWellnessCard(
                //   context,
                //   "Health Tips",
                //   Icons.health_and_safety_rounded,
                //   () => Navigator.push(context, MaterialPageRoute(builder: (context) => const HealthTipsPage())),
                // ),
                _buildWellnessCard(
                  context,
                  AppStrings.of(context, 'video'),
                  Icons.play_circle_fill_rounded,
                  () => Navigator.push(context, MaterialPageRoute(builder: (context) => const VideoPage())),
                ),
                // _buildWellnessCard(
                //   context,
                //   "Journal",
                //   Icons.book_rounded,
                //   () => Navigator.push(context, MaterialPageRoute(builder: (context) => const JournalPage())),
                // ),
                // _buildWellnessCard(
                //   context,
                //   "Birth Plan",
                //   Icons.checklist_rounded,
                //   () => Navigator.push(context, MaterialPageRoute(builder: (context) => const BirthPlanPage())),
                // ),
              ],
            ),
            
            const SizedBox(height: 30),
            
            // Daily Motivation
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(25),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    "Daily Motivation",
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  SizedBox(height: 10),
                  Text(
                    "\"The most precious jewels you'll ever have around your neck are the arms of your children.\"",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWellnessCard(BuildContext context, String title, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.secondary, // White / Secondary background
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04), // Slightly more visible shadow for white card
              blurRadius: 10,
              offset: const Offset(0, 5),
            )
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1), // Subtle primary background for icon circle
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.primary, size: 30), // Primary icon
            ),
            const SizedBox(height: 15),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }
}

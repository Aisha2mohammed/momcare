import 'package:flutter/material.dart';
import 'package:pregnancy_appp/constants/color.dart';
import 'package:pregnancy_appp/l10n/l10n.dart';

class ExercisePage extends StatelessWidget {
  const ExercisePage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        appBar: AppBar(
          title: Text(AppStrings.of(context, 'exercise')),
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: AppColors.textPrimary,
          bottom: const TabBar(
            labelColor: AppColors.primary,
            unselectedLabelColor: Colors.grey,
            indicatorColor: AppColors.primary,
            tabs: [
              Tab(text: "1st Trimester"),
              Tab(text: "2nd Trimester"),
              Tab(text: "3rd Trimester"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildExerciseList(1),
            _buildExerciseList(2),
            _buildExerciseList(3),
          ],
        ),
      ),
    );
  }

  Widget _buildExerciseList(int trimester) {
    List<Widget> items;
    if (trimester == 1) {
      items = [
        _buildExerciseItem(Icons.directions_walk_rounded, "Light Walking", "Keep a steady pace for 20 mins daily. Start slow and stay hydrated."),
        _buildExerciseItem(Icons.self_improvement_rounded, "Basic Prenatal Yoga", "Focus on gentle stretches and controlled breathing."),
      ];
    } else if (trimester == 2) {
      items = [
        _buildExerciseItem(Icons.pool_rounded, "Swimming", "Safe weightless exercise for joint relief and cardiovascular health."),
        _buildExerciseItem(Icons.directions_walk_rounded, "Moderate Walking", "Increase to 30 mins if comfortable. Good for stamina."),
        _buildExerciseItem(Icons.accessibility_new_rounded, "Pelvic Floor", "Kegel exercises to strengthen your muscles."),
      ];
    } else {
      items = [
        _buildExerciseItem(Icons.directions_walk_rounded, "Slow Walking", "Keep moving but listen to your body. Rest if tired."),
        _buildExerciseItem(Icons.accessibility_new_rounded, "Pelvic Floor", "Continue Kegel exercises to prepare for delivery."),
        _buildExerciseItem(Icons.self_improvement_rounded, "Gentle Stretching", "Relieve back pain and prepare your body for labor."),
      ];
    }

    return ListView(
      padding: const EdgeInsets.all(20),
      children: items,
    );
  }

  Widget _buildExerciseItem(IconData icon, String title, String description) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 5)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), shape: BoxShape.circle),
                child: Icon(icon, color: AppColors.primary, size: 28),
              ),
              const SizedBox(width: 15),
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          ),
          const SizedBox(height: 15),
          Text(description, style: TextStyle(color: Colors.grey[700], height: 1.5)),
        ],
      ),
    );
  }
}

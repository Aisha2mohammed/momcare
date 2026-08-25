import 'package:flutter/material.dart';
import 'package:pregnancy_appp/constants/color.dart';
import 'package:pregnancy_appp/l10n/l10n.dart';

class NutritionGuidePage extends StatelessWidget {
  const NutritionGuidePage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        appBar: AppBar(
          title: Text(AppStrings.of(context, 'nutrition')),
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
            _buildNutritionList(1),
            _buildNutritionList(2),
            _buildNutritionList(3),
          ],
        ),
      ),
    );
  }

  Widget _buildNutritionList(int trimester) {
    List<Widget> items;
    if (trimester == 1) {
      items = [
        const Text("1st Trimester Nutrition", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 20),
        _buildFoodCard("Folic Acid Rich Foods", "Leafy greens like Gomen help prevent neural tube defects.", Icons.eco_rounded),
        _buildFoodCard("Ginger & Citrus", "Helps reduce morning sickness and nausea.", Icons.local_florist_rounded),
        _buildFoodCard("Injera (Teff)", "High in iron for early blood volume expansion.", Icons.restaurant_rounded),
      ];
    } else if (trimester == 2) {
      items = [
        const Text("2nd Trimester Nutrition", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 20),
        _buildFoodCard("Dairy & Eggs", "Excellent for protein and calcium for baby's bone growth.", Icons.egg_rounded),
        _buildFoodCard("Shiro", "A great legume-based source of protein, fiber, and iron.", Icons.local_dining_rounded),
        _buildFoodCard("Bulla (Enset)", "Providing calcium and sustained energy.", Icons.coffee_rounded),
      ];
    } else {
      items = [
        const Text("3rd Trimester Nutrition", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 20),
        _buildFoodCard("Omega-3 Rich Foods", "Flaxseeds and safe fish for baby's brain development.", Icons.set_meal_rounded),
        _buildFoodCard("Iron & Vitamin C", "Lean meats with citrus to boost iron absorption for delivery.", Icons.fastfood_rounded),
        _buildFoodCard("Hydration", "Drink plenty of water to maintain amniotic fluid levels.", Icons.local_drink_rounded),
      ];
    }

    return ListView(
      padding: const EdgeInsets.all(20),
      children: items,
    );
  }

  Widget _buildFoodCard(String name, String benefit, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: AppColors.primary, size: 24),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Text(benefit, style: TextStyle(color: Colors.grey[600], fontSize: 13, height: 1.3)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

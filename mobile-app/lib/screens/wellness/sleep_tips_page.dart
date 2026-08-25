import 'package:flutter/material.dart';
import 'package:pregnancy_appp/constants/color.dart';
import 'package:pregnancy_appp/l10n/l10n.dart';

class SleepTipsPage extends StatelessWidget {
  const SleepTipsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        appBar: AppBar(
          title: Text(AppStrings.of(context, 'sleeping')),
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
            _buildSleepTipsList(1),
            _buildSleepTipsList(2),
            _buildSleepTipsList(3),
          ],
        ),
      ),
    );
  }

  Widget _buildSleepTipsList(int trimester) {
    List<Widget> items;
    if (trimester == 1) {
      items = [
        _buildTipCard(Icons.airline_seat_flat_rounded, "Sleep on your Left", "Sleeping on your left side improves blood flow to the placenta and your baby."),
        _buildTipCard(Icons.timelapse_rounded, "Consistent Routine", "Go to bed and wake up at the same time every day to regulate your body's clock."),
      ];
    } else if (trimester == 2) {
      items = [
        _buildTipCard(Icons.padding_rounded, "Pillow Support", "Use supportive pillows between your knees and under your belly."),
        _buildTipCard(Icons.no_drinks_rounded, "Limit Fluid Intake", "Reduce fluids 2 hours before bedtime to minimize bathroom trips during the night."),
      ];
    } else {
      items = [
        _buildTipCard(Icons.airline_seat_flat_rounded, "Keep Left", "Continue sleeping on your left to avoid putting pressure on your back and liver."),
        _buildTipCard(Icons.favorite_rounded, "Relax Before Bed", "Take a warm shower or read to relax before trying to sleep."),
        _buildTipCard(Icons.padding_rounded, "Full Body Pillow", "A pregnancy pillow can be a lifesaver in the third trimester."),
      ];
    }

    return ListView(
      padding: const EdgeInsets.all(20),
      children: items,
    );
  }

  Widget _buildTipCard(IconData icon, String title, String body) {
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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary, size: 30),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                const SizedBox(height: 8),
                Text(body, style: TextStyle(color: Colors.grey[700], height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

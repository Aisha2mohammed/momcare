import 'package:flutter/material.dart';
import 'package:pregnancy_appp/constants/color.dart';
import 'package:pregnancy_appp/l10n/l10n.dart';

class MusicPage extends StatelessWidget {
  const MusicPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        appBar: AppBar(
          title: Text(AppStrings.of(context, 'music')),
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: AppColors.textPrimary,
          bottom: const TabBar(
            labelColor: AppColors.primary,
            unselectedLabelColor: Colors.grey,
            indicatorColor: AppColors.primary,
            tabs: [
              Tab(text: "Relaxation"),
              Tab(text: "Classical"),
              Tab(text: "Lullaby"),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _MusicListTab(category: "Relaxation"),
            _MusicListTab(category: "Classical"),
            _MusicListTab(category: "Lullaby"),
          ],
        ),
      ),
    );
  }
}

class _MusicListTab extends StatelessWidget {
  final String category;
  const _MusicListTab({required this.category});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 40),
          CircleAvatar(
            radius: 100,
            backgroundColor: AppColors.primary.withOpacity(0.1),
            child: const Icon(Icons.music_note_rounded, size: 100, color: AppColors.primary),
          ),
          const SizedBox(height: 40),
          Text("$category Music", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const Text("Prenatal Relaxation Series", style: TextStyle(color: Colors.grey, fontSize: 16)),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(onPressed: () {}, icon: const Icon(Icons.shuffle_rounded, color: Colors.grey)),
                IconButton(onPressed: () {}, icon: const Icon(Icons.skip_previous_rounded, size: 45)),
                const CircleAvatar(
                  radius: 40,
                  backgroundColor: AppColors.primary,
                  child: Icon(Icons.play_arrow_rounded, size: 50, color: Colors.white),
                ),
                IconButton(onPressed: () {}, icon: const Icon(Icons.skip_next_rounded, size: 45)),
                IconButton(onPressed: () {}, icon: const Icon(Icons.repeat_rounded, color: Colors.grey)),
              ],
            ),
          ),
          const SizedBox(height: 60),
        ],
      ),
    );
  }
}

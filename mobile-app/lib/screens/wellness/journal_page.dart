import 'package:flutter/material.dart';
import 'package:pregnancy_appp/constants/color.dart';

class JournalPage extends StatefulWidget {
  const JournalPage({super.key});

  @override
  State<JournalPage> createState() => _JournalPageState();
}

class _JournalPageState extends State<JournalPage> {
  final List<Map<String, dynamic>> _entries = [
    {
      "title": "First Kick!",
      "date": "Oct 12, 2026",
      "content": "Felt the first little flutters today while resting on the couch. It was magical!",
      "hasImage": false,
    },
    {
      "title": "Cravings",
      "date": "Oct 05, 2026",
      "content": "I cannot get enough of spicy food and ice cream right now.",
      "hasImage": false,
    },
    {
      "title": "Ultrasound Day",
      "date": "Sep 28, 2026",
      "content": "Saw the baby's heartbeat. Everything looks healthy and perfect.",
      "hasImage": true,
    },
  ];

  void _showAddEntryDialog(BuildContext context) {
    final titleController = TextEditingController();
    final contentController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(28),
              topRight: Radius.circular(28),
            ),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(Icons.close_rounded),
                  ),
                  const Text(
                    "New Memory",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  TextButton(
                    onPressed: () {
                      if (titleController.text.isNotEmpty) {
                        setState(() {
                          _entries.insert(0, {
                            "title": titleController.text,
                            "date": "${_monthName(DateTime.now().month)} ${DateTime.now().day}, ${DateTime.now().year}",
                            "content": contentController.text,
                            "hasImage": false,
                          });
                        });
                        Navigator.pop(ctx);
                      }
                    },
                    child: const Text(
                      "Save",
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: titleController,
                decoration: InputDecoration(
                  hintText: "Title (e.g. First Kick!)",
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: contentController,
                minLines: 4,
                maxLines: 8,
                decoration: InputDecoration(
                  hintText: "Write about this memory...",
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  String _monthName(int month) {
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return months[month];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text("Journal & Memories"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
      ),
      body: _entries.isEmpty
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.book_outlined, size: 64, color: AppColors.primary),
                  SizedBox(height: 16),
                  Text("No memories yet.\nTap + to add your first one!", textAlign: TextAlign.center),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: _entries.length,
              itemBuilder: (context, index) {
                final e = _entries[index];
                return _buildJournalEntry(e['title'], e['date'], e['content'], isImage: e['hasImage'] ?? false);
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEntryDialog(context),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
    );
  }

  Widget _buildJournalEntry(String title, String date, String content, {bool isImage = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 5))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18))),
              Text(date, style: TextStyle(color: Colors.grey[500], fontSize: 13)),
            ],
          ),
          const SizedBox(height: 15),
          if (isImage) ...[
            Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.secondary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.image_rounded, size: 50, color: AppColors.primary),
            ),
            const SizedBox(height: 15),
          ],
          Text(content, style: TextStyle(color: Colors.grey[700], height: 1.5)),
        ],
      ),
    );
  }
}

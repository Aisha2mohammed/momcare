import 'package:flutter/material.dart';
import 'package:doctor_app/constants/color.dart';
import 'package:doctor_app/widget/status_modal.dart';

class BroadcastNotificationDialog {
  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _BroadcastSheetContent(),
    );
  }
}

class _BroadcastSheetContent extends StatefulWidget {
  const _BroadcastSheetContent();

  @override
  State<_BroadcastSheetContent> createState() => _BroadcastSheetContentState();
}

class _BroadcastSheetContentState extends State<_BroadcastSheetContent> {
  final TextEditingController _titleController = TextEditingController(
    text: 'Urgent Maternal Health Advisory',
  );
  final TextEditingController _messageController = TextEditingController(
    text: 'Please remember to log your afternoon blood pressure readings and stay hydrated. Report any sudden headache or vision changes immediately.',
  );

  int _selectedAudienceIndex = 0; // 0: All, 1: High-Risk, 2: Pending
  int _selectedUrgencyIndex = 0; // 0: High, 1: Normal

  final List<String> _audiences = [
    'All Active Patients',
    'High-Risk Alerts Only',
    'Pending Consultations',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void _sendNotification() {
    final title = _titleController.text.trim();
    final body = _messageController.text.trim();

    if (title.isEmpty || body.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill out both title and message')),
      );
      return;
    }

    final targetAudience = _audiences[_selectedAudienceIndex];
    Navigator.pop(context);

    AppModals.showSuccess(
      context,
      title: 'Broadcast Dispatched!',
      message: 'Push notification "$title" has been successfully sent to $targetAudience.',
      primaryButtonText: 'Done',
    );
  }

  void _applyTemplate(String title, String body) {
    setState(() {
      _titleController.text = title;
      _messageController.text = body;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        left: 20,
        right: 20,
        top: 16,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Pull Handle
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Header Title
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.campaign_rounded, color: AppColors.primary, size: 22),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Send Push Notification',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        'Broadcast urgent alerts or care advisories',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),

            const SizedBox(height: 18),

            // Audience Selector
            const Text(
              'Target Audience',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(_audiences.length, (index) {
                final isSelected = _selectedAudienceIndex == index;
                return ChoiceChip(
                  label: Text(_audiences[index]),
                  selected: isSelected,
                  selectedColor: AppColors.primary,
                  backgroundColor: AppColors.background,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : AppColors.textPrimary,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 12,
                  ),
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _selectedAudienceIndex = index);
                    }
                  },
                );
              }),
            ),

            const SizedBox(height: 16),

            // Quick Preset Templates
            const Text(
              'Quick Templates',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildTemplateChip(
                    'Pre-eclampsia Reminder',
                    'Blood Pressure & Symptoms Check',
                    'Please record your morning BP. Contact the clinic immediately if you have headaches or epigastric pain.',
                  ),
                  const SizedBox(width: 8),
                  _buildTemplateChip(
                    'Glucose Log Advisory',
                    'Fasting Glucose Monitoring',
                    'Friendly reminder to log your post-meal blood glucose readings in the app before 6 PM today.',
                  ),
                  const SizedBox(width: 8),
                  _buildTemplateChip(
                    'Hydration Alert',
                    'Summer Weather Hydration Notice',
                    'High temperatures expected today. Ensure 2.5-3L water intake and rest in cool environments.',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Title Field
            const Text(
              'Notification Title',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                filled: true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),

            const SizedBox(height: 14),

            // Body Field
            const Text(
              'Message Body',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _messageController,
              maxLines: 3,
              decoration: InputDecoration(
                filled: true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                contentPadding: const EdgeInsets.all(14),
              ),
            ),

            const SizedBox(height: 14),

            // Urgency Toggle
            Row(
              children: [
                const Text(
                  'Urgency Level:',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 12),
                ChoiceChip(
                  label: const Text('Clinical Alert'),
                  selected: _selectedUrgencyIndex == 0,
                  selectedColor: AppColors.riskHigh,
                  labelStyle: TextStyle(
                    color: _selectedUrgencyIndex == 0 ? Colors.white : AppColors.textPrimary,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                  onSelected: (val) => setState(() => _selectedUrgencyIndex = 0),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Routine Tip'),
                  selected: _selectedUrgencyIndex == 1,
                  selectedColor: AppColors.primary,
                  labelStyle: TextStyle(
                    color: _selectedUrgencyIndex == 1 ? Colors.white : AppColors.textPrimary,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                  onSelected: (val) => setState(() => _selectedUrgencyIndex = 1),
                ),
              ],
            ),

            const SizedBox(height: 22),

            // Send Action Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 2,
                ),
                onPressed: _sendNotification,
                icon: const Icon(Icons.send_rounded, size: 18),
                label: const Text(
                  'Broadcast Push Notification',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTemplateChip(String chipLabel, String templateTitle, String templateBody) {
    return ActionChip(
      backgroundColor: AppColors.background,
      side: BorderSide(color: Colors.grey.shade300),
      label: Text(chipLabel, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
      onPressed: () => _applyTemplate(templateTitle, templateBody),
    );
  }
}

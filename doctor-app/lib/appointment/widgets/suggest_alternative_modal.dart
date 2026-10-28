import 'package:flutter/material.dart';
import 'package:doctor_app/constants/color.dart';
import 'package:doctor_app/model/mock_data.dart';

class SuggestAlternativeModal extends StatefulWidget {
  final AppointmentModel appointment;
  final void Function(String reason, List<String> alternativeSlots, String message) onConfirm;

  const SuggestAlternativeModal({
    super.key,
    required this.appointment,
    required this.onConfirm,
  });

  static Future<void> show(
    BuildContext context, {
    required AppointmentModel appointment,
    required void Function(String reason, List<String> alternativeSlots, String message) onConfirm,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SuggestAlternativeModal(
        appointment: appointment,
        onConfirm: onConfirm,
      ),
    );
  }

  @override
  State<SuggestAlternativeModal> createState() => _SuggestAlternativeModalState();
}

class _SuggestAlternativeModalState extends State<SuggestAlternativeModal> {
  final TextEditingController _messageController = TextEditingController();

  final List<String> _reasons = [
    'Emergency C-Section / Delivery scheduled',
    'Clinic capacity reached / Overbooked',
    'Doctor unavailable / Attending triage',
    'Requires direct hospital ER admission',
    'Schedule conflict with operating hours',
  ];

  String _selectedReason = 'Emergency C-Section / Delivery scheduled';

  final List<String> _availableSlots = [
    'Tomorrow, 09:30 AM',
    'Tomorrow, 11:15 AM',
    'Tomorrow, 02:30 PM',
    'Thu, Oct 30 • 10:00 AM',
    'Thu, Oct 30 • 03:00 PM',
    'Fri, Oct 31 • 09:00 AM',
    'Fri, Oct 31 • 04:30 PM',
  ];

  final List<String> _selectedSlots = [];

  @override
  void initState() {
    super.initState();
    _messageController.text =
        'Unavailable at ${widget.appointment.timeSlot} due to scheduled clinical commitments. Please choose one of these alternative consultation slots.';
    // Pre-select first 2 slots for doctor convenience
    if (_availableSlots.length >= 2) {
      _selectedSlots.addAll([_availableSlots[0], _availableSlots[1]]);
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _toggleSlot(String slot) {
    setState(() {
      if (_selectedSlots.contains(slot)) {
        _selectedSlots.remove(slot);
      } else {
        if (_selectedSlots.length < 2) {
          _selectedSlots.add(slot);
        } else {
          // Replace second slot if already 2 selected
          _selectedSlots.removeAt(1);
          _selectedSlots.add(slot);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        top: 12,
        left: 20,
        right: 20,
        bottom: bottomInset + 20,
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag Handle
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
          const SizedBox(height: 14),

          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.riskHigh.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.schedule_send_rounded, color: AppColors.riskHigh, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Decline & Suggest Alternatives',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'For ${widget.appointment.patientName} (${widget.appointment.gestationalAge})',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 12),

          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Step 1: Rejection Reason
                  const Text(
                    '1. Select Rejection Reason',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade200),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: _reasons.map((reason) {
                        final isSelected = _selectedReason == reason;
                        return InkWell(
                          onTap: () => setState(() => _selectedReason = reason),
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            child: Row(
                              children: [
                                Icon(
                                  isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                                  color: isSelected ? AppColors.primary : Colors.grey.shade400,
                                  size: 20,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    reason,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                      color: isSelected ? AppColors.primary : AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Step 2: Pick 2 Alternative Available Slots
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '2. Pick 2 Available Slots to Offer',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: _selectedSlots.length == 2
                              ? AppColors.riskStable.withValues(alpha: 0.15)
                              : Colors.amber.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${_selectedSlots.length} / 2 selected',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: _selectedSlots.length == 2 ? AppColors.riskStable : Colors.amber.shade800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _availableSlots.map((slot) {
                      final isSelected = _selectedSlots.contains(slot);
                      return FilterChip(
                        selected: isSelected,
                        label: Text(slot),
                        labelStyle: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          color: isSelected ? Colors.white : AppColors.textPrimary,
                        ),
                        selectedColor: AppColors.primary,
                        checkmarkColor: Colors.white,
                        backgroundColor: Colors.grey.shade100,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: BorderSide(
                            color: isSelected ? AppColors.primary : Colors.grey.shade300,
                          ),
                        ),
                        onSelected: (_) => _toggleSlot(slot),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),

                  // Step 3: Message to Mother
                  const Text(
                    '3. Message to Patient (Optional)',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _messageController,
                    maxLines: 3,
                    style: const TextStyle(fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Enter clinical rationale or advice for the mother...',
                      hintStyle: const TextStyle(fontSize: 13, color: Colors.grey),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      contentPadding: const EdgeInsets.all(12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.primary),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),
          // Actions
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    side: BorderSide(color: Colors.grey.shade300),
                  ),
                  child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: _selectedSlots.isEmpty
                      ? null
                      : () {
                          Navigator.pop(context);
                          widget.onConfirm(
                            _selectedReason,
                            _selectedSlots,
                            _messageController.text.trim(),
                          );
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.shade300,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.send_rounded, size: 18),
                  label: const Text(
                    'Send Alternatives',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

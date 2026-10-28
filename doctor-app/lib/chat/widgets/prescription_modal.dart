import 'package:flutter/material.dart';
import 'package:doctor_app/constants/color.dart';
import 'package:doctor_app/model/mock_data.dart';

class PrescriptionModal {
  static Future<PrescriptionData?> show(BuildContext context, PatientModel patient) {
    return showModalBottomSheet<PrescriptionData>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _PrescriptionSheetContent(patient: patient),
    );
  }
}

class _PrescriptionSheetContent extends StatefulWidget {
  final PatientModel patient;

  const _PrescriptionSheetContent({required this.patient});

  @override
  State<_PrescriptionSheetContent> createState() => _PrescriptionSheetContentState();
}

class _PrescriptionSheetContentState extends State<_PrescriptionSheetContent> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _drugController = TextEditingController(text: 'Labetalol Hydrochloride');
  final TextEditingController _dosageController = TextEditingController(text: '200 mg Tablets');
  final TextEditingController _frequencyController = TextEditingController(text: 'Twice daily (after breakfast & dinner)');
  final TextEditingController _durationController = TextEditingController(text: '14 days');
  final TextEditingController _instructionsController = TextEditingController(
    text: 'Take with water. Re-check BP 1 hour post-dose and record in app log.',
  );

  @override
  void dispose() {
    _drugController.dispose();
    _dosageController.dispose();
    _frequencyController.dispose();
    _durationController.dispose();
    _instructionsController.dispose();
    super.dispose();
  }

  void _applyPreset(String drug, String dosage, String freq, String duration, String instructions) {
    setState(() {
      _drugController.text = drug;
      _dosageController.text = dosage;
      _frequencyController.text = freq;
      _durationController.text = duration;
      _instructionsController.text = instructions;
    });
  }

  void _submitPrescription() {
    if (!_formKey.currentState!.validate()) return;

    final randomRxNumber = 'RX-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';

    final prescription = PrescriptionData(
      rxNumber: randomRxNumber,
      drugName: _drugController.text.trim(),
      dosage: _dosageController.text.trim(),
      frequency: _frequencyController.text.trim(),
      duration: _durationController.text.trim(),
      instructions: _instructionsController.text.trim(),
      doctorName: 'Dr. Sarah Jenkins, MD',
      doctorLicense: 'LIC-OBGYN-884219',
      timestamp: DateTime.now(),
    );

    Navigator.pop(context, prescription);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        left: 20,
        right: 20,
        top: 14,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Form(
        key: _formKey,
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
              const SizedBox(height: 14),

              // Modal Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      '℞',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'serif',
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Issue Digital Prescription',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          'For ${widget.patient.name} (${widget.patient.gestationalAge})',
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
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

              const SizedBox(height: 16),

              // Clinical Presets
              const Text(
                'Maternal Health Presets',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 6),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: [
                    _buildPresetChip(
                      'Hypertension / BP',
                      'Labetalol HCl',
                      '200 mg Tablets',
                      'Twice daily after meals',
                      '14 days',
                      'Take with full glass of water. Recheck BP 1 hour post-dose.',
                    ),
                    const SizedBox(width: 8),
                    _buildPresetChip(
                      'Prenatal Iron Anemia',
                      'Ferrous Sulfate',
                      '325 mg (65 mg elemental iron)',
                      'Once daily in the morning',
                      '30 days',
                      'Take with citrus juice for optimal absorption. Avoid calcium within 2 hours.',
                    ),
                    const SizedBox(width: 8),
                    _buildPresetChip(
                      'Nausea / Hyperemesis',
                      'Pyridoxine (Vit B6) + Doxylamine',
                      '10 mg / 10 mg Delayed-Release',
                      'Two tablets at bedtime',
                      '10 days',
                      'Swallow whole on an empty stomach with water.',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Drug Name
              _buildTextField(
                label: 'Medication Name',
                controller: _drugController,
                hint: 'e.g. Labetalol, Methyldopa, Insulin Glargine',
                icon: Icons.medication_rounded,
                validator: (val) => val == null || val.isEmpty ? 'Please enter drug name' : null,
              ),

              const SizedBox(height: 12),

              // Dosage and Frequency in a 2-column row
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      label: 'Dosage / Strength',
                      controller: _dosageController,
                      hint: 'e.g. 200 mg, 500 mg',
                      icon: Icons.speed_rounded,
                      validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildTextField(
                      label: 'Duration',
                      controller: _durationController,
                      hint: 'e.g. 14 days, 1 month',
                      icon: Icons.date_range_rounded,
                      validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Frequency
              _buildTextField(
                label: 'Frequency / Timing',
                controller: _frequencyController,
                hint: 'e.g. Twice daily after meals, Once daily at bedtime',
                icon: Icons.repeat_rounded,
                validator: (val) => val == null || val.isEmpty ? 'Required' : null,
              ),

              const SizedBox(height: 12),

              // Instructions
              _buildTextField(
                label: 'Clinical Instructions & Warnings',
                controller: _instructionsController,
                hint: 'e.g. Monitor blood pressure, take with food, avoid caffeine',
                icon: Icons.note_alt_outlined,
                maxLines: 2,
              ),

              const SizedBox(height: 20),

              // Submit Button
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
                  onPressed: _submitPrescription,
                  icon: const Icon(Icons.send_rounded, size: 18),
                  label: const Text(
                    'Sign & Issue Prescription Card',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPresetChip(
    String label,
    String drug,
    String dosage,
    String freq,
    String duration,
    String inst,
  ) {
    return ActionChip(
      backgroundColor: AppColors.background,
      side: BorderSide(color: Colors.grey.shade300),
      label: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
      onPressed: () => _applyPreset(drug, dosage, freq, duration, inst),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 4),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
            prefixIcon: Icon(icon, size: 18, color: AppColors.primary),
            filled: true,
            fillColor: AppColors.background,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          ),
        ),
      ],
    );
  }
}

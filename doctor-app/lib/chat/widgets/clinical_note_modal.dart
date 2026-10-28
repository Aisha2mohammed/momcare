import 'package:flutter/material.dart';
import 'package:doctor_app/constants/color.dart';
import 'package:doctor_app/model/mock_data.dart';

class ClinicalNoteModal {
  static Future<ClinicalNoteData?> show(BuildContext context, PatientModel patient) {
    return showModalBottomSheet<ClinicalNoteData>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ClinicalNoteSheetContent(patient: patient),
    );
  }
}

class _ClinicalNoteSheetContent extends StatefulWidget {
  final PatientModel patient;

  const _ClinicalNoteSheetContent({required this.patient});

  @override
  State<_ClinicalNoteSheetContent> createState() => _ClinicalNoteSheetContentState();
}

class _ClinicalNoteSheetContentState extends State<_ClinicalNoteSheetContent> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _symptomsController = TextEditingController();
  final TextEditingController _diagnosisController = TextEditingController();
  final TextEditingController _nextStepsController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  final List<String> _quickSymptoms = [
    'BP Spike',
    'Severe Headache',
    'Blurred Vision',
    'Glucose Elevation',
    'Pelvic Pressure',
    'Ankle Edema',
    'Dizziness',
  ];

  final List<String> _quickDiagnoses = [
    'Gestational Hypertension',
    'Pre-eclampsia Risk',
    'Gestational Diabetes',
    'Threatened Preterm Contractions',
    'Iron Deficiency Anemia',
    'Stable Prenatal Wellness',
  ];

  final List<String> _quickNextSteps = [
    'Modified Bed Rest',
    'Twice Daily BP Tracking',
    'Repeat Lab Protein',
    'Ultrasound Follow-up',
    'Adjust Medication',
    'Continue Daily Prenatals',
  ];

  final Set<String> _selectedSymptoms = {};

  @override
  void initState() {
    super.initState();
    _symptomsController.text = widget.patient.recentFlaggedSymptom;
    _diagnosisController.text = widget.patient.condition;
    _nextStepsController.text = 'Modified bed rest, twice-daily BP logging, repeat urine protein in 48 hours.';
  }

  @override
  void dispose() {
    _symptomsController.dispose();
    _diagnosisController.dispose();
    _nextStepsController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _toggleSymptomTag(String tag) {
    setState(() {
      if (_selectedSymptoms.contains(tag)) {
        _selectedSymptoms.remove(tag);
      } else {
        _selectedSymptoms.add(tag);
      }
      final base = widget.patient.recentFlaggedSymptom;
      if (_selectedSymptoms.isEmpty) {
        _symptomsController.text = base;
      } else {
        _symptomsController.text = '$base, ${_selectedSymptoms.join(", ")}';
      }
    });
  }

  void _applyDiagnosis(String diag) {
    setState(() {
      _diagnosisController.text = diag;
    });
  }

  void _applyNextStep(String step) {
    setState(() {
      if (_nextStepsController.text.isEmpty) {
        _nextStepsController.text = step;
      } else {
        _nextStepsController.text += ', $step';
      }
    });
  }

  void _submitNote() {
    if (!_formKey.currentState!.validate()) return;

    final note = ClinicalNoteData(
      symptomsObserved: _symptomsController.text.trim(),
      diagnosis: _diagnosisController.text.trim(),
      nextSteps: _nextStepsController.text.trim(),
      notes: _notesController.text.trim(),
      doctorName: 'Dr. Sarah Jenkins, MD',
      timestamp: DateTime.now(),
    );

    Navigator.pop(context, note);
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
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.edit_note_rounded, color: Color(0xFF2563EB), size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Write Clinical Note',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          'Patient: ${widget.patient.name} (${widget.patient.gestationalAge})',
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

              // 1. Symptoms Section with Tag Toggles
              _buildSectionHeader('1. Symptoms Observed', 'Select observed clinical symptoms:'),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: _quickSymptoms.map((symptom) {
                  final isSelected = _selectedSymptoms.contains(symptom);
                  return FilterChip(
                    label: Text(symptom),
                    selected: isSelected,
                    selectedColor: AppColors.riskModerateBg,
                    backgroundColor: AppColors.background,
                    labelStyle: TextStyle(
                      fontSize: 11,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? AppColors.riskModerate : AppColors.textPrimary,
                    ),
                    onSelected: (_) => _toggleSymptomTag(symptom),
                  );
                }).toList(),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _symptomsController,
                validator: (val) => val == null || val.isEmpty ? 'Please specify symptoms' : null,
                decoration: InputDecoration(
                  hintText: 'Describe patient symptoms in detail...',
                  filled: true,
                  fillColor: AppColors.background,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),

              const SizedBox(height: 16),

              // 2. Diagnosis Section with Quick Tags
              _buildSectionHeader('2. Clinical Diagnosis', 'Select primary maternal diagnosis:'),
              const SizedBox(height: 6),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: _quickDiagnoses.map((diag) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ActionChip(
                        backgroundColor: AppColors.background,
                        side: BorderSide(color: Colors.grey.shade300),
                        label: Text(diag, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
                        onPressed: () => _applyDiagnosis(diag),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _diagnosisController,
                validator: (val) => val == null || val.isEmpty ? 'Please enter clinical diagnosis' : null,
                decoration: InputDecoration(
                  hintText: 'Enter clinical diagnosis...',
                  filled: true,
                  fillColor: AppColors.background,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),

              const SizedBox(height: 16),

              // 3. Next Steps & Management Plan
              _buildSectionHeader('3. Next Steps & Action Plan', 'Key recommendations:'),
              const SizedBox(height: 6),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: _quickNextSteps.map((step) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ActionChip(
                        backgroundColor: AppColors.background,
                        side: BorderSide(color: Colors.grey.shade300),
                        label: Text(step, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
                        onPressed: () => _applyNextStep(step),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _nextStepsController,
                maxLines: 2,
                validator: (val) => val == null || val.isEmpty ? 'Please specify next steps' : null,
                decoration: InputDecoration(
                  hintText: 'Detail next steps, home monitoring, or tests...',
                  filled: true,
                  fillColor: AppColors.background,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),

              const SizedBox(height: 14),

              // 4. Physician Private Remarks
              const Text(
                'Additional Advice / Patient Notes (Optional)',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 4),
              TextField(
                controller: _notesController,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: 'Patient counseled on emergency signs...',
                  filled: true,
                  fillColor: AppColors.background,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),

              const SizedBox(height: 20),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 2,
                  ),
                  onPressed: _submitNote,
                  icon: const Icon(Icons.check_circle_rounded, size: 18),
                  label: const Text(
                    'Save & Post Clinical Note to Chat',
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

  Widget _buildSectionHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
        Text(
          subtitle,
          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

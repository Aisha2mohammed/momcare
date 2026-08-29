import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:pregnancy_appp/constants/color.dart';
import 'package:pregnancy_appp/services/api_service.dart';
import 'package:pregnancy_appp/services/mother_service.dart';

class JournalPage extends StatefulWidget {
  const JournalPage({super.key});

  @override
  State<JournalPage> createState() => _JournalPageState();
}

class _JournalPageState extends State<JournalPage> {
  List<Map<String, dynamic>> _entries = [];
  bool _isLoading = true;
  String? _error;

  static const List<String> _moods = [
    'happy', 'normal', 'sad', 'anxious', 'tired', 'energetic',
  ];

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final logs = await MotherService.getHealthLogs();
      if (!mounted) return;
      setState(() {
        _entries = logs.map((e) => e as Map<String, dynamic>).toList();
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Network error. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _submitLog({
    required double? weightKg,
    required String? mood,
    required List<dynamic> symptoms,
    required int? severity,
  }) async {
    try {
      await MotherService.createHealthLog(
        weightKg: weightKg,
        mood: mood,
        symptoms: symptoms,
        symptomSeverity: severity,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Health log saved')),
      );
      await _loadLogs();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Network error. Please try again.')),
      );
    }
  }

  void _showAddLogDialog(BuildContext context) {
    final weightController = TextEditingController();
    final symptomsController = TextEditingController();
    String? selectedMood;
    double severity = 0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
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
            child: SingleChildScrollView(
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
                        "New Health Log",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      TextButton(
                        onPressed: () async {
                          final weight = double.tryParse(weightController.text.trim());
                          final symptoms = symptomsController.text
                              .trim()
                              .split(',')
                              .map((s) => s.trim())
                              .where((s) => s.isNotEmpty)
                              .toList();
                          Navigator.pop(ctx);
                          await _submitLog(
                            weightKg: weight,
                            mood: selectedMood,
                            symptoms: symptoms,
                            severity: severity > 0 ? severity.round() : null,
                          );
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
                    controller: weightController,
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: "Weight (kg)",
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: selectedMood,
                    decoration: InputDecoration(
                      labelText: "Mood",
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    items: _moods.map((m) {
                      return DropdownMenuItem(value: m, child: Text(m));
                    }).toList(),
                    onChanged: (value) => setModalState(() => selectedMood = value),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: symptomsController,
                    decoration: InputDecoration(
                      labelText: "Symptoms (comma separated, e.g. headache, nausea)",
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
                  Text(
                    "Symptom severity: ${severity.round()}",
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Slider(
                    value: severity,
                    min: 0,
                    max: 10,
                    divisions: 10,
                    activeColor: AppColors.primary,
                    onChanged: (value) => setModalState(() => severity = value),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(String iso) {
    final d = DateTime.tryParse(iso);
    if (d == null) return iso;
    const months = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[d.month]} ${d.day}, ${d.year}';
  }

  List<String> _parseSymptoms(dynamic raw) {
    if (raw == null) return [];
    if (raw is List) {
      return raw.map((s) => s.toString()).toList();
    }
    if (raw is String) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          return decoded.map((s) => s.toString()).toList();
        }
      } catch (_) {}
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text("Health Log"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_error!, style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 12),
                      OutlinedButton(onPressed: _loadLogs, child: const Text('Retry')),
                    ],
                  ),
                )
              : _entries.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.book_outlined, size: 64, color: AppColors.primary),
                          SizedBox(height: 16),
                          Text("No health logs yet.\nTap + to log your first entry!", textAlign: TextAlign.center),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadLogs,
                      child: ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(20),
                        itemCount: _entries.length,
                        itemBuilder: (context, index) {
                          final e = _entries[index];
                          final weight = e['weight_kg'];
                          final mood = e['mood'] as String?;
                          final severity = e['symptom_severity'];
                          final symptoms = _parseSymptoms(e['symptoms_json']);
                          return _buildHealthLogEntry(
                            date: e['log_date'] as String? ?? '',
                            weight: weight != null ? '$weight kg' : null,
                            mood: mood,
                            severity: severity,
                            symptoms: symptoms,
                          );
                        },
                      ),
                    ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddLogDialog(context),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
    );
  }

  Widget _buildHealthLogEntry({
    required String date,
    String? weight,
    String? mood,
    dynamic severity,
    required List<String> symptoms,
  }) {
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
              Expanded(
                child: Text(
                  _formatDate(date),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              if (weight != null)
                Text(weight, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
            ],
          ),
          if (mood != null || severity != null) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (mood != null)
                  _buildTag(Icons.mood_rounded, "Mood: $mood"),
                if (severity != null)
                  _buildTag(Icons.speed_rounded, "Severity: $severity/10"),
              ],
            ),
          ],
          if (symptoms.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text("Symptoms:", style: TextStyle(fontSize: 13, color: Colors.grey)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: symptoms.map((s) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(s, style: const TextStyle(fontSize: 12, color: AppColors.primary)),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTag(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey[700]),
          const SizedBox(width: 6),
          Text(text, style: TextStyle(fontSize: 12, color: Colors.grey[700])),
        ],
      ),
    );
  }
}
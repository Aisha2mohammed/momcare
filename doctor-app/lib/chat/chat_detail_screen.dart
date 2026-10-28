import 'package:flutter/material.dart';
import 'package:doctor_app/constants/color.dart';
import 'package:doctor_app/model/mock_data.dart';
import 'package:doctor_app/chat/widgets/clinical_header_widget.dart';
import 'package:doctor_app/chat/widgets/message_bubble_widget.dart';
import 'package:doctor_app/chat/widgets/prescription_modal.dart';
import 'package:doctor_app/chat/widgets/clinical_note_modal.dart';
import 'package:doctor_app/widget/patient_chart_dialog.dart';
import 'package:doctor_app/widget/status_modal.dart';

class ChatDetailScreen extends StatefulWidget {
  final PatientModel patient;

  const ChatDetailScreen({super.key, required this.patient});

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final TextEditingController _msgController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late List<ChatMessage> _messages;
  bool _isVoiceRecording = false;

  @override
  void initState() {
    super.initState();
    // Load patient conversation messages
    _messages = List<ChatMessage>.from(
      MockData.chats[widget.patient.id]?.messages ?? [
        ChatMessage(
          text: 'Hello Dr. Sarah, I am logging in for our consultation.',
          isMe: false,
          timestamp: DateTime.now().subtract(const Duration(minutes: 30)),
        ),
      ],
    );

    // Automatically mark patient messages as read
    widget.patient.isRead = true;
    widget.patient.unreadCount = 0;
  }

  @override
  void dispose() {
    _msgController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 120,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _sendTextMessage() {
    final text = _msgController.text.trim();
    if (text.isEmpty) return;

    final now = DateTime.now();
    setState(() {
      _messages.add(ChatMessage(
        text: text,
        isMe: true,
        timestamp: now,
        type: MessageType.text,
      ));
      _syncConversation(lastMessageText: text);
    });

    _msgController.clear();
    Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
  }

  void _openPrescriptionModal() async {
    final rxData = await PrescriptionModal.show(context, widget.patient);
    if (rxData != null && mounted) {
      final now = DateTime.now();
      setState(() {
        _messages.add(ChatMessage(
          text: 'Digital Prescription Issued: ${rxData.drugName} (${rxData.dosage})',
          isMe: true,
          timestamp: now,
          type: MessageType.prescription,
          prescription: rxData,
        ));
        _syncConversation(lastMessageText: 'Rx: ${rxData.drugName} (${rxData.dosage})');
      });

      Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);

      AppModals.showSuccess(
        context,
        title: 'Prescription Issued',
        message: '${rxData.drugName} has been signed and posted to the patient chat.',
        primaryButtonText: 'Great, Done',
      );
    }
  }

  void _openClinicalNoteModal() async {
    final noteData = await ClinicalNoteModal.show(context, widget.patient);
    if (noteData != null && mounted) {
      final now = DateTime.now();
      setState(() {
        _messages.add(ChatMessage(
          text: 'Clinical Assessment: ${noteData.diagnosis}',
          isMe: true,
          timestamp: now,
          type: MessageType.clinicalNote,
          clinicalNote: noteData,
        ));
        _syncConversation(lastMessageText: 'Clinical Note: ${noteData.diagnosis}');
      });

      Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Clinical note posted to conversation'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _openAttachmentPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Share Clinical Attachment',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildAttachOption(
                    icon: Icons.picture_as_pdf_rounded,
                    color: const Color(0xFFDC2626),
                    label: 'Lab Report PDF',
                    onTap: () {
                      Navigator.pop(context);
                      _addSampleAttachment('CBC_and_Urine_Lab_Report.pdf', '1.4 MB', 'pdf');
                    },
                  ),
                  _buildAttachOption(
                    icon: Icons.monitor_heart_rounded,
                    color: const Color(0xFF2563EB),
                    label: 'Ultrasound Scan',
                    onTap: () {
                      Navigator.pop(context);
                      _addSampleAttachment('Anatomy_Scan_Growth_28w.pdf', '3.8 MB', 'pdf');
                    },
                  ),
                  _buildAttachOption(
                    icon: Icons.photo_library_rounded,
                    color: AppColors.primary,
                    label: 'Clinical Photo',
                    onTap: () {
                      Navigator.pop(context);
                      _addSampleAttachment('Home_BP_Monitor_Screen.png', '850 KB', 'image');
                    },
                  ),
                ],
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  void _addSampleAttachment(String fileName, String size, String type) {
    final now = DateTime.now();
    setState(() {
      _messages.add(ChatMessage(
        text: 'Document attachment uploaded for review.',
        isMe: true,
        timestamp: now,
        type: MessageType.attachment,
        attachment: AttachmentData(
          fileName: fileName,
          fileSize: size,
          fileType: type,
        ),
      ));
      _syncConversation(lastMessageText: 'Shared file: $fileName');
    });
    Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
  }

  void _toggleVoiceNote() {
    setState(() {
      _isVoiceRecording = !_isVoiceRecording;
    });

    if (_isVoiceRecording) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Recording voice consultation note... tap mic again to finish'),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      // Finished voice recording -> send audio message
      final now = DateTime.now();
      setState(() {
        _messages.add(ChatMessage(
          text: 'Voice Note (0:42) - Doctor instructions on hydration and resting position.',
          isMe: true,
          timestamp: now,
          type: MessageType.text,
        ));
        _syncConversation(lastMessageText: 'Voice note (0:42)');
      });
      Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
    }
  }

  void _syncConversation({required String lastMessageText}) {
    MockData.chats[widget.patient.id] = ChatDetail(
      patientId: widget.patient.id,
      messages: _messages,
    );
    widget.patient.lastMessage = lastMessageText;
    widget.patient.lastMessageTime = DateTime.now();
    widget.patient.isRead = true;
    widget.patient.unreadCount = 0;
  }

  void _openNotesHistory() {
    final notes = _messages.where((m) => m.type == MessageType.clinicalNote).toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Clinical Notes History',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${notes.length} Recorded',
                    style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Expanded(
                child: notes.isEmpty
                    ? const Center(child: Text('No clinical notes recorded in this session yet.'))
                    : ListView.builder(
                        itemCount: notes.length,
                        itemBuilder: (context, i) {
                          return MessageBubbleWidget(message: notes[i]);
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAttachOption({
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        titleSpacing: 0,
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: Row(
          children: [
            CircleAvatar(
              backgroundImage: NetworkImage(widget.patient.imageUrl),
              radius: 18,
              onBackgroundImageError: (_, __) {},
              child: Text(
                widget.patient.name.isNotEmpty ? widget.patient.name[0] : 'P',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.patient.name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${widget.patient.gestationalAge} • ${widget.patient.riskLabel}',
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Call Patient',
            icon: const Icon(Icons.phone_outlined, color: AppColors.primary, size: 22),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Calling ${widget.patient.name} (${widget.patient.phone})...')),
              );
            },
          ),
          IconButton(
            tooltip: 'View Full Patient Chart',
            icon: const Icon(Icons.insert_chart_outlined_rounded, color: AppColors.primary, size: 22),
            onPressed: () => PatientChartDialog.show(context, widget.patient),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          // 1. Sticky Patient Clinical Header
          ClinicalHeaderWidget(
            patient: widget.patient,
            onNotesHistoryPressed: _openNotesHistory,
          ),

          // 2. Conversation Feed (Distinguishing Doctor vs Patient messages)
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return MessageBubbleWidget(
                  message: message,
                  onAttachmentTapped: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Opening ${message.attachment?.fileName}...')),
                    );
                  },
                );
              },
            ),
          ),

          // 3. Action Toolbar (Above Chat Input)
          _buildClinicalActionToolbar(),

          // 4. Chat Input Bar
          _buildChatInputBar(),
        ],
      ),
    );
  }

  // 3. Action Toolbar (Above Chat Input)
  Widget _buildClinicalActionToolbar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey.shade200),
          bottom: BorderSide(color: Colors.grey.shade100),
        ),
      ),
      child: Row(
        children: [
          // Clinical Note Button
          Expanded(
            child: InkWell(
              onTap: _openClinicalNoteModal,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF93C5FD).withValues(alpha: 0.6)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.edit_note_rounded, size: 16, color: Color(0xFF2563EB)),
                    SizedBox(width: 5),
                    Text(
                      'Write Note',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1D4ED8),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(width: 8),

          // Issue Prescription Button
          Expanded(
            child: InkWell(
              onTap: _openPrescriptionModal,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '℞',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                        fontFamily: 'serif',
                      ),
                    ),
                    SizedBox(width: 5),
                    Text(
                      'Issue Rx',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(width: 8),

          // Attach File / Image Icon
          IconButton(
            tooltip: 'Attach Clinical Document / Photo',
            style: IconButton.styleFrom(
              backgroundColor: AppColors.background,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.all(8),
            ),
            icon: const Icon(Icons.attach_file_rounded, color: AppColors.primary, size: 20),
            onPressed: _openAttachmentPicker,
          ),
        ],
      ),
    );
  }

  // 4. Chat Input Bar with Voice Note & Send Button
  Widget _buildChatInputBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: Colors.white,
      child: SafeArea(
        child: Row(
          children: [
            // Voice note record button
            IconButton(
              tooltip: _isVoiceRecording ? 'Stop Recording' : 'Record Voice Consultation',
              icon: Icon(
                _isVoiceRecording ? Icons.stop_circle_rounded : Icons.mic_none_rounded,
                color: _isVoiceRecording ? AppColors.riskHigh : AppColors.primary,
                size: 24,
              ),
              onPressed: _toggleVoiceNote,
            ),

            // Text input field
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: _isVoiceRecording ? AppColors.riskHigh : Colors.grey.shade300,
                  ),
                ),
                child: TextField(
                  controller: _msgController,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    hintText: _isVoiceRecording
                        ? 'Recording voice consultation note...'
                        : 'Type message or clinical advice...',
                    hintStyle: TextStyle(
                      fontSize: 13,
                      color: _isVoiceRecording ? AppColors.riskHigh : Colors.grey.shade500,
                      fontWeight: _isVoiceRecording ? FontWeight.bold : FontWeight.normal,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                  onSubmitted: (_) => _sendTextMessage(),
                ),
              ),
            ),

            const SizedBox(width: 8),

            // Send Button
            CircleAvatar(
              backgroundColor: AppColors.primary,
              radius: 20,
              child: IconButton(
                icon: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                onPressed: _sendTextMessage,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

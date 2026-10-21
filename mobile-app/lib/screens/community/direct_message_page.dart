import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pregnancy_appp/constants/color.dart';
import 'package:pregnancy_appp/services/api_service.dart';
import 'package:pregnancy_appp/services/community_service.dart';
import 'package:pregnancy_appp/services/push_service.dart';

class DirectMessagePage extends StatefulWidget {
  final String otherUserId;
  final String otherUserName;
  final String? otherUserPhoto;

  const DirectMessagePage({
    super.key,
    required this.otherUserId,
    required this.otherUserName,
    this.otherUserPhoto,
  });

  @override
  State<DirectMessagePage> createState() => _DirectMessagePageState();
}

class _DirectMessagePageState extends State<DirectMessagePage> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  final List<Map<String, dynamic>> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;
  String? _editingMessageId;
  String? _currentUserId;
  String? _userRole;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _initChat();
  }

  Future<void> _initChat() async {
    _currentUserId = await ApiService.getUserId();
    _userRole = await ApiService.getUserRole();
    await _loadMessages(showSpinner: true);

    // Socket listeners for real-time messages, edits, and deletions
    try {
      PushService.socket?.on('direct:message', _handleIncomingSocketMessage);
      PushService.socket?.on('direct:message_updated', _handleMessageUpdated);
      PushService.socket?.on('direct:message_deleted', _handleMessageDeleted);
    } catch (_) {}

    // Fallback sync polling every 4 seconds while screen is open
    _pollTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (mounted) {
        _loadMessages(showSpinner: false);
      }
    });
  }

  void _handleIncomingSocketMessage(dynamic payload) {
    if (!mounted || payload == null || payload is! Map) return;
    final data = Map<String, dynamic>.from(payload);
    final senderId = data['sender_id']?.toString();
    final receiverId = data['receiver_id']?.toString();

    // Check if relevant to this conversation
    if ((senderId == widget.otherUserId && receiverId == _currentUserId) ||
        (senderId == _currentUserId && receiverId == widget.otherUserId)) {
      final id = data['id']?.toString();
      final exists = _messages.any((m) => m['id']?.toString() == id);
      if (!exists) {
        setState(() {
          _messages.add(data);
        });
        _scrollToBottom();
      }
    }
  }

  void _handleMessageUpdated(dynamic payload) {
    if (!mounted || payload == null || payload is! Map) return;
    final data = Map<String, dynamic>.from(payload);
    final id = data['id']?.toString();
    if (id == null) return;

    final index = _messages.indexWhere((m) => m['id']?.toString() == id);
    if (index != -1) {
      setState(() {
        _messages[index] = {
          ..._messages[index],
          ...data,
          'is_edited': true,
        };
      });
    }
  }

  void _handleMessageDeleted(dynamic payload) {
    if (!mounted || payload == null || payload is! Map) return;
    final data = Map<String, dynamic>.from(payload);
    final id = data['id']?.toString();
    if (id == null) return;

    setState(() {
      _messages.removeWhere((m) => m['id']?.toString() == id);
    });
  }

  Future<void> _loadMessages({bool showSpinner = false}) async {
    if (showSpinner) {
      setState(() => _isLoading = true);
    }
    try {
      final raw = await CommunityService.getDirectMessages(widget.otherUserId);
      if (!mounted) return;
      final list = raw.map((m) => Map<String, dynamic>.from(m as Map)).toList();
      setState(() {
        _messages
          ..clear()
          ..addAll(list);
      });
      if (showSpinner) {
        _scrollToBottom();
      }
    } catch (e) {
      debugPrint('[DirectMessagePage] Error loading messages: $e');
    } finally {
      if (mounted && showSpinner) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 60,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _handleSendOrUpdate() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isSending) return;

    // Editing mode
    if (_editingMessageId != null) {
      final messageId = _editingMessageId!;
      setState(() => _isSending = true);
      try {
        final updated = await CommunityService.updateDirectMessage(messageId, text);
        if (!mounted) return;
        setState(() {
          final idx = _messages.indexWhere((m) => m['id']?.toString() == messageId);
          if (idx != -1) {
            _messages[idx] = {
              ..._messages[idx],
              ...updated,
              'message_text': text,
              'is_edited': true,
            };
          }
          _editingMessageId = null;
          _controller.clear();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Message updated successfully'), duration: Duration(seconds: 2)),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update message: $e')),
        );
      } finally {
        if (mounted) setState(() => _isSending = false);
      }
      return;
    }

    // New message
    _controller.clear();
    setState(() => _isSending = true);

    // Optimistic message
    final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
    final optimisticMsg = {
      'id': tempId,
      'sender_id': _currentUserId,
      'receiver_id': widget.otherUserId,
      'message_text': text,
      'is_read': false,
      'is_edited': false,
      'created_at': DateTime.now().toIso8601String(),
    };

    setState(() {
      _messages.add(optimisticMsg);
    });
    _scrollToBottom();

    try {
      final sent = await CommunityService.sendDirectMessage(
        otherUserId: widget.otherUserId,
        messageText: text,
      );
      if (!mounted) return;
      setState(() {
        final index = _messages.indexWhere((m) => m['id'] == tempId);
        if (index != -1 && sent.isNotEmpty) {
          _messages[index] = sent;
        }
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send message: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text;
    if (text != null && text.isNotEmpty) {
      final cur = _controller.text;
      final sel = _controller.selection;
      if (sel.isValid && sel.start >= 0 && sel.end >= sel.start) {
        final newText = cur.replaceRange(sel.start, sel.end, text);
        _controller.text = newText;
        _controller.selection = TextSelection.collapsed(offset: sel.start + text.length);
      } else {
        _controller.text = '$cur$text';
        _controller.selection = TextSelection.collapsed(offset: _controller.text.length);
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pasted from clipboard'), duration: Duration(milliseconds: 1200)),
      );
    }
  }

  void _copyMessage(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Message copied to clipboard'), duration: Duration(seconds: 2)),
    );
  }

  void _startEdit(Map<String, dynamic> msg) {
    final text = (msg['message_text'] ?? '').toString();
    setState(() {
      _editingMessageId = msg['id']?.toString();
      _controller.text = text;
      _controller.selection = TextSelection.collapsed(offset: text.length);
    });
    _focusNode.requestFocus();
  }

  void _cancelEdit() {
    setState(() {
      _editingMessageId = null;
      _controller.clear();
    });
  }

  Future<void> _confirmDelete(Map<String, dynamic> msg) async {
    final id = msg['id']?.toString();
    if (id == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Delete Message"),
        content: const Text("Are you sure you want to delete this message? It will be removed for both of you."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[600],
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(dialogCtx, true),
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await CommunityService.deleteDirectMessage(id);
        if (!mounted) return;
        setState(() {
          _messages.removeWhere((m) => m['id']?.toString() == id);
          if (_editingMessageId == id) {
            _cancelEdit();
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Message deleted'), duration: Duration(seconds: 2)),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not delete message: $e')),
        );
      }
    }
  }

  void _showMessageActionSheet(BuildContext context, Map<String, dynamic> msg) {
    final text = (msg['message_text'] ?? '').toString();
    final senderId = msg['sender_id']?.toString();
    final receiverId = msg['receiver_id']?.toString();
    final isMe = senderId != null && senderId == _currentUserId;
    final canEdit = isMe || _userRole == 'admin';
    final canDelete = isMe ||
        (_currentUserId != null && (_currentUserId == senderId || _currentUserId == receiverId)) ||
        _userRole == 'admin';

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.copy_rounded, color: AppColors.primary),
                title: const Text("Copy Text", style: TextStyle(fontWeight: FontWeight.w600)),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _copyMessage(text);
                },
              ),
              if (canEdit)
                ListTile(
                  leading: const Icon(Icons.edit_outlined, color: Colors.blueAccent),
                  title: const Text("Edit Message", style: TextStyle(fontWeight: FontWeight.w600)),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _startEdit(msg);
                  },
                ),
              if (canDelete)
                ListTile(
                  leading: Icon(Icons.delete_outline_rounded, color: Colors.red[600]),
                  title: Text(
                    "Delete Message",
                    style: TextStyle(fontWeight: FontWeight.w600, color: Colors.red[600]),
                  ),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _confirmDelete(msg);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(dynamic iso) {
    if (iso == null) return '';
    final dt = DateTime.tryParse(iso.toString())?.toLocal();
    if (dt == null) return '';
    final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$hour:$minute $period';
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    try {
      PushService.socket?.off('direct:message', _handleIncomingSocketMessage);
      PushService.socket?.off('direct:message_updated', _handleMessageUpdated);
      PushService.socket?.off('direct:message_deleted', _handleMessageDeleted);
    } catch (_) {}
    _controller.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasPhoto = widget.otherUserPhoto != null && widget.otherUserPhoto!.trim().isNotEmpty;
    final initial = widget.otherUserName.isNotEmpty ? widget.otherUserName[0].toUpperCase() : 'M';

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          color: Colors.black87,
          onPressed: () => Navigator.pop(context),
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 19,
              backgroundColor: AppColors.primary.withValues(alpha: 0.12),
              backgroundImage: hasPhoto ? NetworkImage(ApiService.resolveUrl(widget.otherUserPhoto)) : null,
              child: hasPhoto
                  ? null
                  : Text(
                      initial,
                      style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.otherUserName,
                    style: const TextStyle(color: Colors.black87, fontSize: 15.5, fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Text(
                    "Mother in Mom Care Community",
                    style: TextStyle(color: Colors.grey, fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Notice banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: const Color(0xFFFDF2F8),
            child: Row(
              children: [
                const Icon(Icons.lock_outline_rounded, size: 14, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "Private messages are secure between you and ${widget.otherUserName}.",
                    style: const TextStyle(fontSize: 11.5, color: AppColors.primary, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),

          // Messages list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(18),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.08),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.waving_hand_rounded, size: 40, color: AppColors.primary),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                "Say hello to ${widget.otherUserName}!",
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                "Share thoughts, support each other, or ask questions privately.\nTap & hold any message to copy, edit, or delete.",
                                style: TextStyle(color: Colors.grey[600], fontSize: 12.5, height: 1.4),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final msg = _messages[index];
                          final senderId = msg['sender_id']?.toString();
                          final isMe = senderId != null && senderId == _currentUserId;
                          final text = (msg['message_text'] ?? '').toString();
                          final time = _formatTime(msg['created_at']);
                          final isEdited = msg['is_edited'] == true;

                          return GestureDetector(
                            onLongPress: () => _showMessageActionSheet(context, msg),
                            child: _buildBubble(text, time, isMe, isEdited),
                          );
                        },
                      ),
          ),

          // Editing indicator bar
          if (_editingMessageId != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: const Color(0xFFEFF6FF),
              child: Row(
                children: [
                  const Icon(Icons.edit_note_rounded, size: 18, color: Colors.blueAccent),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      "Editing message...",
                      style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Colors.blueAccent),
                    ),
                  ),
                  GestureDetector(
                    onTap: _cancelEdit,
                    child: const Icon(Icons.close_rounded, size: 18, color: Colors.grey),
                  ),
                ],
              ),
            ),

          // Input area
          Container(
            color: Colors.white,
            padding: EdgeInsets.only(
              left: 10,
              right: 12,
              top: 10,
              bottom: MediaQuery.of(context).padding.bottom + 10,
            ),
            child: Row(
              children: [
                // Quick Paste Button
                IconButton(
                  visualDensity: VisualDensity.compact,
                  tooltip: "Paste from clipboard",
                  icon: const Icon(Icons.content_paste_rounded, size: 20, color: AppColors.primary),
                  onPressed: _pasteFromClipboard,
                ),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      textCapitalization: TextCapitalization.sentences,
                      minLines: 1,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: _editingMessageId != null ? "Update your message..." : "Type a private message...",
                        hintStyle: const TextStyle(fontSize: 14, color: Colors.grey),
                        border: InputBorder.none,
                      ),
                      onSubmitted: (_) => _handleSendOrUpdate(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _handleSendOrUpdate,
                  child: Container(
                    padding: const EdgeInsets.all(11),
                    decoration: BoxDecoration(
                      color: _editingMessageId != null ? Colors.blueAccent : AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: _isSending
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : Icon(
                            _editingMessageId != null ? Icons.check_rounded : Icons.send_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBubble(String text, String time, bool isMe, bool isEdited) {
    final hasPhoto = widget.otherUserPhoto != null && widget.otherUserPhoto!.trim().isNotEmpty;
    final initial = widget.otherUserName.isNotEmpty ? widget.otherUserName[0].toUpperCase() : 'M';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 14,
              backgroundColor: AppColors.primary.withValues(alpha: 0.12),
              backgroundImage: hasPhoto ? NetworkImage(ApiService.resolveUrl(widget.otherUserPhoto)) : null,
              child: hasPhoto
                  ? null
                  : Text(
                      initial,
                      style: const TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
            ),
            const SizedBox(width: 8),
          ],
          Column(
            crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Container(
                constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                decoration: BoxDecoration(
                  color: isMe ? AppColors.primary : Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(18),
                    topRight: const Radius.circular(18),
                    bottomLeft: Radius.circular(isMe ? 18 : 4),
                    bottomRight: Radius.circular(isMe ? 4 : 18),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    )
                  ],
                ),
                child: Text(
                  text,
                  style: TextStyle(
                    color: isMe ? Colors.white : Colors.black87,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 3),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (time.isNotEmpty)
                    Text(
                      time,
                      style: TextStyle(color: Colors.grey[500], fontSize: 10),
                    ),
                  if (isEdited) ...[
                    const SizedBox(width: 4),
                    Text(
                      "(edited)",
                      style: TextStyle(color: Colors.grey[400], fontSize: 9.5, fontStyle: FontStyle.italic),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

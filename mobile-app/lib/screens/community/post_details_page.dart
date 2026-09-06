import 'package:flutter/material.dart';
import 'package:pregnancy_appp/constants/color.dart';
import 'package:pregnancy_appp/services/api_service.dart';
import 'package:pregnancy_appp/services/community_service.dart';

class PostDetailsPage extends StatefulWidget {
  final Map<String, dynamic> post;
  final String groupName;
  final bool initiallyLiked;

  const PostDetailsPage({
    super.key,
    required this.post,
    required this.groupName,
    this.initiallyLiked = false,
  });

  @override
  State<PostDetailsPage> createState() => _PostDetailsPageState();
}

class _PostDetailsPageState extends State<PostDetailsPage> {
  late bool _isLiked;
  late int _likeCount;

  List<dynamic> _comments = [];
  bool _loadingComments = true;
  String? _commentsError;

  final TextEditingController _commentController = TextEditingController();
  bool _submittingComment = false;

  // ── Helpers ────────────────────────────────────────────────────────────
  int _toInt(Object? v) =>
      v is num ? v.toInt() : int.tryParse(v?.toString() ?? '') ?? 0;

  String _timeAgo(String iso) {
    final dt = DateTime.tryParse(iso);
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  @override
  void initState() {
    super.initState();
    _isLiked = widget.initiallyLiked;
    _likeCount = _toInt(widget.post['like_count']);
    _loadComments();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  // ── Load comments ──────────────────────────────────────────────────────
  Future<void> _loadComments() async {
    final postId = widget.post['id'] as String?;
    if (postId == null) {
      setState(() {
        _loadingComments = false;
        _commentsError = 'Invalid post.';
      });
      return;
    }
    setState(() {
      _loadingComments = true;
      _commentsError = null;
    });
    try {
      final data = await CommunityService.getPostComments(postId);
      if (!mounted) return;
      setState(() => _comments = data);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _commentsError = e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _commentsError = 'Could not load comments.');
    } finally {
      if (mounted) setState(() => _loadingComments = false);
    }
  }

  // ── Submit comment ─────────────────────────────────────────────────────
  Future<void> _submitComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;
    final postId = widget.post['id'] as String?;
    if (postId == null) return;

    setState(() => _submittingComment = true);
    try {
      final newComment = await CommunityService.createComment(postId, text);
      if (!mounted) return;
      _commentController.clear();
      setState(() => _comments.insert(0, newComment));
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not post comment. Please try again.')),
      );
    } finally {
      if (mounted) setState(() => _submittingComment = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.post['author_name'] as String? ?? 'Anonymous';
    final content = widget.post['content'] as String? ?? '';
    final createdAt = widget.post['created_at'] as String? ?? '';
    final time = _timeAgo(createdAt);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Post Details', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Author info ──────────────────────────────────────
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 25,
                        backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                        child: Text(
                          name.isEmpty ? 'A' : name[0],
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 16)),
                            Row(
                              children: [
                                Text(time,
                                    style: TextStyle(
                                        color: Colors.grey[500], fontSize: 13)),
                                if (widget.groupName.isNotEmpty) ...[
                                  Text(' · ',
                                      style: TextStyle(color: Colors.grey[400])),
                                  Flexible(
                                    child: Text(
                                      widget.groupName,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                          color: AppColors.primary,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ── Post content ─────────────────────────────────────
                  Text(content,
                      style: const TextStyle(
                          fontSize: 16, height: 1.6, color: Colors.black87)),
                  const SizedBox(height: 20),

                  // ── Interaction stats ────────────────────────────────
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _isLiked = !_isLiked;
                            _isLiked ? _likeCount++ : _likeCount--;
                          });
                        },
                        child: Row(
                          children: [
                            Icon(
                              _isLiked
                                  ? Icons.thumb_up_rounded
                                  : Icons.thumb_up_off_alt_rounded,
                              color: _isLiked ? AppColors.primary : Colors.grey,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '$_likeCount Likes',
                              style: TextStyle(
                                color: _isLiked ? AppColors.primary : Colors.grey,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 20),
                      Row(
                        children: [
                          Icon(Icons.chat_bubble_outline_rounded,
                              color: Colors.grey, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            '${_comments.length} Comments',
                            style: const TextStyle(
                                color: Colors.grey,
                                fontWeight: FontWeight.w600,
                                fontSize: 14),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const Divider(height: 40),
                  const Text('Comments',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 16),

                  // ── Comments list ────────────────────────────────────
                  if (_loadingComments)
                    const Center(
                        child: Padding(
                      padding: EdgeInsets.all(24),
                      child: CircularProgressIndicator(color: AppColors.primary),
                    ))
                  else if (_commentsError != null)
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(_commentsError!,
                              style: TextStyle(color: Colors.grey[500])),
                          const SizedBox(height: 8),
                          TextButton.icon(
                            onPressed: _loadComments,
                            icon: const Icon(Icons.refresh_rounded, size: 16),
                            label: const Text('Retry'),
                          ),
                        ],
                      ),
                    )
                  else if (_comments.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text('No comments yet. Be the first!',
                            style: TextStyle(color: Colors.grey[500])),
                      ),
                    )
                  else
                    ..._comments.map((c) => _buildCommentItem(c)),
                ],
              ),
            ),
          ),

          // ── Comment input ──────────────────────────────────────────────
          Container(
            padding: EdgeInsets.only(
              left: 20,
              right: 10,
              bottom: MediaQuery.of(context).padding.bottom + 10,
              top: 10,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -5)),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    decoration: InputDecoration(
                      hintText: 'Add a comment...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                    ),
                    onSubmitted: (_) => _submitComment(),
                  ),
                ),
                _submittingComment
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: AppColors.primary),
                        ),
                      )
                    : IconButton(
                        onPressed: _submitComment,
                        icon: const Icon(Icons.send_rounded,
                            color: AppColors.primary),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentItem(Map<String, dynamic> c) {
    final name = c['author_name'] as String? ?? 'Anonymous';
    final text = c['content'] as String? ?? '';
    final time = _timeAgo(c['created_at'] as String? ?? '');

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
            child: Text(
              name.isEmpty ? 'A' : name[0],
              style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 14,
                  fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(name,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14)),
                    Text(time,
                        style: TextStyle(color: Colors.grey[500], fontSize: 11)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(text,
                    style: TextStyle(
                        color: Colors.grey[800], fontSize: 14, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

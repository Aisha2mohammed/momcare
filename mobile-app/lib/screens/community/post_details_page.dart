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
  final TextEditingController _commentController = TextEditingController();
  late final List<Map<String, dynamic>> _comments;
  late bool isLiked;
  late int likeCount;
  bool _submitting = false;
  bool _loadingComments = true;
  bool _commentsLoadFailed = false;

  String get _postId => widget.post['id'] as String? ?? '';

  // Backend COUNT()/bigint values arrive as strings; safe numeric parse.
  int _toInt(Object? v) =>
      v is num ? v.toInt() : int.tryParse(v?.toString() ?? '') ?? 0;

  @override
  void initState() {
    super.initState();
    isLiked = widget.initiallyLiked || widget.post['liked_by_me'] == true;
    // Server like_count already includes this user's like if liked_by_me.
    likeCount = _toInt(widget.post['like_count']);
    _comments = [];
    _loadComments();
  }

  Future<void> _loadComments() async {
    setState(() {
      _loadingComments = true;
      _commentsLoadFailed = false;
    });
    try {
      final comments = await CommunityService.getPostComments(_postId);
      if (!mounted) return;
      setState(() {
        _comments
          ..clear()
          ..addAll([
            for (final c in comments)
              {
                'author': (c['author_name'] as String?) ?? 'Member',
                'content': (c['content'] as String?) ?? '',
                'created_at': (c['created_at'] as String?) ?? '',
              },
          ]);
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      _handleCommentLoadError(e.message);
    } catch (_) {
      if (!mounted) return;
      _handleCommentLoadError('Network error. Please try again.');
    } finally {
      if (mounted) setState(() => _loadingComments = false);
    }
  }

  void _handleCommentLoadError(String message) {
    setState(() => _commentsLoadFailed = true);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

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

  int get _commentCount => _comments.length;

  Future<void> _toggleLike() async {
    final previous = isLiked;
    setState(() {
      isLiked = !isLiked;
      likeCount += isLiked ? 1 : -1;
    });
    try {
      final result = await CommunityService.likePost(_postId);
      final liked = result['liked'] == true;
      final count = _toInt(result['like_count']);
      if (!mounted) return;
      // Reconcile with persisted server state.
      setState(() {
        isLiked = liked;
        likeCount = count;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        isLiked = previous;
        likeCount = previous ? likeCount + 1 : likeCount - 1;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not update like. Please try again.')),
      );
    }
  }

  Future<void> _submitComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty || _submitting || _postId.isEmpty) return;
    setState(() => _submitting = true);
    try {
      final row = await CommunityService.createComment(_postId, text);
      String author = 'Member';
      final userId = await ApiService.getUserId();
      if (userId != null && userId.isNotEmpty && row['user_id'] == userId) {
        author = 'You';
      }
      if (!mounted) return;
      setState(() {
        _comments.add({
          'author': author,
          'content': (row['content'] as String?) ?? text,
          'created_at': (row['created_at'] as String?) ?? DateTime.now().toIso8601String(),
        });
        _commentController.clear();
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not add comment. Please try again.')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.post['author_name'] as String? ?? 'Anonymous';
    final content = widget.post['content'] as String? ?? '';
    final time = _timeAgo(widget.post['created_at'] as String? ?? '');

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text("Post Details", style: TextStyle(fontWeight: FontWeight.bold)),
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
                  // Author Info
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 25,
                        backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                        child: Text(name.isEmpty ? 'A' : name[0],
                            style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 20)),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Text(time, style: TextStyle(color: Colors.grey[500], fontSize: 13)),
                                if (widget.groupName.isNotEmpty) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withValues(alpha: 0.08),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(widget.groupName,
                                        style: const TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.w600)),
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
                  // Content
                  Text(
                    content,
                    style: const TextStyle(fontSize: 16, height: 1.6, color: Colors.black87),
                  ),
                  const SizedBox(height: 25),
                  // Interaction Stats
                  Row(
                    children: [
                      _buildInteractionButton(
                        isLiked ? Icons.thumb_up_rounded : Icons.thumb_up_off_alt_rounded,
                        "$likeCount Likes",
                        isLiked ? AppColors.primary : Colors.grey,
                        _toggleLike,
                      ),
                      const SizedBox(width: 20),
                      _buildInteractionButton(
                        Icons.chat_bubble_outline_rounded,
                        "$_commentCount Comments",
                        Colors.grey,
                        () {},
                      ),
                    ],
                  ),
                  const Divider(height: 40),
                  const Text("Comments", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 16),
                  if (_loadingComments)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (_commentsLoadFailed)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              "Couldn't load comments.",
                              style: TextStyle(color: Colors.grey[500], fontSize: 13),
                            ),
                          ),
                          TextButton(
                            onPressed: _loadComments,
                            child: const Text("Retry", style: TextStyle(fontSize: 13)),
                          ),
                        ],
                      ),
                    )
                  else if (_comments.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        "No comments yet. Be the first to comment!",
                        style: TextStyle(color: Colors.grey[500], fontSize: 13),
                      ),
                    )
                  else
                    ...List.generate(
                      _comments.length,
                      (i) => _buildCommentItem(
                        _comments[i]['author']! as String,
                        _comments[i]['content']! as String,
                        _comments[i]['created_at']! as String,
                      ),
                    ),
                ],
              ),
            ),
          ),
          // Comment Input
          Container(
            padding: EdgeInsets.only(left: 20, right: 10, bottom: MediaQuery.of(context).padding.bottom + 10, top: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -5)),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    decoration: InputDecoration(
                      hintText: "Add a comment...",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    ),
                    onSubmitted: (_) => _submitComment(),
                  ),
                ),
                IconButton(
                  onPressed: _submitting ? null : _submitComment,
                  icon: const Icon(Icons.send_rounded, color: AppColors.primary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInteractionButton(IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildCommentItem(String name, String text, String time) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: name == "You"
                ? AppColors.primary.withValues(alpha: 0.2)
                : AppColors.primary.withValues(alpha: 0.05),
            child: Text(name.isEmpty ? 'M' : name[0],
                style: TextStyle(color: AppColors.primary, fontSize: 14, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    Text(_timeAgo(time), style: TextStyle(color: Colors.grey[500], fontSize: 11)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(text, style: TextStyle(color: Colors.grey[800], fontSize: 14, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:pregnancy_appp/constants/color.dart';

class PostDetailsPage extends StatefulWidget {
  final String author;
  final String time;
  final String content;
  final int likes;
  final int comments;

  const PostDetailsPage({
    super.key,
    required this.author,
    required this.time,
    required this.content,
    required this.likes,
    required this.comments,
  });

  @override
  State<PostDetailsPage> createState() => _PostDetailsPageState();
}

class _PostDetailsPageState extends State<PostDetailsPage> {
  bool isLiked = false;
  late int likeCount;
  final TextEditingController _commentController = TextEditingController();
  late List<Map<String, String>> _comments;

  @override
  void initState() {
    super.initState();
    likeCount = widget.likes;
    _comments = [
      {"name": "Helen M.", "text": "That's a great question! My doctor said it's safe in moderation.", "time": "30m ago"},
      {"name": "Ruth B.", "text": "I've been drinking it too and it really helps with morning sickness.", "time": "1h ago"},
      {"name": "Sara G.", "text": "Always check with your care provider just to be safe!", "time": "2h ago"},
    ];
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                        backgroundColor: AppColors.primary.withOpacity(0.1),
                        child: Text(widget.author[0], style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 20)),
                      ),
                      const SizedBox(width: 15),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.author, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          Text(widget.time, style: TextStyle(color: Colors.grey[500], fontSize: 13)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Content
                  Text(
                    widget.content,
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
                        () {
                          setState(() {
                            isLiked = !isLiked;
                            isLiked ? likeCount++ : likeCount--;
                          });
                        },
                      ),
                      const SizedBox(width: 20),
                      _buildInteractionButton(
                        Icons.chat_bubble_outline_rounded,
                        "${_comments.length} Comments",
                        Colors.grey,
                        () {},
                      ),
                    ],
                  ),
                  const Divider(height: 40),
                  const Text("Comments", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 16),
                  // Dynamic comments list
                  ...List.generate(
                    _comments.length,
                    (i) => _buildCommentItem(_comments[i]['name']!, _comments[i]['text']!, _comments[i]['time']!),
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
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5)),
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
                  onPressed: _submitComment,
                  icon: const Icon(Icons.send_rounded, color: AppColors.primary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _submitComment() {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _comments.insert(0, {
        "name": "You",
        "text": text,
        "time": "Just now",
      });
    });
    _commentController.clear();
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
            backgroundColor: name == "You" ? AppColors.primary.withOpacity(0.2) : AppColors.primary.withOpacity(0.05),
            child: Text(name[0], style: TextStyle(color: AppColors.primary, fontSize: 14, fontWeight: FontWeight.bold)),
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
                    Text(time, style: TextStyle(color: Colors.grey[500], fontSize: 11)),
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

import 'package:flutter/material.dart';
import 'package:pregnancy_appp/constants/color.dart';
import 'package:pregnancy_appp/screens/community/post_details_page.dart';
import 'package:pregnancy_appp/screens/community/direct_message_page.dart';

class CommunityPage extends StatefulWidget {
  const CommunityPage({super.key});

  @override
  State<CommunityPage> createState() => _CommunityPageState();
}

class _CommunityPageState extends State<CommunityPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String selectedCategory = "All Posts";
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  final List<Map<String, dynamic>> allPosts = [
    {
      "author": "Abeba T.",
      "time": "2h ago",
      "content": "Does anyone know if drinking Bulla during the first trimester is safe? I've heard mixed things.",
      "likes": 12,
      "comments": 5,
      "category": "Nutrition",
    },
    {
      "author": "Marta K.",
      "time": "5h ago",
      "content": "Just had my 20-week scan! Everything looks great. The baby was so active. ❤️",
      "likes": 45,
      "comments": 8,
      "category": "Stories",
    },
    {
      "author": "Selam W.",
      "time": "Yesterday",
      "content": "I'm feeling very tired lately. Any tips for boosting energy naturally?",
      "likes": 28,
      "comments": 15,
      "category": "Health",
    },
    {
      "author": "Tigest H.",
      "time": "Yesterday",
      "content": "Looking for recommendations for a good baby stroller in Addis Ababa. Any tips?",
      "likes": 10,
      "comments": 3,
      "category": "Baby Gear",
    },
  ];

  final Set<int> _likedPosts = {};

  final List<Map<String, dynamic>> _conversations = [
    {"name": "Abeba T.", "initial": "A", "lastMessage": "Does anyone know if drinking Bulla...", "time": "2h ago", "unread": 2},
    {"name": "Marta K.", "initial": "M", "lastMessage": "Yes, I had the same experience!", "time": "5h ago", "unread": 0},
    {"name": "Selam W.", "initial": "S", "lastMessage": "Ginger tea helped me a lot 😊", "time": "Yesterday", "unread": 1},
    {"name": "Tigest H.", "initial": "T", "lastMessage": "Let me know if you need more tips!", "time": "Yesterday", "unread": 0},
    {"name": "Helen M.", "initial": "H", "lastMessage": "How are you feeling today?", "time": "Mon", "unread": 0},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> filteredPosts = allPosts.where((p) {
      final matchCategory = selectedCategory == "All Posts" || p['category'] == selectedCategory;
      final matchSearch = _searchQuery.isEmpty ||
          (p['content'] as String).toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (p['author'] as String).toLowerCase().contains(_searchQuery.toLowerCase());
      return matchCategory && matchSearch;
    }).toList();

    final filteredConversations = _conversations.where((c) {
      return _searchQuery.isEmpty ||
          (c['name'] as String).toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Column(
        children: [
          // ── Header ──────────────────────────────────────────
          Container(
            color: const Color(0xFFF8F9FA),
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Community",
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    TextButton.icon(
                      onPressed: () => _showAddPostModal(context),
                      icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
                      label: const Text("Post"),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        backgroundColor: AppColors.primary.withOpacity(0.08),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // ── Search Bar ──────────────────────────────────
                Container(
                  height: 46,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2)),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) => setState(() => _searchQuery = val),
                    decoration: InputDecoration(
                      hintText: "Search posts or people...",
                      hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                      prefixIcon: Icon(Icons.search_rounded, color: Colors.grey[400], size: 20),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? GestureDetector(
                              onTap: () {
                                _searchController.clear();
                                setState(() => _searchQuery = "");
                              },
                              child: Icon(Icons.close_rounded, color: Colors.grey[400], size: 18),
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // ── Tabs ────────────────────────────────────────
                Container(
                  height: 42,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    onTap: (_) => setState(() {}),
                    indicator: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.grey[600],
                    labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                    unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                    dividerColor: Colors.transparent,
                    splashBorderRadius: BorderRadius.circular(10),
                    tabs: [
                      Tab(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.article_outlined, size: 16,
                                color: _tabController.index == 0 ? Colors.white : Colors.grey[600]),
                            const SizedBox(width: 6),
                            const Text("Posts"),
                          ],
                        ),
                      ),
                      Tab(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.chat_bubble_outline_rounded, size: 16,
                                color: _tabController.index == 1 ? Colors.white : Colors.grey[600]),
                            const SizedBox(width: 6),
                            const Text("Messages"),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),

          // ── Tab Content ─────────────────────────────────────
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // ---- POSTS TAB ----
                Column(
                  children: [
                    // Category chips
                    SizedBox(
                      height: 38,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        children: [
                          _buildCategoryBadge("All Posts"),
                          _buildCategoryBadge("Health"),
                          _buildCategoryBadge("Nutrition"),
                          _buildCategoryBadge("Baby Gear"),
                          _buildCategoryBadge("Stories"),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: filteredPosts.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.search_off_rounded, size: 48, color: Colors.grey[300]),
                                  const SizedBox(height: 12),
                                  Text("No posts found.", style: TextStyle(color: Colors.grey[500])),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              itemCount: filteredPosts.length,
                              itemBuilder: (context, index) {
                                final post = filteredPosts[index];
                                final originalIndex = allPosts.indexOf(post);
                                return _buildFeedItem(context, originalIndex, post);
                              },
                            ),
                    ),
                  ],
                ),

                // ---- MESSAGES TAB ----
                filteredConversations.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.search_off_rounded, size: 48, color: Colors.grey[300]),
                            const SizedBox(height: 12),
                            Text("No people found.", style: TextStyle(color: Colors.grey[500])),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                        itemCount: filteredConversations.length,
                        itemBuilder: (context, index) =>
                            _buildConversationItem(context, filteredConversations[index]),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Add Post Modal ─────────────────────────────────────────────────────────
  void _showAddPostModal(BuildContext context) {
    final textController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close_rounded)),
                  const Text("Create New Post", style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                  TextButton(
                    onPressed: () {
                      if (textController.text.isNotEmpty) {
                        setState(() {
                          allPosts.insert(0, {
                            "author": "You",
                            "time": "Just now",
                            "content": textController.text,
                            "likes": 0,
                            "comments": 0,
                            "category": "All Posts",
                          });
                        });
                        Navigator.pop(ctx);
                      }
                    },
                    child: const Text("Share", style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 15)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                controller: textController,
                maxLines: 5,
                decoration: InputDecoration(
                  hintText: "What's on your mind?",
                  hintStyle: TextStyle(color: Colors.grey[400], fontSize: 15),
                  border: InputBorder.none,
                ),
                style: const TextStyle(fontSize: 15),
              ),
              const Divider(),
              Row(
                children: [
                  IconButton(onPressed: () {}, icon: const Icon(Icons.image_rounded, color: AppColors.primary)),
                  IconButton(onPressed: () {}, icon: const Icon(Icons.emoji_emotions_rounded, color: Colors.orange)),
                  IconButton(onPressed: () {}, icon: const Icon(Icons.location_on_rounded, color: Colors.red)),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  // ── Conversation Item ──────────────────────────────────────────────────────
  Widget _buildConversationItem(BuildContext context, Map<String, dynamic> conv) {
    return GestureDetector(
      onTap: () {
        setState(() => conv['unread'] = 0);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DirectMessagePage(personName: conv['name'], personInitial: conv['initial']),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 3))],
        ),
        child: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.primary.withOpacity(0.12),
                  child: Text(conv['initial'],
                      style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 18)),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 11,
                    height: 11,
                    decoration: BoxDecoration(
                        color: Colors.green, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(conv['name'],
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 3),
                  Text(conv['lastMessage'],
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.grey[500], fontSize: 13)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(conv['time'], style: TextStyle(color: Colors.grey[400], fontSize: 11)),
                if ((conv['unread'] as int) > 0) ...[
                  const SizedBox(height: 6),
                  Container(
                    width: 20,
                    height: 20,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                    child: Text('${conv['unread']}',
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Category Badge ─────────────────────────────────────────────────────────
  Widget _buildCategoryBadge(String label) {
    final isActive = selectedCategory == label;
    return GestureDetector(
      onTap: () => setState(() => selectedCategory = label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isActive ? AppColors.primary : Colors.grey[300]!),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.grey[700],
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  // ── Feed Item ──────────────────────────────────────────────────────────────
  Widget _buildFeedItem(BuildContext context, int index, Map<String, dynamic> post) {
    final name = post['author'] as String;
    final isLiked = _likedPosts.contains(index);
    final displayedLikes = (post['likes'] as int) + (isLiked ? 1 : 0);

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PostDetailsPage(
            author: post['author'],
            time: post['time'],
            content: post['content'],
            likes: post['likes'],
            comments: post['comments'],
          ),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Author row
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                  child: Text(name[0], style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      Text(post['time'],
                          style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                    ],
                  ),
                ),
                // Category chip
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(post['category'],
                      style: const TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Post content
            Text(post['content'],
                style: TextStyle(color: Colors.grey[800], height: 1.45, fontSize: 14),
                maxLines: 3,
                overflow: TextOverflow.ellipsis),
            const SizedBox(height: 14),
            // Divider + actions
            Divider(height: 1, color: Colors.grey[100]),
            const SizedBox(height: 12),
            Row(
              children: [
                // Like
                GestureDetector(
                  onTap: () {
                    setState(() {
                      isLiked ? _likedPosts.remove(index) : _likedPosts.add(index);
                    });
                  },
                  child: Row(
                    children: [
                      Icon(
                        isLiked ? Icons.thumb_up_rounded : Icons.thumb_up_off_alt_rounded,
                        size: 18,
                        color: isLiked ? AppColors.primary : Colors.grey[500],
                      ),
                      const SizedBox(width: 5),
                      Text("$displayedLikes",
                          style: TextStyle(
                              color: isLiked ? AppColors.primary : Colors.grey[500],
                              fontWeight: FontWeight.w600,
                              fontSize: 13)),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                // Comment
                Row(
                  children: [
                    Icon(Icons.chat_bubble_outline_rounded, size: 17, color: Colors.grey[500]),
                    const SizedBox(width: 5),
                    Text("${post['comments']}",
                        style: TextStyle(color: Colors.grey[500], fontSize: 13)),
                  ],
                ),
                const Spacer(),
                Icon(Icons.share_outlined, size: 18, color: Colors.grey[400]),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

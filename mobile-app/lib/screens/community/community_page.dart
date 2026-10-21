import 'package:flutter/material.dart';
import 'package:pregnancy_appp/constants/color.dart';
import 'package:pregnancy_appp/screens/community/post_details_page.dart';
import 'package:pregnancy_appp/services/api_service.dart';
import 'package:pregnancy_appp/services/community_service.dart';
import 'package:pregnancy_appp/services/content_service.dart';
import 'package:pregnancy_appp/widget/status_modal.dart';

class CommunityPage extends StatefulWidget {
  const CommunityPage({super.key});

  @override
  State<CommunityPage> createState() => _CommunityPageState();
}

class _CommunityPageState extends State<CommunityPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = "";
  final TextEditingController _searchController = TextEditingController();

  final List<Map<String, dynamic>> _groups = [];
  final List<dynamic> _posts = [];
  final Set<String> _likedPostIds = {};
  String? _selectedGroupId;

  bool _loadingGroups = true;
  bool _loadingPosts = false;
  String? _groupsError;
  String? _postsError;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _init();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // ── Data loading ──────────────────────────────────────────────────────
  String? _groupNameById(String? id) {
    for (final g in _groups) {
      if (g['id'] == id) return g['name'] as String?;
    }
    return null;
  }

  Future<void> _init() async {
    setState(() {
      _loadingGroups = true;
      _groupsError = null;
    });
    try {
      final rawGroups = await CommunityService.getGroups();
      if (!mounted) return;
      final groups = rawGroups.map((g) => g as Map<String, dynamic>).toList();

      int trimester = 1;
      try {
        trimester = await ContentService.currentTrimester();
      } catch (_) {}

      String? preferred;
      for (final g in groups) {
        if (g['trimester_group'] == trimester) {
          preferred = g['id'] as String?;
          break;
        }
      }

      setState(() {
        _groups
          ..clear()
          ..addAll(groups);
        _selectedGroupId =
            preferred ?? (groups.isNotEmpty ? groups.first['id'] as String? : null);
      });
      if (_selectedGroupId != null) {
        await _loadPosts(_selectedGroupId!);
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _groupsError = e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _groupsError = 'Network error. Please try again.');
    } finally {
      if (mounted) setState(() => _loadingGroups = false);
    }
  }

  Future<void> _loadPosts(String groupId, {bool showSpinner = true}) async {
    if (showSpinner) {
      setState(() {
        _loadingPosts = true;
        _postsError = null;
      });
    }
    try {
      final posts = await CommunityService.getGroupPosts(groupId);
      if (!mounted) return;
      setState(() {
        _posts
          ..clear()
          ..addAll(posts);
        // Persisted like state from the server (liked_by_me).
        _likedPostIds
          ..clear()
          ..addAll({
            for (final p in posts)
              if (p['liked_by_me'] == true) p['id'] as String?,
          }.whereType<String>());
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _postsError = e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _postsError = 'Network error. Please try again.');
    } finally {
      if (mounted) setState(() => _loadingPosts = false);
    }
  }

  Future<void> _selectGroup(String id) async {
    if (id == _selectedGroupId) return;
    setState(() => _selectedGroupId = id);
    await _loadPosts(id);
  }

  // ── Like ──────────────────────────────────────────────────────────────
  // Optimistically toggles, then reconciles with the server's persisted
  // state (likePost returns liked + like_count).
  Future<void> _toggleLike(String postId) async {
    final wasLiked = _likedPostIds.contains(postId);
    final postIndex = _posts.indexWhere((p) => p['id'] == postId);

    setState(() {
      wasLiked ? _likedPostIds.remove(postId) : _likedPostIds.add(postId);
      if (postIndex != -1) {
        final count = _toInt(_posts[postIndex]['like_count']);
        _posts[postIndex]['like_count'] = count + (wasLiked ? -1 : 1);
      }
    });
    try {
      final result = await CommunityService.likePost(postId);
      final liked = result['liked'] == true;
      final count = _toInt(result['like_count']);
      if (!mounted) return;
      setState(() {
        liked ? _likedPostIds.add(postId) : _likedPostIds.remove(postId);
        final i = _posts.indexWhere((p) => p['id'] == postId);
        if (i != -1) _posts[i]['like_count'] = count;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        wasLiked ? _likedPostIds.add(postId) : _likedPostIds.remove(postId);
        final i = _posts.indexWhere((p) => p['id'] == postId);
        if (i != -1) {
          final count = _toInt(_posts[i]['like_count']);
          _posts[i]['like_count'] = count + (wasLiked ? 1 : -1);
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not update like. Please try again.')),
      );
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────
  // Backend COUNT()/bigint values arrive as strings; safe numeric parse.
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
  Widget build(BuildContext context) {
    final filteredPosts = _posts.where((p) {
      final content = (p['content'] as String? ?? '').toLowerCase();
      final author = (p['author_name'] as String? ?? '').toLowerCase();
      final q = _searchQuery.toLowerCase();
      return q.isEmpty || content.contains(q) || author.contains(q);
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      floatingActionButton: _tabController.index == 0
          ? FloatingActionButton.extended(
              onPressed: () => _showAddPostModal(context),
              backgroundColor: AppColors.primary,
              elevation: 4,
              icon: const Icon(Icons.add_rounded, color: Colors.white, size: 20),
              label: const Text(
                "Post",
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
              ),
            )
          : null,
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
                    ElevatedButton.icon(
                      onPressed: () => _showAddPostModal(context),
                      icon: const Icon(Icons.add_rounded, size: 17),
                      label: const Text("Post"),
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: AppColors.primary,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
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
                    SizedBox(height: 38, child: _buildGroupChips()),
                    const SizedBox(height: 10),
                    Expanded(child: _buildPostsArea(filteredPosts)),
                  ],
                ),

                // ---- MESSAGES TAB ----
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.forum_outlined, size: 48, color: Colors.grey[300]),
                        const SizedBox(height: 12),
                        Text(
                          "Member-to-member direct messaging isn't available yet.",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey[500], fontSize: 14, height: 1.5),
                        ),
                      ],
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

  // ── Group Chips ───────────────────────────────────────────────────────
  Widget _buildGroupChips() {
    if (_loadingGroups) {
      return const Center(
        child: SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }
    if (_groupsError != null && _groups.isEmpty) {
      return Center(
        child: Text(_groupsError!, style: TextStyle(color: Colors.grey[500], fontSize: 13)),
      );
    }
    if (_groups.isEmpty) {
      return Center(
        child: Text("No community groups yet.", style: TextStyle(color: Colors.grey[500], fontSize: 13)),
      );
    }
    return ListView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      children: [
        for (final group in _groups) _buildGroupBadge(group),
      ],
    );
  }

  Widget _buildGroupBadge(Map<String, dynamic> group) {
    final label = group['name'] as String? ?? 'Group';
    final id = group['id'] as String?;
    final isActive = id == _selectedGroupId;
    return GestureDetector(
      onTap: () {
        if (id == null) return;
        _selectGroup(id);
      },
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

  // ── Posts area ────────────────────────────────────────────────────────
  Widget _buildPostsArea(List<dynamic> filteredPosts) {
    if (_loadingPosts) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_postsError != null && _posts.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded, size: 48, color: Colors.grey[300]),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _postsError!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[500]),
              ),
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: _selectedGroupId != null ? () => _loadPosts(_selectedGroupId!) : null,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text("Retry"),
            ),
          ],
        ),
      );
    }
    if (_posts.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.forum_outlined, size: 48, color: Colors.grey[300]),
            const SizedBox(height: 12),
            Text("No posts in this group yet.", style: TextStyle(color: Colors.grey[500])),
          ],
        ),
      );
    }
    if (filteredPosts.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off_rounded, size: 48, color: Colors.grey[300]),
            const SizedBox(height: 12),
            Text("No posts found.", style: TextStyle(color: Colors.grey[500])),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: filteredPosts.length,
      itemBuilder: (context, index) => _buildFeedItem(context, filteredPosts[index]),
    );
  }

  // ── Feed Item ─────────────────────────────────────────────────────────
  Widget _buildFeedItem(BuildContext context, Map<String, dynamic> post) {
    final id = post['id'] as String? ?? '';
    final name = post['author_name'] as String? ?? 'Anonymous';
    final content = post['content'] as String? ?? '';
    final time = _timeAgo(post['created_at'] as String? ?? '');
    final commentCount = _toInt(post['comment_count']);
    // Server like_count already reflects this user's like (persisted).
    final displayedLikes = _toInt(post['like_count']);
    final isLiked = _likedPostIds.contains(id);
    final groupName = _groupNameById(_selectedGroupId) ?? '';

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PostDetailsPage(
            post: post,
            groupName: groupName,
            initiallyLiked: isLiked,
          ),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Author row
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  child: Text(name.isEmpty ? 'A' : name[0],
                      style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      Text(time, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                    ],
                  ),
                ),
                // Group chip
                if (groupName.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(groupName,
                        style: const TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.w600)),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            // Post content
            Text(content,
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
                  onTap: () => _toggleLike(id),
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
                    Text("$commentCount",
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

  // ── Add Post Modal ────────────────────────────────────────────────────
  void _showAddPostModal(BuildContext context) {
    final textController = TextEditingController();
    final targetGroupId = _selectedGroupId ?? (_groups.isNotEmpty ? _groups.first['id'] as String? : null);
    final groupName = _groupNameById(targetGroupId) ?? 'Community';
    var isAnonymous = false;
    var submitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          Future<void> submit() async {
            final content = textController.text.trim();
            if (content.isEmpty) {
              ScaffoldMessenger.of(ctx).showSnackBar(
                const SnackBar(
                  content: Text('Please enter something to share.'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
              return;
            }
            if (targetGroupId == null) {
              AppStatusModal.showError(
                context: ctx,
                title: 'No Group Selected',
                message: 'Please choose or wait for a community group to load.',
              );
              return;
            }

            setModalState(() => submitting = true);
            try {
              await CommunityService.createPost(
                groupId: targetGroupId,
                content: content,
                isAnonymous: isAnonymous,
              );
              if (!ctx.mounted) return;
              Navigator.pop(ctx);
              await _loadPosts(targetGroupId, showSpinner: false);
              if (!mounted) return;
              AppStatusModal.showSuccess(
                context: context,
                title: 'Post Published!',
                message: 'Your post was successfully shared in $groupName.',
              );
            } on ApiException catch (e) {
              if (!ctx.mounted) return;
              setModalState(() => submitting = false);
              AppStatusModal.showError(
                context: ctx,
                title: 'Could Not Post',
                message: e.message,
              );
            } catch (_) {
              if (!ctx.mounted) return;
              setModalState(() => submitting = false);
              AppStatusModal.showError(
                context: ctx,
                title: 'Could Not Post',
                message: 'Network error. Please try again.',
              );
            }
          }

          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 20,
                    offset: Offset(0, -4),
                  ),
                ],
              ),
              padding: const EdgeInsets.fromLTRB(22, 14, 22, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Drag Handle
                  Center(
                    child: Container(
                      width: 42,
                      height: 4.5,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Header Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        onPressed: submitting ? null : () => Navigator.pop(ctx),
                        icon: const Icon(Icons.close_rounded, size: 22),
                      ),
                      const Text(
                        "Share with Community",
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                      ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        ),
                        onPressed: submitting ? null : submit,
                        icon: submitting
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.send_rounded, size: 14),
                        label: Text(
                          submitting ? "..." : "Send",
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Target Community Group Banner (shares directly to the community group, no group selector)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(7),
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.groups_rounded, size: 16, color: Colors.white),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Sharing to Community Group",
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 1),
                              Text(
                                groupName,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Content Input Box
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: TextField(
                      controller: textController,
                      minLines: 5,
                      maxLines: 8,
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText: "What's on your mind? Share pregnancy questions, tips, or experiences with other mothers...",
                        hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14, height: 1.4),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                      style: const TextStyle(fontSize: 14.5, height: 1.45),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Anonymous toggle
                  Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: isAnonymous ? AppColors.primary.withValues(alpha: 0.1) : Colors.grey[100],
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                isAnonymous ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                                color: isAnonymous ? AppColors.primary : Colors.grey[600],
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Post anonymously",
                                  style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
                                ),
                                Text(
                                  "Hides your identity from other mothers",
                                  style: TextStyle(fontSize: 11.5, color: Colors.grey[500]),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: isAnonymous,
                        activeColor: AppColors.primary,
                        onChanged: submitting
                            ? null
                            : (val) => setModalState(() => isAnonymous = val),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Bottom Submit Button
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: submitting ? null : submit,
                    icon: submitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.send_rounded, size: 18),
                    label: Text(
                      submitting ? "Sharing..." : "Send Post to $groupName",
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 6),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pregnancy_appp/constants/color.dart';
import 'package:pregnancy_appp/screens/community/direct_message_page.dart';
import 'package:pregnancy_appp/screens/community/post_details_page.dart';
import 'package:pregnancy_appp/services/api_service.dart';
import 'package:pregnancy_appp/services/community_service.dart';
import 'package:pregnancy_appp/services/push_service.dart';
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
  String _selectedGroupId = 'all'; // Default to 'all' public feed

  // Conversations in Messages tab
  final List<Map<String, dynamic>> _conversations = [];
  bool _loadingConversations = false;
  String? _conversationsError;

  bool _loadingGroups = true;
  bool _loadingPosts = false;
  String? _postsError;
  String? _currentUserId;
  String? _userRole;
  bool get _isMother =>
      (_userRole ?? '').toLowerCase().trim() == 'mother' ||
      (_userRole ?? '').toLowerCase().trim() == 'admin';

  Timer? _conversationPollTimer;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabChange);
    _init();
  }

  void _handleTabChange() {
    if (_tabController.index == 1) {
      _loadConversations();
    }
    setState(() {});
  }

  @override
  void dispose() {
    _conversationPollTimer?.cancel();
    try {
      PushService.socket?.off('direct:conversation_update');
    } catch (_) {}
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // ── Data loading ──────────────────────────────────────────────────────
  Future<void> _init() async {
    _currentUserId = await ApiService.getUserId();
    _userRole = await ApiService.getUserRole();
    setState(() {
      _loadingGroups = true;
    });

    try {
      final rawGroups = await CommunityService.getGroups();
      if (!mounted) return;
      final groups = rawGroups.map((g) => g as Map<String, dynamic>).toList();

      setState(() {
        _groups
          ..clear()
          ..addAll(groups);
      });

      // Default: load all public posts
      await _loadPosts('all');
    } on ApiException {
      if (!mounted) return;
    } catch (_) {
      if (!mounted) return;
    } finally {
      if (mounted) setState(() => _loadingGroups = false);
    }

    // Socket listener for conversation updates
    try {
      PushService.socket?.on('direct:conversation_update', (_) {
        if (mounted && _tabController.index == 1) {
          _loadConversations(showSpinner: false);
        }
      });
      PushService.socket?.on('direct:message', (_) {
        if (mounted && _tabController.index == 1) {
          _loadConversations(showSpinner: false);
        }
      });
    } catch (_) {}
  }

  Future<void> _loadPosts(String groupId, {bool showSpinner = true}) async {
    if (showSpinner) {
      setState(() {
        _loadingPosts = true;
        _postsError = null;
      });
    }
    try {
      final posts = await CommunityService.getAllPosts(
        groupId: groupId == 'all' ? null : groupId,
      );
      if (!mounted) return;
      setState(() {
        _posts
          ..clear()
          ..addAll(posts);
        // Persisted like state from the server (liked_by_me)
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
      if (mounted && showSpinner) setState(() => _loadingPosts = false);
    }
  }

  Future<void> _loadConversations({bool showSpinner = true}) async {
    if (showSpinner) {
      setState(() {
        _loadingConversations = true;
        _conversationsError = null;
      });
    }
    try {
      final data = await CommunityService.getConversations();
      if (!mounted) return;
      final list = data.map((c) => Map<String, dynamic>.from(c as Map)).toList();
      setState(() {
        _conversations
          ..clear()
          ..addAll(list);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _conversationsError = 'Could not load conversations');
    } finally {
      if (mounted && showSpinner) {
        setState(() => _loadingConversations = false);
      }
    }
  }

  Future<void> _selectGroup(String id) async {
    if (id == _selectedGroupId) return;
    setState(() => _selectedGroupId = id);
    await _loadPosts(id);
  }

  // ── Like ──────────────────────────────────────────────────────────────
  Future<void> _toggleLike(String postId) async {
    if (!_isMother) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Only registered mothers can like posts in the community.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

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

  // ── Author Profile & Private Messaging ────────────────────────────────
  void _showAuthorProfile(BuildContext context, Map<String, dynamic> post) {
    final isAnonymous = post['is_anonymous'] == true;
    final authorId = post['author_id']?.toString();
    final authorName = (post['author_name'] as String?) ?? 'Anonymous';
    final authorPhoto = post['author_photo'] as String?;

    if (isAnonymous || authorId == null || authorId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This mother posted anonymously to protect her privacy.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final isMe = authorId == _currentUserId;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) {
        final hasPhoto = authorPhoto != null && authorPhoto.trim().isNotEmpty;
        final initial = authorName.isNotEmpty ? authorName[0].toUpperCase() : 'M';

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 4.5,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                CircleAvatar(
                  radius: 36,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                  backgroundImage: hasPhoto ? NetworkImage(ApiService.resolveUrl(authorPhoto)) : null,
                  child: hasPhoto
                      ? null
                      : Text(
                          initial,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                ),
                const SizedBox(height: 12),
                Text(
                  authorName,
                  style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isMe ? "You (Post Author)" : "Mother in Mom Care Community",
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                if (!isMe) ...[
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.chat_bubble_outline_rounded, size: 19),
                    label: Text(
                      "Chat Privately with $authorName",
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    onPressed: () {
                      if (!_isMother) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Only registered mothers can communicate in private chats.'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                        return;
                      }
                      Navigator.pop(sheetContext);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DirectMessagePage(
                            otherUserId: authorId,
                            otherUserName: authorName,
                            otherUserPhoto: authorPhoto,
                          ),
                        ),
                      ).then((_) {
                        _loadConversations(showSpinner: false);
                      });
                    },
                  ),
                  const SizedBox(height: 10),
                ],
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 44),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: () => Navigator.pop(sheetContext),
                  child: const Text("Close"),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────
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

    final filteredConversations = _conversations.where((c) {
      final name = (c['other_user_name'] as String? ?? '').toLowerCase();
      final msg = (c['last_message'] as String? ?? '').toLowerCase();
      final q = _searchQuery.toLowerCase();
      return q.isEmpty || name.contains(q) || msg.contains(q);
    }).toList();

    final totalUnreadMessages = _conversations.fold<int>(
      0,
      (sum, c) => sum + _toInt(c['unread_count']),
    );

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
                    OutlinedButton.icon(
                      onPressed: () => _showRulesModal(context),
                      icon: const Icon(Icons.shield_outlined, size: 16, color: AppColors.primary),
                      label: const Text(
                        "Guidelines",
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.primary, width: 1.2),
                        backgroundColor: const Color(0xFFFDF2F8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // ── Search Bar (Filters Posts and Conversations) ────
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
                      hintText: _tabController.index == 0
                          ? "Search thoughts or mothers..."
                          : "Search conversations or mothers...",
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
                            if (totalUnreadMessages > 0) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                decoration: BoxDecoration(
                                  color: _tabController.index == 1 ? Colors.white : Colors.red[600],
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  totalUnreadMessages > 99 ? '99+' : '$totalUnreadMessages',
                                  style: TextStyle(
                                    color: _tabController.index == 1 ? AppColors.primary : Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
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

                // ---- MESSAGES TAB (Functional Private Chats) ----
                _buildMessagesArea(filteredConversations),
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

    final allItems = <Map<String, dynamic>>[
      {'id': 'all', 'name': 'All Community'},
      ..._groups,
    ];

    return ListView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      children: [
        for (final group in allItems) _buildGroupBadge(group),
      ],
    );
  }

  Widget _buildGroupBadge(Map<String, dynamic> group) {
    final label = group['name'] as String? ?? 'Group';
    final id = group['id'] as String? ?? 'all';
    final isActive = id == _selectedGroupId;

    return GestureDetector(
      onTap: () => _selectGroup(id),
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

  // ── Posts Area ────────────────────────────────────────────────────────
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
              onPressed: () => _loadPosts(_selectedGroupId),
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
            Text(
              "No thoughts shared in this feed yet.",
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () => _showAddPostModal(context),
              icon: const Icon(Icons.edit_note_rounded, size: 18),
              label: const Text("Share First Thought"),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
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
            Text("No posts match your search.", style: TextStyle(color: Colors.grey[500])),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadPosts(_selectedGroupId, showSpinner: false),
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: filteredPosts.length,
        itemBuilder: (context, index) => _buildFeedItem(context, filteredPosts[index]),
      ),
    );
  }

  // ── Feed Item ─────────────────────────────────────────────────────────
  Widget _buildFeedItem(BuildContext context, Map<String, dynamic> post) {
    final id = post['id'] as String? ?? '';
    final isAnonymous = post['is_anonymous'] == true;
    final name = isAnonymous ? 'Anonymous' : (post['author_name'] as String? ?? 'Mother');
    final authorId = post['author_id']?.toString();
    final authorPhoto = post['author_photo'] as String?;
    final content = post['content'] as String? ?? '';
    final time = _timeAgo(post['created_at'] as String? ?? '');
    final commentCount = _toInt(post['comment_count']);
    final displayedLikes = _toInt(post['like_count']);
    final isLiked = _likedPostIds.contains(id);
    final groupName = (post['group_name'] as String?) ?? 'Public';

    final hasPhoto = !isAnonymous && authorPhoto != null && authorPhoto.trim().isNotEmpty;
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'M';
    final canChat = !isAnonymous && authorId != null && authorId != _currentUserId;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Author row - tapping author views their profile
          Row(
            children: [
              GestureDetector(
                onTap: () => _showAuthorProfile(context, post),
                child: CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  backgroundImage: hasPhoto ? NetworkImage(ApiService.resolveUrl(authorPhoto)) : null,
                  child: hasPhoto
                      ? null
                      : Text(
                          initial,
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () => _showAuthorProfile(context, post),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              name,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (canChat) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFDF2F8),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.chat_bubble_outline_rounded, size: 10, color: AppColors.primary),
                                  SizedBox(width: 3),
                                  Text("Chat", style: TextStyle(color: AppColors.primary, fontSize: 9.5, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                      Text(time, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                    ],
                  ),
                ),
              ),
              // Group / Public Chip
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  groupName,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 2),
              // More Actions Menu
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded, size: 20, color: Colors.grey),
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                onSelected: (val) {
                  if (val == 'copy') {
                    _copyPost(content);
                  } else if (val == 'edit') {
                    _showEditPostModal(context, post);
                  } else if (val == 'delete') {
                    _confirmDeletePost(context, id);
                  } else if (val == 'report') {
                    _reportPost(context, id);
                  }
                },
                itemBuilder: (ctx) {
                  final isMyPost = post['is_mine'] == true ||
                      (!isAnonymous && authorId != null && authorId == _currentUserId) ||
                      _userRole == 'admin';
                  return [
                    const PopupMenuItem(
                      value: 'copy',
                      child: Row(
                        children: [
                          Icon(Icons.copy_rounded, size: 18, color: AppColors.primary),
                          SizedBox(width: 8),
                          Text("Copy Text"),
                        ],
                      ),
                    ),
                    if (isMyPost) ...[
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit_outlined, size: 18, color: Colors.blueAccent),
                            SizedBox(width: 8),
                            Text("Edit Post"),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline_rounded, size: 18, color: Colors.red[600]),
                            const SizedBox(width: 8),
                            Text("Delete Post", style: TextStyle(color: Colors.red[600])),
                          ],
                        ),
                      ),
                    ] else ...[
                      const PopupMenuItem(
                        value: 'report',
                        child: Row(
                          children: [
                            Icon(Icons.flag_outlined, size: 18, color: Colors.amber),
                            SizedBox(width: 8),
                            Text("Report Post"),
                          ],
                        ),
                      ),
                    ],
                  ];
                },
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Post content - tapping opens details, long-press copies
          GestureDetector(
            onLongPress: () => _copyPost(content),
            onTap: () => _openPostDetails(post, groupName, isLiked),
            child: Text(
              content,
              style: TextStyle(color: Colors.grey[800], height: 1.45, fontSize: 14),
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 14),

          // Divider + Actions
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
                    Text(
                      "$displayedLikes",
                      style: TextStyle(
                        color: isLiked ? AppColors.primary : Colors.grey[500],
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 22),
              // Comment
              GestureDetector(
                onTap: () => _openPostDetails(post, groupName, isLiked),
                child: Row(
                  children: [
                    Icon(Icons.chat_bubble_outline_rounded, size: 17, color: Colors.grey[500]),
                    const SizedBox(width: 5),
                    Text(
                      "$commentCount",
                      style: TextStyle(color: Colors.grey[500], fontSize: 13),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              // Private message action button if author is another mother
              if (canChat)
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DirectMessagePage(
                          otherUserId: authorId,
                          otherUserName: name,
                          otherUserPhoto: authorPhoto,
                        ),
                      ),
                    ).then((_) => _loadConversations(showSpinner: false));
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.mail_outline_rounded, size: 14, color: AppColors.primary),
                        SizedBox(width: 4),
                        Text(
                          "Message",
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Messages Tab (Live Direct Conversations) ──────────────────────────
  Widget _buildMessagesArea(List<Map<String, dynamic>> filteredConversations) {
    if (_loadingConversations) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_conversationsError != null && _conversations.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded, size: 48, color: Colors.grey[300]),
            const SizedBox(height: 12),
            Text(_conversationsError!, style: TextStyle(color: Colors.grey[500])),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () => _loadConversations(),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text("Retry"),
            ),
          ],
        ),
      );
    }

    if (_conversations.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 36),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.chat_bubble_outline_rounded, size: 48, color: AppColors.primary),
              ),
              const SizedBox(height: 18),
              const Text(
                "No Private Chats Yet",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                "Tap any mother's profile photo in the Posts tab to start a private conversation.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600], fontSize: 13.5, height: 1.45),
              ),
              const SizedBox(height: 18),
              OutlinedButton.icon(
                onPressed: () => _tabController.animateTo(0),
                icon: const Icon(Icons.people_alt_outlined, size: 18),
                label: const Text("Explore Community Posts"),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (filteredConversations.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off_rounded, size: 48, color: Colors.grey[300]),
            const SizedBox(height: 12),
            Text("No conversations match your search.", style: TextStyle(color: Colors.grey[500])),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadConversations(showSpinner: false),
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        itemCount: filteredConversations.length,
        itemBuilder: (context, index) => _buildConversationItem(context, filteredConversations[index]),
      ),
    );
  }

  Widget _buildConversationItem(BuildContext context, Map<String, dynamic> conv) {
    final otherUserId = conv['other_user_id']?.toString() ?? '';
    final otherUserName = (conv['other_user_name'] as String?) ?? 'Mother';
    final otherUserPhoto = conv['other_user_photo'] as String?;
    final lastMessage = (conv['last_message'] as String?) ?? '';
    final isLastSender = conv['is_last_sender'] == true;
    final unreadCount = _toInt(conv['unread_count']);
    final time = _timeAgo(conv['last_message_at'] as String? ?? '');

    final hasPhoto = otherUserPhoto != null && otherUserPhoto.trim().isNotEmpty;
    final initial = otherUserName.isNotEmpty ? otherUserName[0].toUpperCase() : 'M';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DirectMessagePage(
              otherUserId: otherUserId,
              otherUserName: otherUserName,
              otherUserPhoto: otherUserPhoto,
            ),
          ),
        ).then((_) => _loadConversations(showSpinner: false));
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
              backgroundImage: hasPhoto ? NetworkImage(ApiService.resolveUrl(otherUserPhoto)) : null,
              child: hasPhoto
                  ? null
                  : Text(
                      initial,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          otherUserName,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        time,
                        style: TextStyle(
                          fontSize: 11,
                          color: unreadCount > 0 ? AppColors.primary : Colors.grey[500],
                          fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          isLastSender ? "You: $lastMessage" : lastMessage,
                          style: TextStyle(
                            fontSize: 13,
                            color: unreadCount > 0 ? Colors.black87 : Colors.grey[600],
                            fontWeight: unreadCount > 0 ? FontWeight.w600 : FontWeight.normal,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (unreadCount > 0)
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            "$unreadCount",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Add Post Modal (Shares Publicly Without Needing a Group) ───────────
  void _showAddPostModal(BuildContext context) {
    if (!_isMother) {
      AppStatusModal.showError(
        context: context,
        title: 'Registered Mothers Only',
        message: 'Only registered mothers can post and share thoughts in the community.',
      );
      return;
    }

    final textController = TextEditingController();
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
                  content: Text('Please enter your thoughts to share.'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
              return;
            }

            setModalState(() => submitting = true);
            try {
              // Post publicly to community feed (groupId optional)
              final targetGroupId = (_selectedGroupId != 'all') ? _selectedGroupId : null;
              await CommunityService.createPost(
                groupId: targetGroupId,
                content: content,
                isAnonymous: isAnonymous,
              );
              if (!ctx.mounted) return;
              Navigator.pop(ctx);
              await _loadPosts(_selectedGroupId, showSpinner: false);
              if (!mounted) return;
              AppStatusModal.showSuccess(
                context: context,
                title: 'Thought Shared!',
                message: 'Your thought was posted publicly to the community feed.',
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
                        "Share Your Thoughts",
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

                  // Public Community Banner (Shares publicly to all mothers, no group needed)
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
                          child: const Icon(Icons.public_rounded, size: 16, color: Colors.white),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Posting Publicly",
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 1),
                              const Text(
                                "Shared with all mothers in Mom Care",
                                style: TextStyle(
                                  fontSize: 13.5,
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
                        hintText: "What's on your mind? Share questions, thoughts, or experiences with other mothers...",
                        hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14, height: 1.4),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                      style: const TextStyle(fontSize: 14.5, height: 1.45),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Anonymous Toggle
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
                                  "Hides your name and profile picture",
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
                      submitting ? "Sharing..." : "Share Publicly",
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
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

  // ── Community Guidelines Modal ─────────────────────────────────────────
  Future<void> _showRulesModal(BuildContext context) async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return FutureBuilder<Map<String, dynamic>>(
          future: CommunityService.getCommunityRules(),
          builder: (ctx, snapshot) {
            final rulesContent = snapshot.data?['content'] as String? ??
                '''Community Guidelines for Mom Care

1. Be kind and respectful to all community members.
2. Do not share unverified medical advice or remedies.
3. Respect privacy — do not share personal health information publicly.
4. Spam, advertisements, or promotional content are strictly prohibited.
5. Posts flagged by multiple users will be reviewed by an admin.
6. Community support is not a substitute for professional medical care.
7. Always consult a licensed doctor for any health concerns.''';

            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 44,
                        height: 4.5,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.shield_rounded, color: AppColors.primary, size: 22),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Community Guidelines",
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                "Official guidelines set by Mom Care moderation",
                                style: TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Divider(height: 1, color: Colors.grey[200]),
                    const SizedBox(height: 14),
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(ctx).size.height * 0.55,
                      ),
                      child: snapshot.connectionState == ConnectionState.waiting
                          ? const Center(
                              child: Padding(
                                padding: EdgeInsets.all(24),
                                child: CircularProgressIndicator(),
                              ),
                            )
                          : SingleChildScrollView(
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Colors.grey[200]!),
                                ),
                                child: Text(
                                  rulesContent,
                                  style: TextStyle(
                                    fontSize: 14,
                                    height: 1.6,
                                    color: Colors.grey[800],
                                  ),
                                ),
                              ),
                            ),
                    ),
                    const SizedBox(height: 18),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 48),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text("I Understand & Agree", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ── Open Post Details & Handle updates/deletes ─────────────────────────
  Future<void> _openPostDetails(Map<String, dynamic> post, String groupName, bool isLiked) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PostDetailsPage(
          post: post,
          groupName: groupName,
          initiallyLiked: isLiked,
        ),
      ),
    );
    if (!mounted) return;
    if (result is Map && result['deleted'] == true) {
      setState(() {
        _posts.removeWhere((p) => p['id']?.toString() == result['id']?.toString());
      });
    } else {
      setState(() {});
    }
  }

  // ── Copy Post ──────────────────────────────────────────────────────────
  void _copyPost(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Post content copied to clipboard'),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ── Edit Post Modal ────────────────────────────────────────────────────
  void _showEditPostModal(BuildContext context, Map<String, dynamic> post) {
    final postId = post['id']?.toString() ?? '';
    final textController = TextEditingController(text: post['content'] as String? ?? '');
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
                const SnackBar(content: Text('Post content cannot be empty.')),
              );
              return;
            }

            setModalState(() => submitting = true);
            try {
              await CommunityService.updatePost(postId, content);
              if (!ctx.mounted) return;
              Navigator.pop(ctx);
              setState(() {
                final idx = _posts.indexWhere((p) => p['id']?.toString() == postId);
                if (idx != -1) {
                  _posts[idx]['content'] = content;
                }
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Post updated successfully'),
                  duration: Duration(seconds: 2),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            } catch (e) {
              if (!ctx.mounted) return;
              setModalState(() => submitting = false);
              ScaffoldMessenger.of(ctx).showSnackBar(
                SnackBar(content: Text('Failed to update post: $e')),
              );
            }
          }

          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(28),
                  topRight: Radius.circular(28),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(22, 14, 22, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        onPressed: submitting ? null : () => Navigator.pop(ctx),
                        icon: const Icon(Icons.close_rounded, size: 22),
                      ),
                      const Text(
                        "Edit Post",
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        ),
                        onPressed: submitting ? null : submit,
                        child: submitting
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Text("Save", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
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
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                      style: const TextStyle(fontSize: 14.5, height: 1.45),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Delete Post Confirmation ──────────────────────────────────────────
  Future<void> _confirmDeletePost(BuildContext context, String postId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Delete Post"),
        content: const Text("Are you sure you want to delete this post? This cannot be undone."),
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
        await CommunityService.deletePost(postId);
        if (!mounted) return;
        setState(() {
          _posts.removeWhere((p) => p['id']?.toString() == postId);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Post deleted successfully'),
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete post: $e')),
        );
      }
    }
  }

  // ── Report Post Modal ─────────────────────────────────────────────────
  Future<void> _reportPost(BuildContext context, String postId) async {
    final reasonController = TextEditingController();
    final submit = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Report Post"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Please tell us why you are reporting this post:",
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                hintText: "Reason for reporting...",
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[600],
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Submit Report"),
          ),
        ],
      ),
    );

    if (submit == true) {
      try {
        await CommunityService.reportPost(postId, reason: reasonController.text.trim());
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Post flagged for admin review. Thank you.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to report post: $e')),
        );
      }
    }
  }
}
import 'api_service.dart';

class CommunityService {
  // ── Groups ────────────────────────────────────────────────────────────
  static Future<List<dynamic>> getGroups() async {
    final response = await ApiService.get(ApiEndpoints.communityGroups);
    return response['data'] as List<dynamic>? ?? [];
  }

  // ── Public or Group feed ──────────────────────────────────────────────
  static Future<List<dynamic>> getAllPosts({
    int page = 1,
    int limit = 50,
    String? groupId,
  }) async {
    final response = await ApiService.get(
      ApiEndpoints.communityFeed(page: page, limit: limit, groupId: groupId),
    );
    return response['data'] as List<dynamic>? ?? [];
  }

  // ── Legacy / specific group posts ─────────────────────────────────────
  static Future<List<dynamic>> getGroupPosts(
    String groupId, {
    int page = 1,
    int limit = 50,
  }) async {
    return getAllPosts(page: page, limit: limit, groupId: groupId);
  }

  // ── Create post (groupId is optional) ─────────────────────────────────
  static Future<Map<String, dynamic>> createPost({
    String? groupId,
    required String content,
    bool isAnonymous = false,
  }) async {
    final body = <String, dynamic>{
      'content': content,
      'isAnonymous': isAnonymous,
    };
    if (groupId != null && groupId.isNotEmpty && groupId != 'all') {
      body['groupId'] = groupId;
    }
    final response = await ApiService.post(
      ApiEndpoints.communityPosts,
      body: body,
    );
    return response['data'] as Map<String, dynamic>;
  }

  // ── Add comment ───────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> createComment(
    String postId,
    String content,
  ) async {
    final response = await ApiService.post(
      ApiEndpoints.postCommentsCreate(postId),
      body: {'content': content},
    );
    return response['data'] as Map<String, dynamic>;
  }

  // ── Post comment history ──────────────────────────────────────────────
  static Future<List<dynamic>> getPostComments(
    String postId, {
    int page = 1,
    int limit = 50,
  }) async {
    final response = await ApiService.get(
      ApiEndpoints.postComments(postId, page: page, limit: limit),
    );
    return response['data'] as List<dynamic>? ?? [];
  }

  // ── Like a post ───────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> likePost(String postId) async {
    final response = await ApiService.put(ApiEndpoints.postLike(postId));
    return response['data'] as Map<String, dynamic>? ?? {};
  }

  // ── Flag / Report post ────────────────────────────────────────────────
  static Future<void> reportPost(String postId, {String? reason}) async {
    await ApiService.put(
      ApiEndpoints.postFlag(postId),
      body: {'reason': reason ?? 'Reported by community member'},
    );
  }

  // ── Edit / Delete Post ────────────────────────────────────────────────
  static Future<Map<String, dynamic>> updatePost(String postId, String content) async {
    final response = await ApiService.put(
      ApiEndpoints.postUpdate(postId),
      body: {'content': content},
    );
    return response['data'] as Map<String, dynamic>? ?? {};
  }

  static Future<void> deletePost(String postId) async {
    await ApiService.delete(ApiEndpoints.postDelete(postId));
  }

  // ── Community Guidelines & Rules ─────────────────────────────────────
  static Future<Map<String, dynamic>> getCommunityRules() async {
    final response = await ApiService.get(ApiEndpoints.communityRules);
    return response['data'] as Map<String, dynamic>? ?? {};
  }

  // ── Direct Messaging (Mother-to-Mother) ───────────────────────────────
  static Future<List<dynamic>> getConversations() async {
    final response = await ApiService.get(ApiEndpoints.directMessageConversations);
    return response['data'] as List<dynamic>? ?? [];
  }

  static Future<List<dynamic>> getDirectMessages(
    String otherUserId, {
    int page = 1,
    int limit = 50,
  }) async {
    final response = await ApiService.get(
      ApiEndpoints.directMessages(otherUserId, page: page, limit: limit),
    );
    return response['data'] as List<dynamic>? ?? [];
  }

  static Future<Map<String, dynamic>> sendDirectMessage({
    required String otherUserId,
    required String messageText,
  }) async {
    final response = await ApiService.post(
      ApiEndpoints.sendDirectMessage(otherUserId),
      body: {'messageText': messageText},
    );
    return response['data'] as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> updateDirectMessage(
    String messageId,
    String text,
  ) async {
    final response = await ApiService.put(
      ApiEndpoints.directMessageUpdate(messageId),
      body: {'messageText': text},
    );
    return response['data'] as Map<String, dynamic>? ?? {};
  }

  static Future<void> deleteDirectMessage(String messageId) async {
    await ApiService.delete(ApiEndpoints.directMessageDelete(messageId));
  }
}
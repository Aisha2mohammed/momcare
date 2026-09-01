import 'api_service.dart';

class CommunityService {
  // ── Groups ────────────────────────────────────────────────────────────
  static Future<List<dynamic>> getGroups() async {
    final response = await ApiService.get('/community/groups');
    return response['data'] as List<dynamic>? ?? [];
  }

  // ── Group posts ───────────────────────────────────────────────────────
  static Future<List<dynamic>> getGroupPosts(
    String groupId, {
    int page = 1,
    int limit = 50,
  }) async {
    final response = await ApiService.get(
      '/community/groups/$groupId/posts?page=$page&limit=$limit',
    );
    return response['data'] as List<dynamic>? ?? [];
  }

  // ── Create post ───────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> createPost({
    required String groupId,
    required String content,
    bool isAnonymous = false,
  }) async {
    final response = await ApiService.post(
      '/community/posts',
      body: {
        'groupId': groupId,
        'content': content,
        'isAnonymous': isAnonymous,
      },
    );
    return response['data'] as Map<String, dynamic>;
  }

  // ── Add comment ───────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> createComment(
    String postId,
    String content,
  ) async {
    final response = await ApiService.post(
      '/community/posts/$postId/comments',
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
      '/community/posts/$postId/comments?page=$page&limit=$limit',
    );
    return response['data'] as List<dynamic>? ?? [];
  }

  // ── Like a post ───────────────────────────────────────────────────────
  // Returns persisted like state + count from the server.
  static Future<Map<String, dynamic>> likePost(String postId) async {
    final response = await ApiService.put('/community/posts/$postId/like');
    return response['data'] as Map<String, dynamic>? ?? {};
  }
}
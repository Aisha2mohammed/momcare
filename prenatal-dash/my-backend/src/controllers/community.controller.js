const { query } = require('../config/db');
const { sendSuccess, sendError, sendPaginated } = require('../utils/apiResponse');

// ── GET /api/v1/community/groups ──────────────────────────────────────
exports.getGroups = async (req, res, next) => {
  try {
    const result = await query(
      'SELECT id, trimester_group, name FROM community_groups ORDER BY trimester_group'
    );
    return sendSuccess(res, 200, 'Community groups retrieved', result.rows);
  } catch (err) {
    next(err);
  }
};

// ── GET /api/v1/community/groups/:id/posts ───────────────────────────
exports.getGroupPosts = async (req, res, next) => {
  try {
    const { id } = req.params;
    const { page = 1, limit = 20 } = req.query;
    const offset = (Number(page) - 1) * Number(limit);

    const countResult = await query(
      'SELECT COUNT(*) FROM community_posts WHERE group_id = $1 AND is_deleted = false',
      [id]
    );
    const total = parseInt(countResult.rows[0].count, 10);

    const result = await query(
      `SELECT cp.id, cp.content, cp.is_anonymous, cp.created_at,
              u.name as author_name,
              (SELECT COUNT(*) FROM community_comments WHERE post_id = cp.id AND is_deleted = false) as comment_count,
              (SELECT COUNT(*) FROM community_post_likes WHERE post_id = cp.id) as like_count,
              COALESCE(EXISTS(
                SELECT 1 FROM community_post_likes WHERE post_id = cp.id AND user_id = $2
              ), false) as liked_by_me
       FROM community_posts cp
       JOIN users u ON cp.user_id = u.id
       WHERE cp.group_id = $1 AND cp.is_deleted = false
       ORDER BY cp.created_at DESC
       LIMIT $3 OFFSET $4`,
      [id, req.user ? req.user.id : null, Number(limit), offset]
    );

    // Anonymize if requested
    const sanitized = result.rows.map(post => ({
      ...post,
      author_name: post.is_anonymous ? 'Anonymous' : post.author_name,
    }));

    return sendPaginated(res, sanitized, page, limit, total);
  } catch (err) {
    next(err);
  }
};

// ── POST /api/v1/community/posts ──────────────────────────────────────
exports.createPost = async (req, res, next) => {
  try {
    const { groupId, content, isAnonymous } = req.body;

    if (!groupId || !content) {
      return sendError(res, 400, 'groupId and content are required.');
    }

    const result = await query(
      `INSERT INTO community_posts (user_id, group_id, content, is_anonymous)
       VALUES ($1, $2, $3, $4) RETURNING *`,
      [req.user.id, groupId, content, isAnonymous || false]
    );

    return sendSuccess(res, 201, 'Post created', result.rows[0]);
  } catch (err) {
    next(err);
  }
};

// ── POST /api/v1/community/posts/:id/comments ─────────────────────────
exports.createComment = async (req, res, next) => {
  try {
    const { id } = req.params;
    const { content } = req.body;

    if (!content) return sendError(res, 400, 'Content is required.');

    // Verify post exists
    const post = await query('SELECT id FROM community_posts WHERE id = $1 AND is_deleted = false', [id]);
    if (post.rows.length === 0) return sendError(res, 404, 'Post not found.');

    const result = await query(
      `INSERT INTO community_comments (post_id, user_id, content)
       VALUES ($1, $2, $3) RETURNING *`,
      [id, req.user.id, content]
    );

    return sendSuccess(res, 201, 'Comment created', result.rows[0]);
  } catch (err) {
    next(err);
  }
};

// ── GET /api/v1/community/posts/:id/comments ──────────────────────────
exports.getPostComments = async (req, res, next) => {
  try {
    const { id } = req.params;
    const { page = 1, limit = 20 } = req.query;
    const offset = (Number(page) - 1) * Number(limit);

    const post = await query('SELECT id FROM community_posts WHERE id = $1 AND is_deleted = false', [id]);
    if (post.rows.length === 0) return sendError(res, 404, 'Post not found.');

    const countResult = await query(
      'SELECT COUNT(*) FROM community_comments WHERE post_id = $1 AND is_deleted = false',
      [id]
    );
    const total = parseInt(countResult.rows[0].count, 10);

    const result = await query(
      `SELECT c.id, c.content, c.created_at,
              u.name as author_name
       FROM community_comments c
       JOIN users u ON c.user_id = u.id
       WHERE c.post_id = $1 AND c.is_deleted = false
       ORDER BY c.created_at ASC
       LIMIT $2 OFFSET $3`,
      [id, Number(limit), offset]
    );

    // Mirror the posts anonymization pattern (commenter name from users).
    const sanitized = result.rows.map(comment => ({
      ...comment,
      author_name: comment.author_name || 'Anonymous',
    }));

    return sendPaginated(res, sanitized, page, limit, total);
  } catch (err) {
    next(err);
  }
};

// ── PUT /api/v1/community/posts/:id/like ──────────────────────────────
exports.likePost = async (req, res, next) => {
  try {
    const { id } = req.params;
    const userId = req.user.id;

    // Verify post exists
    const post = await query('SELECT id FROM community_posts WHERE id = $1 AND is_deleted = false', [id]);
    if (post.rows.length === 0) return sendError(res, 404, 'Post not found.');

    // Upsert: a user can only like a post once (unique post_id + user_id).
    await query(
      `INSERT INTO community_post_likes (post_id, user_id)
       VALUES ($1, $2)
       ON CONFLICT (post_id, user_id) DO NOTHING`,
      [id, userId]
    );

    const likeCount = await query(
      'SELECT COUNT(*) FROM community_post_likes WHERE post_id = $1',
      [id]
    );

    return sendSuccess(res, 200, 'Post liked', {
      liked: true,
      like_count: parseInt(likeCount.rows[0].count, 10),
    });
  } catch (err) {
    next(err);
  }
};

// ── DELETE /api/v1/admin/community/posts/:id (admin) ─────────────────
exports.deletePost = async (req, res, next) => {
  try {
    const { id } = req.params;

    const result = await query(
      `UPDATE community_posts SET is_deleted = true, deleted_by_admin_id = $1 WHERE id = $2 RETURNING id`,
      [req.user.id, id]
    );

    if (result.rows.length === 0) return sendError(res, 404, 'Post not found.');

    // Log audit
    const { logAdminAction } = require('../services/auditLogger');
    await logAdminAction(req.user.id, 'DELETE', 'community_posts', id, { reason: 'Moderated by admin' });

    return sendSuccess(res, 200, 'Post removed');
  } catch (err) {
    next(err);
  }
};

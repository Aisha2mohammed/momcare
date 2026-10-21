const { query } = require('../config/db');
const { sendSuccess, sendError, sendPaginated } = require('../utils/apiResponse');

const isUUID = (str) => /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(String(str || '').trim());

function ensureRegisteredMother(req, res) {
  const role = (req.user?.role || '').toLowerCase().trim();
  if (!req.user || (role !== 'mother' && role !== 'admin')) {
    sendError(res, 403, 'Only registered mothers can participate in community discussions and private messaging.');
    return false;
  }
  return true;
}

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

// ── GET /api/v1/community/posts (Public Community Feed) ───────────────
exports.getAllPosts = async (req, res, next) => {
  try {
    const { page = 1, limit = 20, groupId } = req.query;
    const offset = (Number(page) - 1) * Number(limit);
    const userId = req.user ? req.user.id : null;

    const isFilteredByGroup = Boolean(
      groupId &&
      groupId !== 'all' &&
      groupId !== 'null' &&
      groupId !== 'undefined' &&
      String(groupId).trim().length > 0
    );

    const groupCondition = isFilteredByGroup ? 'AND cp.group_id = $2::uuid' : '';
    const countQuery = `SELECT COUNT(*) FROM community_posts cp WHERE cp.is_deleted = false ${isFilteredByGroup ? 'AND cp.group_id = $1::uuid' : ''}`;
    const countParams = isFilteredByGroup ? [groupId] : [];

    const countResult = await query(countQuery, countParams);
    const total = parseInt(countResult.rows[0].count, 10);

    const postsQuery = `
      SELECT cp.id, cp.content, cp.is_anonymous, cp.created_at, cp.group_id,
             cp.user_id as author_id,
             u.name as author_name,
             mp.profile_photo as author_photo,
             cg.name as group_name,
             (SELECT COUNT(*) FROM community_comments WHERE post_id = cp.id AND is_deleted = false) as comment_count,
             (SELECT COUNT(*) FROM community_post_likes WHERE post_id = cp.id) as like_count,
             COALESCE(CASE WHEN $1::uuid IS NOT NULL THEN EXISTS(
               SELECT 1 FROM community_post_likes WHERE post_id = cp.id AND user_id = $1::uuid
             ) ELSE false END, false) as liked_by_me
      FROM community_posts cp
      JOIN users u ON cp.user_id = u.id
      LEFT JOIN mother_profiles mp ON mp.user_id = u.id
      LEFT JOIN community_groups cg ON cp.group_id = cg.id
      WHERE cp.is_deleted = false ${groupCondition}
      ORDER BY cp.created_at DESC
      LIMIT $${isFilteredByGroup ? 3 : 2} OFFSET $${isFilteredByGroup ? 4 : 3}
    `;

    const queryParams = isFilteredByGroup
      ? [userId || null, groupId, Number(limit), offset]
      : [userId || null, Number(limit), offset];

    const result = await query(postsQuery, queryParams);

    const sanitized = result.rows.map(post => ({
      ...post,
      author_id: post.is_anonymous ? null : post.author_id,
      author_name: post.is_anonymous ? 'Anonymous' : (post.author_name || 'Mother'),
      author_photo: post.is_anonymous ? null : post.author_photo,
      group_name: post.group_name || 'Public Community',
      is_mine: Boolean(userId && String(post.author_id) === String(userId)),
    }));

    return sendPaginated(res, sanitized, page, limit, total);
  } catch (err) {
    next(err);
  }
};

// ── GET /api/v1/community/groups/:id/posts ───────────────────────────
exports.getGroupPosts = async (req, res, next) => {
  req.query.groupId = req.params.id;
  return exports.getAllPosts(req, res, next);
};

// ── POST /api/v1/community/posts (Public or Group Post) ───────────────
exports.createPost = async (req, res, next) => {
  try {
    if (!ensureRegisteredMother(req, res)) return;

    const content = (req.body.content || '').trim();
    const rawGroupId = req.body.groupId || req.body.group_id;
    const isAnonymous = req.body.isAnonymous ?? req.body.is_anonymous ?? false;

    if (!content) {
      return sendError(res, 400, 'Content is required.');
    }

    let targetGroupId = null;
    if (
      rawGroupId &&
      rawGroupId !== 'all' &&
      rawGroupId !== 'null' &&
      rawGroupId !== 'undefined' &&
      String(rawGroupId).trim().length > 0
    ) {
      targetGroupId = String(rawGroupId).trim();
    }

    const result = await query(
      `INSERT INTO community_posts (user_id, group_id, content, is_anonymous)
       VALUES ($1, $2, $3, $4) RETURNING *`,
      [req.user.id, targetGroupId, content, Boolean(isAnonymous)]
    );

    return sendSuccess(res, 201, 'Post created', result.rows[0]);
  } catch (err) {
    next(err);
  }
};

// ── PUT /api/v1/community/posts/:id (Edit Mother's Own Post) ─────────
exports.updateMyPost = async (req, res, next) => {
  try {
    if (!ensureRegisteredMother(req, res)) return;
    const userRole = (req.user?.role || '').toLowerCase().trim();
    const id = String(req.params.id || req.params.postId || '').trim();
    const { content } = req.body;

    if (!content || !content.trim()) {
      return sendError(res, 400, 'Content is required.');
    }
    if (!isUUID(id)) {
      return sendError(res, 400, 'Invalid post ID format.');
    }

    let result;
    if (userRole === 'admin') {
      result = await query(
        `UPDATE community_posts
         SET content = $1
         WHERE id = $2::uuid AND is_deleted = false
         RETURNING *`,
        [content.trim(), id]
      );
    } else {
      result = await query(
        `UPDATE community_posts
         SET content = $1
         WHERE id = $2::uuid AND user_id = $3::uuid AND is_deleted = false
         RETURNING *`,
        [content.trim(), id, req.user.id]
      );
    }

    if (result.rows.length === 0) {
      return sendError(res, 404, 'Post not found or unauthorized to edit.');
    }

    return sendSuccess(res, 200, 'Post updated', result.rows[0]);
  } catch (err) {
    next(err);
  }
};

// ── DELETE /api/v1/community/posts/:id (Delete Mother's Own Post) ─────
exports.deleteMyPost = async (req, res, next) => {
  try {
    if (!ensureRegisteredMother(req, res)) return;
    const userRole = (req.user?.role || '').toLowerCase().trim();
    const id = String(req.params.id || req.params.postId || '').trim();

    if (!isUUID(id)) {
      return sendError(res, 400, 'Invalid post ID format.');
    }

    let result;
    if (userRole === 'admin') {
      result = await query(
        `UPDATE community_posts
         SET is_deleted = true, deleted_by_admin_id = $1::uuid
         WHERE id = $2::uuid AND is_deleted = false
         RETURNING id`,
        [req.user.id, id]
      );
    } else {
      result = await query(
        `UPDATE community_posts
         SET is_deleted = true
         WHERE id = $1::uuid AND user_id = $2::uuid AND is_deleted = false
         RETURNING id`,
        [id, req.user.id]
      );
    }

    if (result.rows.length === 0) {
      return sendError(res, 404, 'Post not found or unauthorized to delete.');
    }

    return sendSuccess(res, 200, 'Post deleted');
  } catch (err) {
    next(err);
  }
};

// ── PUT /api/v1/community/posts/:id/flag (Report Post) ────────────────
exports.reportPost = async (req, res, next) => {
  try {
    const { id } = req.params;
    const { reason } = req.body;

    const result = await query(
      `UPDATE community_posts
       SET is_flagged = true,
           report_count = COALESCE(report_count, 0) + 1,
           report_reason = COALESCE($1, report_reason, 'Flagged by community member')
       WHERE id = $2 AND is_deleted = false
       RETURNING id, is_flagged, report_count`,
      [reason || 'Reported by user', id]
    );

    if (result.rows.length === 0) return sendError(res, 404, 'Post not found.');

    return sendSuccess(res, 200, 'Post flagged for review', result.rows[0]);
  } catch (err) {
    next(err);
  }
};

// ── POST /api/v1/community/posts/:id/comments ─────────────────────────
exports.createComment = async (req, res, next) => {
  try {
    if (!ensureRegisteredMother(req, res)) return;
    const { id } = req.params;
    const { content } = req.body;

    if (!content || !content.trim()) return sendError(res, 400, 'Content is required.');

    // Verify post exists
    const post = await query('SELECT id FROM community_posts WHERE id = $1 AND is_deleted = false', [id]);
    if (post.rows.length === 0) return sendError(res, 404, 'Post not found.');

    const result = await query(
      `INSERT INTO community_comments (post_id, user_id, content)
       VALUES ($1, $2, $3) RETURNING *`,
      [id, req.user.id, content.trim()]
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
    const { page = 1, limit = 50 } = req.query;
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
              u.id as author_id,
              u.name as author_name,
              mp.profile_photo as author_photo
       FROM community_comments c
       JOIN users u ON c.user_id = u.id
       LEFT JOIN mother_profiles mp ON mp.user_id = u.id
       WHERE c.post_id = $1 AND c.is_deleted = false
       ORDER BY c.created_at ASC
       LIMIT $2 OFFSET $3`,
      [id, Number(limit), offset]
    );

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
    if (!ensureRegisteredMother(req, res)) return;
    const { id } = req.params;
    const userId = req.user.id;

    const post = await query('SELECT id FROM community_posts WHERE id = $1 AND is_deleted = false', [id]);
    if (post.rows.length === 0) return sendError(res, 404, 'Post not found.');

    const existing = await query(
      'SELECT 1 FROM community_post_likes WHERE post_id = $1 AND user_id = $2',
      [id, userId]
    );

    let liked = false;
    if (existing.rows.length > 0) {
      await query('DELETE FROM community_post_likes WHERE post_id = $1 AND user_id = $2', [id, userId]);
      liked = false;
    } else {
      await query(
        `INSERT INTO community_post_likes (post_id, user_id)
         VALUES ($1, $2) ON CONFLICT (post_id, user_id) DO NOTHING`,
        [id, userId]
      );
      liked = true;
    }

    const likeCount = await query(
      'SELECT COUNT(*) FROM community_post_likes WHERE post_id = $1',
      [id]
    );

    return sendSuccess(res, 200, liked ? 'Post liked' : 'Post unliked', {
      liked,
      like_count: parseInt(likeCount.rows[0].count, 10),
    });
  } catch (err) {
    next(err);
  }
};

// ── GET /api/v1/admin/community/posts (Admin Moderation) ─────────────
exports.getAdminPosts = async (req, res, next) => {
  try {
    const { trimester, flaggedOnly, search, page = 1, limit = 50 } = req.query;
    const offset = (Number(page) - 1) * Number(limit);

    const conditions = ['cp.is_deleted = false'];
    const params = [];

    if (flaggedOnly === 'true' || flaggedOnly === true) {
      conditions.push('(cp.is_flagged = true OR COALESCE(cp.report_count, 0) > 0)');
    }

    if (trimester && trimester !== 'All') {
      const trimNum = trimester === 'T1' ? 1 : trimester === 'T2' ? 2 : trimester === 'T3' ? 3 : null;
      if (trimNum !== null) {
        params.push(trimNum);
        conditions.push(`cg.trimester_group = $${params.length}`);
      } else if (trimester === 'General') {
        conditions.push('(cp.group_id IS NULL OR cg.trimester_group IS NULL)');
      }
    }

    if (search && search.trim()) {
      params.push(`%${search.trim().toLowerCase()}%`);
      conditions.push(`(LOWER(cp.content) LIKE $${params.length} OR LOWER(u.name) LIKE $${params.length})`);
    }

    const whereClause = conditions.length ? `WHERE ${conditions.join(' AND ')}` : '';

    const countResult = await query(
      `SELECT COUNT(*) FROM community_posts cp
       JOIN users u ON cp.user_id = u.id
       LEFT JOIN community_groups cg ON cp.group_id = cg.id
       ${whereClause}`,
      params
    );
    const total = parseInt(countResult.rows[0].count, 10);

    const listParams = [...params, Number(limit), offset];
    const postsResult = await query(
      `SELECT cp.id, cp.content, cp.is_anonymous, cp.is_flagged,
              COALESCE(cp.report_count, 0) as report_count,
              cp.report_reason, cp.created_at,
              u.name as author_name,
              cg.name as group_name,
              cg.trimester_group
       FROM community_posts cp
       JOIN users u ON cp.user_id = u.id
       LEFT JOIN community_groups cg ON cp.group_id = cg.id
       ${whereClause}
       ORDER BY cp.is_flagged DESC, cp.created_at DESC
       LIMIT $${listParams.length - 1} OFFSET $${listParams.length}`,
      listParams
    );

    const rows = postsResult.rows.map(p => {
      let trimesterGroup = 'General';
      if (p.trimester_group === 1) trimesterGroup = 'T1';
      else if (p.trimester_group === 2) trimesterGroup = 'T2';
      else if (p.trimester_group === 3) trimesterGroup = 'T3';

      return {
        id: p.id,
        author: p.is_anonymous ? 'Anonymous' : (p.author_name || 'Member'),
        content: p.content,
        trimesterGroup,
        groupName: p.group_name || 'General Community',
        postedAt: p.created_at,
        isFlagged: p.is_flagged || p.report_count > 0,
        reportReason: p.report_reason || (p.is_flagged ? 'Flagged for moderation' : undefined),
        reportCount: parseInt(p.report_count, 10) || (p.is_flagged ? 1 : 0),
      };
    });

    return sendPaginated(res, rows, page, limit, total);
  } catch (err) {
    next(err);
  }
};

// ── PUT /api/v1/admin/community/posts/:id/dismiss-flag ────────────────
exports.dismissFlag = async (req, res, next) => {
  try {
    const { id } = req.params;
    const result = await query(
      `UPDATE community_posts
       SET is_flagged = false, report_count = 0, report_reason = NULL
       WHERE id = $1 RETURNING id`,
      [id]
    );

    if (result.rows.length === 0) return sendError(res, 404, 'Post not found.');

    return sendSuccess(res, 200, 'Flag dismissed');
  } catch (err) {
    next(err);
  }
};

// ── DELETE /api/v1/admin/community/posts/:id (Admin Moderation) ───────
exports.deletePost = async (req, res, next) => {
  try {
    const { id } = req.params;

    const result = await query(
      `UPDATE community_posts SET is_deleted = true, deleted_by_admin_id = $1 WHERE id = $2 RETURNING id`,
      [req.user.id, id]
    );

    if (result.rows.length === 0) return sendError(res, 404, 'Post not found.');

    const { logAdminAction } = require('../services/auditLogger');
    await logAdminAction(req.user.id, 'DELETE', 'community_posts', id, { reason: 'Moderated by admin' });

    return sendSuccess(res, 200, 'Post removed');
  } catch (err) {
    next(err);
  }
};

// ── Community Rules ───────────────────────────────────────────────────
const DEFAULT_RULES = `Community Guidelines for Mom Care

1. Be kind and respectful to all community members.
2. Do not share unverified medical advice or remedies.
3. Respect privacy — do not share personal health information publicly.
4. Spam, advertisements, or promotional content are strictly prohibited.
5. Posts flagged by multiple users will be reviewed by an admin.
6. Community support is not a substitute for professional medical care.
7. Always consult a licensed doctor for any health concerns.`;

exports.getCommunityRules = async (req, res, next) => {
  try {
    const result = await query("SELECT content, updated_at FROM community_rules WHERE id = 'default'");
    if (result.rows.length > 0) {
      return sendSuccess(res, 200, 'Community rules', {
        content: result.rows[0].content,
        updatedAt: result.rows[0].updated_at,
      });
    }
    return sendSuccess(res, 200, 'Community rules', {
      content: DEFAULT_RULES,
      updatedAt: new Date().toISOString(),
    });
  } catch (err) {
    next(err);
  }
};

exports.updateCommunityRules = async (req, res, next) => {
  try {
    const { content } = req.body;
    if (!content || !content.trim()) return sendError(res, 400, 'Rules content is required.');

    await query(
      `INSERT INTO community_rules (id, content, updated_at)
       VALUES ('default', $1, CURRENT_TIMESTAMP)
       ON CONFLICT (id) DO UPDATE SET content = $1, updated_at = CURRENT_TIMESTAMP`,
      [content.trim()]
    );

    return sendSuccess(res, 200, 'Community rules saved', { content: content.trim() });
  } catch (err) {
    next(err);
  }
};

// ── DIRECT MESSAGING (Mother-to-Mother Private Chat) ──────────────────

// GET /api/v1/community/direct-messages/conversations
exports.getConversations = async (req, res, next) => {
  try {
    if (!ensureRegisteredMother(req, res)) return;
    const userId = req.user.id;
    const result = await query(`
      WITH RankedMessages AS (
        SELECT
          dm.*,
          CASE WHEN dm.sender_id = $1 THEN dm.receiver_id ELSE dm.sender_id END as other_user_id,
          ROW_NUMBER() OVER(
            PARTITION BY CASE WHEN dm.sender_id = $1 THEN dm.receiver_id ELSE dm.sender_id END
            ORDER BY dm.created_at DESC
          ) as rn
        FROM direct_messages dm
        WHERE dm.sender_id = $1 OR dm.receiver_id = $1
      ),
      UnreadCounts AS (
        SELECT sender_id, COUNT(*) as unread_count
        FROM direct_messages
        WHERE receiver_id = $1 AND is_read = false
        GROUP BY sender_id
      )
      SELECT
        rm.other_user_id,
        u.name as other_user_name,
        mp.profile_photo as other_user_photo,
        mp.gestational_week,
        rm.message_text as last_message,
        rm.created_at as last_message_at,
        (rm.sender_id = $1) as is_last_sender,
        COALESCE(uc.unread_count, 0)::int as unread_count
      FROM RankedMessages rm
      JOIN users u ON u.id = rm.other_user_id
      LEFT JOIN mother_profiles mp ON mp.user_id = u.id
      LEFT JOIN UnreadCounts uc ON uc.sender_id = rm.other_user_id
      WHERE rm.rn = 1
      ORDER BY rm.created_at DESC
    `, [userId]);

    return sendSuccess(res, 200, 'Conversations retrieved', result.rows);
  } catch (err) {
    next(err);
  }
};

// GET /api/v1/community/direct-messages/:otherUserId
exports.getDirectMessages = async (req, res, next) => {
  try {
    if (!ensureRegisteredMother(req, res)) return;
    const userId = req.user.id;
    const { otherUserId } = req.params;
    if (!isUUID(otherUserId)) {
      return sendError(res, 400, 'Invalid other user ID format.');
    }
    const { page = 1, limit = 50 } = req.query;
    const offset = (Number(page) - 1) * Number(limit);

    // Mark messages from other user as read
    await query(
      `UPDATE direct_messages
       SET is_read = true
       WHERE sender_id = $1 AND receiver_id = $2 AND is_read = false`,
      [otherUserId, userId]
    );

    const countResult = await query(
      `SELECT COUNT(*) FROM direct_messages
       WHERE (sender_id = $1 AND receiver_id = $2)
          OR (sender_id = $2 AND receiver_id = $1)`,
      [userId, otherUserId]
    );
    const total = parseInt(countResult.rows[0].count, 10);

    const result = await query(
      `SELECT id, sender_id, receiver_id, message_text, is_read, COALESCE(is_edited, false) as is_edited, created_at
       FROM direct_messages
       WHERE (sender_id = $1 AND receiver_id = $2)
          OR (sender_id = $2 AND receiver_id = $1)
       ORDER BY created_at ASC
       LIMIT $3 OFFSET $4`,
      [userId, otherUserId, Number(limit), offset]
    );

    return sendPaginated(res, result.rows, page, limit, total);
  } catch (err) {
    next(err);
  }
};

// POST /api/v1/community/direct-messages/:otherUserId
exports.sendDirectMessage = async (req, res, next) => {
  try {
    if (!ensureRegisteredMother(req, res)) return;
    const userId = req.user.id;
    const otherUserId = String(req.params.otherUserId || req.body.otherUserId || req.body.receiverId || '').trim();
    const { messageText, message } = req.body;
    const text = (messageText || message || '').trim();

    if (!text) {
      return sendError(res, 400, 'Message text is required.');
    }

    if (!otherUserId || !isUUID(otherUserId)) {
      return sendError(res, 400, 'Valid recipient user ID is required.');
    }

    if (String(userId) === String(otherUserId)) {
      return sendError(res, 400, 'You cannot message yourself.');
    }

    const result = await query(
      `INSERT INTO direct_messages (sender_id, receiver_id, message_text)
       VALUES ($1, $2, $3)
       RETURNING *`,
      [userId, otherUserId, text]
    );

    const msg = result.rows[0];

    // Live socket emission to both parties
    try {
      const { getIO } = require('../config/socket');
      const io = getIO();
      if (io) {
        io.to(`user:${otherUserId}`).emit('direct:message', msg);
        io.to(`user:${userId}`).emit('direct:message', msg);
        io.to(`user:${otherUserId}`).emit('direct:conversation_update');
        io.to(`user:${userId}`).emit('direct:conversation_update');
      }
    } catch (_) {}

    return sendSuccess(res, 201, 'Message sent', msg);
  } catch (err) {
    next(err);
  }
};

// PUT /api/v1/community/direct-messages/messages/:messageId
exports.updateDirectMessage = async (req, res, next) => {
  try {
    if (!ensureRegisteredMother(req, res)) return;
    const userRole = (req.user?.role || '').toLowerCase().trim();
    const userId = req.user.id;
    const messageId = String(req.params.messageId || req.params.id || '').trim();
    const { messageText, message } = req.body;
    const text = (messageText || message || '').trim();

    if (!text) {
      return sendError(res, 400, 'Message text cannot be empty.');
    }

    if (!isUUID(messageId)) {
      return sendError(res, 400, 'Invalid message ID format.');
    }

    let result;
    if (userRole === 'admin') {
      result = await query(
        `UPDATE direct_messages
         SET message_text = $1, is_edited = true
         WHERE id = $2::uuid
         RETURNING *`,
        [text, messageId]
      );
    } else {
      result = await query(
        `UPDATE direct_messages
         SET message_text = $1, is_edited = true
         WHERE id = $2::uuid AND sender_id = $3::uuid
         RETURNING *`,
        [text, messageId, userId]
      );
    }

    if (result.rows.length === 0) {
      return sendError(res, 404, 'Message not found or you are not authorized to edit it.');
    }

    const updatedMsg = result.rows[0];

    try {
      const { getIO } = require('../config/socket');
      const io = getIO();
      if (io) {
        io.to(`user:${updatedMsg.receiver_id}`).emit('direct:message_updated', updatedMsg);
        io.to(`user:${updatedMsg.sender_id}`).emit('direct:message_updated', updatedMsg);
        io.to(`user:${updatedMsg.receiver_id}`).emit('direct:conversation_update');
        io.to(`user:${updatedMsg.sender_id}`).emit('direct:conversation_update');
      }
    } catch (_) {}

    return sendSuccess(res, 200, 'Message updated', updatedMsg);
  } catch (err) {
    next(err);
  }
};

// DELETE /api/v1/community/direct-messages/messages/:messageId
exports.deleteDirectMessage = async (req, res, next) => {
  try {
    if (!ensureRegisteredMother(req, res)) return;
    const userRole = (req.user?.role || '').toLowerCase().trim();
    const userId = req.user.id;
    const messageId = String(req.params.messageId || req.params.id || '').trim();

    if (!isUUID(messageId)) {
      return sendError(res, 400, 'Invalid message ID format.');
    }

    let result;
    if (userRole === 'admin') {
      result = await query(
        `DELETE FROM direct_messages
         WHERE id = $1::uuid
         RETURNING id, sender_id, receiver_id`,
        [messageId]
      );
    } else {
      result = await query(
        `DELETE FROM direct_messages
         WHERE id = $1::uuid AND (sender_id = $2::uuid OR receiver_id = $2::uuid)
         RETURNING id, sender_id, receiver_id`,
        [messageId, userId]
      );
    }

    if (result.rows.length === 0) {
      return sendError(res, 404, 'Message not found or you are not authorized to delete it.');
    }

    const deletedMsg = result.rows[0];

    try {
      const { getIO } = require('../config/socket');
      const io = getIO();
      if (io) {
        io.to(`user:${deletedMsg.receiver_id}`).emit('direct:message_deleted', deletedMsg);
        io.to(`user:${deletedMsg.sender_id}`).emit('direct:message_deleted', deletedMsg);
        io.to(`user:${deletedMsg.receiver_id}`).emit('direct:conversation_update');
        io.to(`user:${deletedMsg.sender_id}`).emit('direct:conversation_update');
      }
    } catch (_) {}

    return sendSuccess(res, 200, 'Message deleted', { id: deletedMsg.id });
  } catch (err) {
    next(err);
  }
};

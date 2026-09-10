const { query } = require('../config/db');
const { sendSuccess, sendError, sendPaginated } = require('../utils/apiResponse');
const notificationService = require('../services/notificationService');
const { getIO } = require('../config/socket');
const { logAdminAction } = require('../services/auditLogger');

// ── POST /api/v1/notifications/send ──────────────────────────────────
exports.sendNow = async (req, res, next) => {
  try {
    const {
      titleAm, titleOr, titleEn,
      bodyAm, bodyOr, bodyEn,
      targetGroup = 'all', targetUserId, scheduledAt
    } = req.body;

    // Create notification record
    const result = await query(
      `INSERT INTO notifications (title_am, title_or, title_en, body_am, body_or, body_en,
        target_group, target_user_id, sent_by, scheduled_at, sent_at)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11)
       RETURNING *`,
      [titleAm, titleOr, titleEn, bodyAm, bodyOr, bodyEn,
        targetGroup, targetUserId || null, 'admin',
        scheduledAt ? new Date(scheduledAt) : null, scheduledAt ? null : new Date()]
    );

    const notification = result.rows[0];

    // If not scheduled, send immediately
    if (!scheduledAt) {
      let fcmResult = { sentCount: 0 };

      if (targetGroup === 'specific_user' && targetUserId) {
        const userResult = await query('SELECT fcm_token FROM users WHERE id = $1', [targetUserId]);
        if (userResult.rows[0]?.fcm_token) {
          fcmResult = await notificationService.sendToUser(
            userResult.rows[0].fcm_token,
            titleAm || titleEn || 'Notification',
            bodyAm || bodyEn || ''
          );
          await query('UPDATE notifications SET sent_count = 1 WHERE id = $1', [notification.id]);
        }
      } else {
        fcmResult = await notificationService.sendToGroupByTarget(targetGroup, titleAm || titleEn, bodyAm || bodyEn);
        await query('UPDATE notifications SET sent_count = $1 WHERE id = $2', [fcmResult.sentCount || 0, notification.id]);
      }

      // Emit real-time event
      const io = getIO();
      if (io) {
        if (targetGroup === 'specific_user' && targetUserId) {
          io.to(`user:${targetUserId}`).emit('notification:new', notification);
        } else {
          io.emit('notification:new', notification);
        }
      }

      // Log audit
      await logAdminAction(req.user.id, 'SEND', 'notifications', notification.id, { targetGroup, title: titleAm || titleEn });

      return sendSuccess(res, 200, 'Notification sent', { notification, fcmResult });
    }

    // Log audit for scheduled notification
    await logAdminAction(req.user.id, 'SCHEDULE', 'notifications', notification.id, { targetGroup, scheduledAt });

    return sendSuccess(res, 201, 'Notification scheduled', notification);
  } catch (err) {
    next(err);
  }
};

// ── POST /api/v1/notifications/schedule ──────────────────────────────
exports.schedule = async (req, res, next) => {
  try {
    const {
      titleAm, titleOr, titleEn,
      bodyAm, bodyOr, bodyEn,
      targetGroup = 'all', targetUserId, scheduledAt
    } = req.body;

    if (!scheduledAt) return sendError(res, 400, 'scheduledAt is required for scheduling.');
    if (new Date(scheduledAt) <= new Date()) {
      return sendError(res, 400, 'scheduledAt must be a future date.');
    }

    const result = await query(
      `INSERT INTO notifications (title_am, title_or, title_en, body_am, body_or, body_en,
        target_group, target_user_id, sent_by, scheduled_at)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)
       RETURNING *`,
      [titleAm, titleOr, titleEn, bodyAm, bodyOr, bodyEn,
        targetGroup, targetUserId || null, 'admin', new Date(scheduledAt)]
    );

    // Log audit
    await logAdminAction(req.user.id, 'SCHEDULE', 'notifications', result.rows[0].id, { targetGroup, scheduledAt });

    return sendSuccess(res, 201, 'Notification scheduled', result.rows[0]);
  } catch (err) {
    next(err);
  }
};

// ── GET /api/v1/notifications/history ────────────────────────────────
exports.getHistory = async (req, res, next) => {
  try {
    const { page = 1, limit = 20, status } = req.query;
    let whereClause = 'WHERE 1=1';
    const params = [];
    let idx = 1;

    if (status) {
      whereClause += ` AND n.sent_at IS ${status === 'sent' ? 'NOT NULL' : 'NULL'}`;
    }

    const countResult = await query(`SELECT COUNT(*) FROM notifications n ${whereClause}`, params);
    const total = parseInt(countResult.rows[0].count, 10);

    const offset = (Number(page) - 1) * Number(limit);
    params.push(Number(limit), offset);

    const result = await query(
      `SELECT n.* FROM notifications n ${whereClause}
       ORDER BY n.created_at DESC
       LIMIT $${idx++} OFFSET $${idx}`,
      params
    );

    return sendPaginated(res, result.rows, page, limit, total);
  } catch (err) {
    next(err);
  }
};

// ── GET /api/v1/notifications/me ─────────────────────────────────────
// Sent notifications scoped to the logged-in user: broadcasts ('all'),
// their role group ('mothers'/'doctors'), or ones targeted directly at
// them (target_user_id). is_read reflects THIS user's read state.
exports.getMyNotifications = async (req, res, next) => {
  try {
    const { page = 1, limit = 20 } = req.query;
    const userId = req.user.id;
    const userRole = req.user.role;
    const lang = req.user.language || 'am';
    const offset = (Number(page) - 1) * Number(limit);

    const scope = `(n.target_group = 'all'
        OR (n.target_group = 'mothers' AND $2 = 'mother')
        OR (n.target_group = 'doctors' AND $2 = 'doctor')
        OR n.target_user_id = $1)
      AND n.sent_at IS NOT NULL`;

    const countResult = await query(
      `SELECT COUNT(*) FROM notifications n WHERE ${scope}`,
      [userId, userRole]
    );
    const total = parseInt(countResult.rows[0].count, 10);

    const result = await query(
      `SELECT n.id, n.title_am, n.title_or, n.title_en,
              n.body_am, n.body_or, n.body_en,
              n.target_group, n.target_user_id, n.sent_by,
              n.scheduled_at, n.sent_at, n.created_at,
              COALESCE(EXISTS(
                SELECT 1 FROM notification_reads nr
                WHERE nr.notification_id = n.id AND nr.user_id = $1
              ), false) AS is_read
       FROM notifications n
       WHERE ${scope}
       ORDER BY n.created_at DESC
       LIMIT $3 OFFSET $4`,
      [userId, userRole, Number(limit), offset]
    );

    const localized = result.rows.map(r => localize(r, lang));

    return sendPaginated(res, localized, page, limit, total);
  } catch (err) {
    next(err);
  }
};

// ── PUT /api/v1/notifications/:id/read ───────────────────────────────
// Marks a notification as read for the current user (idempotent upsert).
exports.markRead = async (req, res, next) => {
  try {
    const { id } = req.params;
    const userId = req.user.id;

    const notification = await query(
      'SELECT id FROM notifications WHERE id = $1 AND sent_at IS NOT NULL',
      [id]
    );
    if (notification.rows.length === 0) return sendError(res, 404, 'Notification not found.');

    await query(
      `INSERT INTO notification_reads (notification_id, user_id)
       VALUES ($1, $2)
       ON CONFLICT (notification_id, user_id) DO NOTHING`,
      [id, userId]
    );

    return sendSuccess(res, 200, 'Notification marked as read', { id, is_read: true });
  } catch (err) {
    next(err);
  }
};

// Mirrors the localization helper used by content controllers, but falls
// back through all available languages so a user always sees something.
function localize(item, lang) {
  const l = lang === 'or' ? 'or' : lang === 'en' ? 'en' : 'am';
  return {
    ...item,
    title: item[`title_${l}`] || item.title_am || item.title_or || item.title_en || '',
    body: item[`body_${l}`] || item.body_am || item.body_or || item.body_en || '',
  };
}

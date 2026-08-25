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

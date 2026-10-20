const { query } = require('../config/db');
const { normalizeLang } = require('../utils/normalizeLang');
const { sendSuccess, sendError, sendPaginated } = require('../utils/apiResponse');
const { dispatchNotification } = require('../services/notificationDispatcher');
const { logAdminAction } = require('../services/auditLogger');

// Which notifications belong in a user's inbox ($1 = user id, $2 = role)
const SCOPE = `(n.target_group = 'all'
    OR ($2 = 'mother' AND (
         n.target_group = 'mothers'
         OR n.target_group IN ('trimester', 'week', 'month')
         OR n.trimester IS NOT NULL
         OR n.week IS NOT NULL
         OR n.month IS NOT NULL
       ))
    OR (n.target_group = 'doctors' AND $2 = 'doctor')
    OR n.target_user_id = $1)
  AND n.sent_at IS NOT NULL`;

// ── POST /api/v1/notifications/send ──────────────────────────────────
exports.sendNow = async (req, res, next) => {
  try {
    const {
      titleAm, titleOr, titleEn, titleSo,
      title_am, title_or, title_en, title_so,
      title,
      bodyAm, bodyOr, bodyEn, bodySo,
      body_am, body_or, body_en, body_so,
      body,
      type = 'Reminder',
      trimester, week, month,
      targetGroup = 'all', target_group,
      targetUserId, target_user_id,
      audience,
      scheduledAt, scheduled_at, schedule,
      data = {},
    } = req.body;

    const tEn = titleEn || title_en || title || '';
    const tAm = titleAm || title_am || '';
    const tOr = titleOr || title_or || '';
    const tSo = titleSo || title_so || '';

    const bEn = bodyEn || body_en || body || '';
    const bAm = bodyAm || body_am || '';
    const bOr = bodyOr || body_or || '';
    const bSo = bodySo || body_so || '';

    const notifType = type || 'Reminder';
    const finalTargetGroup = targetGroup || target_group || (audience && audience.type) || 'all';
    const finalTargetUserId = targetUserId || target_user_id || (audience && audience.type === 'user' ? audience.value : null);
    const finalTrimester = trimester !== undefined && trimester !== '' && trimester !== null ? parseInt(trimester, 10) : (audience && audience.type === 'trimester' ? parseInt(audience.value, 10) : null);
    const finalWeek = week !== undefined && week !== '' && week !== null ? parseInt(week, 10) : null;
    const finalMonth = month !== undefined && month !== '' && month !== null ? parseInt(month, 10) : null;
    const finalSchedule = scheduledAt || scheduled_at || schedule || null;

    const isFutureSchedule = finalSchedule && new Date(finalSchedule) > new Date();

    const result = await query(
      `INSERT INTO notifications (
        title_am, title_or, title_en, title_so,
        body_am, body_or, body_en, body_so,
        type, trimester, week, month,
        target_group, target_user_id, sent_by,
        scheduled_at, sent_at, data
      ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17, $18::jsonb)
      RETURNING *`,
      [
        tAm, tOr, tEn, tSo,
        bAm, bOr, bEn, bSo,
        notifType, finalTrimester, finalWeek, finalMonth,
        finalTargetGroup, finalTargetUserId || null, 'admin',
        isFutureSchedule ? new Date(finalSchedule) : null,
        isFutureSchedule ? null : new Date(),
        JSON.stringify(data),
      ]
    );
    const notification = result.rows[0];

    if (!isFutureSchedule) {
      const delivery = await dispatchNotification(notification);
      await query('UPDATE notifications SET sent_count = $1 WHERE id = $2', [delivery.delivered, notification.id]);

      await logAdminAction(req.user.id, 'SEND', 'notifications', notification.id, {
        targetGroup: finalTargetGroup, title: tEn || tAm, type: notifType,
      });

      return sendSuccess(res, 200, 'Notification sent', { notification, delivery });
    }

    await logAdminAction(req.user.id, 'SCHEDULE', 'notifications', notification.id, {
      targetGroup: finalTargetGroup, scheduledAt: finalSchedule, type: notifType,
    });
    return sendSuccess(res, 201, 'Notification scheduled', notification);
  } catch (err) {
    next(err);
  }
};

// ── POST /api/v1/notifications/schedule ──────────────────────────────
exports.schedule = async (req, res, next) => {
  try {
    const {
      titleAm, titleOr, titleEn, titleSo,
      title_am, title_or, title_en, title_so,
      title,
      bodyAm, bodyOr, bodyEn, bodySo,
      body_am, body_or, body_en, body_so,
      body,
      type = 'Reminder',
      trimester, week, month,
      targetGroup = 'all', target_group,
      targetUserId, target_user_id,
      audience,
      scheduledAt, scheduled_at, schedule,
      data = {},
    } = req.body;

    const finalSchedule = scheduledAt || scheduled_at || schedule;
    if (!finalSchedule) return sendError(res, 400, 'scheduledAt is required for scheduling.');
    if (new Date(finalSchedule) <= new Date()) {
      return sendError(res, 400, 'scheduledAt must be a future date.');
    }

    const tEn = titleEn || title_en || title || '';
    const tAm = titleAm || title_am || '';
    const tOr = titleOr || title_or || '';
    const tSo = titleSo || title_so || '';

    const bEn = bodyEn || body_en || body || '';
    const bAm = bodyAm || body_am || '';
    const bOr = bodyOr || body_or || '';
    const bSo = bodySo || body_so || '';

    const notifType = type || 'Reminder';
    const finalTargetGroup = targetGroup || target_group || (audience && audience.type) || 'all';
    const finalTargetUserId = targetUserId || target_user_id || (audience && audience.type === 'user' ? audience.value : null);
    const finalTrimester = trimester !== undefined && trimester !== '' && trimester !== null ? parseInt(trimester, 10) : (audience && audience.type === 'trimester' ? parseInt(audience.value, 10) : null);
    const finalWeek = week !== undefined && week !== '' && week !== null ? parseInt(week, 10) : null;
    const finalMonth = month !== undefined && month !== '' && month !== null ? parseInt(month, 10) : null;

    const result = await query(
      `INSERT INTO notifications (
        title_am, title_or, title_en, title_so,
        body_am, body_or, body_en, body_so,
        type, trimester, week, month,
        target_group, target_user_id, sent_by,
        scheduled_at, data
      ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17::jsonb)
      RETURNING *`,
      [
        tAm, tOr, tEn, tSo,
        bAm, bOr, bEn, bSo,
        notifType, finalTrimester, finalWeek, finalMonth,
        finalTargetGroup, finalTargetUserId || null, 'admin',
        new Date(finalSchedule), JSON.stringify(data),
      ]
    );

    await logAdminAction(req.user.id, 'SCHEDULE', 'notifications', result.rows[0].id, {
      targetGroup: finalTargetGroup, scheduledAt: finalSchedule, type: notifType,
    });
    return sendSuccess(res, 201, 'Notification scheduled', result.rows[0]);
  } catch (err) {
    next(err);
  }
};

// ── GET /api/v1/notifications/history (admin) ────────────────────────
exports.getHistory = async (req, res, next) => {
  try {
    const { page = 1, limit = 20, status } = req.query;
    let whereClause = 'WHERE 1=1';
    if (status) {
      whereClause += ` AND n.sent_at IS ${status === 'sent' ? 'NOT NULL' : 'NULL'}`;
    }

    const countResult = await query(`SELECT COUNT(*) FROM notifications n ${whereClause}`);
    const total = parseInt(countResult.rows[0].count, 10);

    const offset = (Number(page) - 1) * Number(limit);
    const result = await query(
      `SELECT n.* FROM notifications n ${whereClause}
       ORDER BY n.created_at DESC
       LIMIT $1 OFFSET $2`,
      [Number(limit), offset]
    );

    return sendPaginated(res, result.rows, page, limit, total);
  } catch (err) {
    next(err);
  }
};

// ── GET /api/v1/notifications/me ─────────────────────────────────────
exports.getMyNotifications = async (req, res, next) => {
  try {
    const { page = 1, limit = 20 } = req.query;
    const userId = req.user.id;
    const userRole = req.user.role;
    const lang = req.user.language || 'am';
    const offset = (Number(page) - 1) * Number(limit);

    const countResult = await query(
      `SELECT COUNT(*) FROM notifications n WHERE ${SCOPE}`,
      [userId, userRole]
    );
    const total = parseInt(countResult.rows[0].count, 10);

    const result = await query(
      `SELECT n.id, n.title_am, n.title_or, n.title_en, n.title_so,
              n.body_am, n.body_or, n.body_en, n.body_so,
              n.type, n.trimester, n.week, n.month,
              n.target_group, n.target_user_id, n.sent_by,
              n.scheduled_at, n.sent_at, n.created_at, n.data,
              COALESCE(EXISTS(
                SELECT 1 FROM notification_reads nr
                WHERE nr.notification_id = n.id AND nr.user_id = $1
              ), false) AS is_read
       FROM notifications n
       WHERE ${SCOPE}
       ORDER BY n.created_at DESC
       LIMIT $3 OFFSET $4`,
      [userId, userRole, Number(limit), offset]
    );

    return sendPaginated(res, result.rows.map((r) => localize(r, lang)), page, limit, total);
  } catch (err) {
    next(err);
  }
};

// ── GET /api/v1/notifications/unread-count ───────────────────────────
exports.getUnreadCount = async (req, res, next) => {
  try {
    const result = await query(
      `SELECT COUNT(*) FROM notifications n
       WHERE ${SCOPE}
         AND NOT EXISTS (
           SELECT 1 FROM notification_reads nr
           WHERE nr.notification_id = n.id AND nr.user_id = $1
         )`,
      [req.user.id, req.user.role]
    );
    return sendSuccess(res, 200, 'Unread count', { count: parseInt(result.rows[0].count, 10) });
  } catch (err) {
    next(err);
  }
};

// ── PUT /api/v1/notifications/read-all ───────────────────────────────
exports.markAllRead = async (req, res, next) => {
  try {
    await query(
      `INSERT INTO notification_reads (notification_id, user_id)
       SELECT n.id, $1 FROM notifications n WHERE ${SCOPE}
       ON CONFLICT (notification_id, user_id) DO NOTHING`,
      [req.user.id, req.user.role]
    );
    return sendSuccess(res, 200, 'All notifications marked as read', { count: 0 });
  } catch (err) {
    next(err);
  }
};

// ── PUT /api/v1/notifications/:id/read ───────────────────────────────
exports.markRead = async (req, res, next) => {
  try {
    const { id } = req.params;
    const userId = req.user.id;
    const userRole = req.user.role;

    const existing = await query(
      'SELECT id, target_group, target_user_id FROM notifications WHERE id = $1 AND sent_at IS NOT NULL',
      [id]
    );
    if (existing.rows.length === 0) return sendError(res, 404, 'Notification not found.');

    const n = existing.rows[0];
    const inScope =
      n.target_group === 'all' ||
      (n.target_group === 'mothers' && userRole === 'mother') ||
      (n.target_group === 'doctors' && userRole === 'doctor') ||
      String(n.target_user_id) === String(userId);
    if (!inScope) {
      return sendError(res, 403, 'Forbidden. This notification does not belong to you.');
    }

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

// ── POST /api/v1/notifications/devices ───────────────────────────────
// The Flutter app calls this after login to save the phone's FCM token.
exports.registerDevice = async (req, res, next) => {
  try {
    const { token, platform } = req.body;
    if (!token) return sendError(res, 400, 'token is required.');

    await query(
      `INSERT INTO devices (user_id, fcm_token, platform)
       VALUES ($1, $2, $3)
       ON CONFLICT (fcm_token)
       DO UPDATE SET user_id = $1, platform = $3, updated_at = NOW()`,
      [req.user.id, token, platform || null]
    );
    return sendSuccess(res, 200, 'Device registered', { registered: true });
  } catch (err) {
    next(err);
  }
};

// ── DELETE /api/v1/notifications/devices ─────────────────────────────
// Called on logout so the next person on this phone doesn't get your pushes.
exports.unregisterDevice = async (req, res, next) => {
  try {
    const { token } = req.body;
    if (!token) return sendError(res, 400, 'token is required.');

    await query('DELETE FROM devices WHERE fcm_token = $1 AND user_id = $2', [token, req.user.id]);
    return sendSuccess(res, 200, 'Device removed', { removed: true });
  } catch (err) {
    next(err);
  }
};

function localize(item, lang) {
  const l = normalizeLang(lang);
  const oromoTitle = item.title_or || item.title_om;
  const oromoBody = item.body_or || item.body_om;
  const byLangTitle = l === 'om' || l === 'or' ? oromoTitle : item[`title_${l}`];
  const byLangBody = l === 'om' || l === 'or' ? oromoBody : item[`body_${l}`];
  return {
    ...item,
    title: byLangTitle || item.title_en || item.title_am || oromoTitle || item.title_so || '',
    body: byLangBody || item.body_en || item.body_am || oromoBody || item.body_so || '',
  };
}
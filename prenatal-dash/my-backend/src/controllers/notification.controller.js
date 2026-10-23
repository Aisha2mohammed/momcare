const { query } = require('../config/db');
const { normalizeLang } = require('../utils/normalizeLang');
const { sendSuccess, sendError, sendPaginated } = require('../utils/apiResponse');
const { dispatchNotification } = require('../services/notificationDispatcher');
const { logAdminAction } = require('../services/auditLogger');

// ── Helper: Stage calculations ──────────────────────────────────────────
function getStageFromWeek(week) {
  const w = Number(week);
  if (!w || isNaN(w)) return { trimester: null, month: null };
  const trimester = w <= 13 ? 1 : w <= 26 ? 2 : 3;
  let month = 1;
  if (w <= 4) month = 1;
  else if (w <= 8) month = 2;
  else if (w <= 13) month = 3;
  else if (w <= 17) month = 4;
  else if (w <= 21) month = 5;
  else if (w <= 26) month = 6;
  else if (w <= 30) month = 7;
  else if (w <= 35) month = 8;
  else month = 9;
  return { trimester, month };
}

function getTrimesterFromMonth(month) {
  const m = Number(month);
  if (!m || isNaN(m)) return null;
  return m <= 3 ? 1 : m <= 6 ? 2 : 3;
}

// Helper: Calculate mother's current pregnancy stage dynamically from LMP
async function getUserPregnancyStage(userId, role) {
  if (role !== 'mother') {
    return { week: null, trimester: null, month: null };
  }
  const res = await query(
    `SELECT
       COALESCE(
         CASE
           WHEN lmp_date IS NOT NULL THEN
             LEAST(42, GREATEST(1, ((CURRENT_DATE - lmp_date::date) / 7) + 1))
           ELSE gestational_week
         END,
         1
       ) AS cur_week
     FROM mother_profiles
     WHERE user_id = $1`,
    [userId]
  );
  if (res.rows.length === 0) {
    return { week: 1, trimester: 1, month: 1 };
  }
  const curWeek = Number(res.rows[0].cur_week) || 1;
  const { trimester, month } = getStageFromWeek(curWeek);
  return { week: curWeek, trimester, month };
}

// Which notifications belong in a user's inbox based on role, stage (week/month/trimester), or direct targeting
function buildInboxCondition(offset = 1) {
  const p1 = `$${offset}`;     // userId
  const p2 = `$${offset + 1}`; // role
  const p3 = `$${offset + 2}`; // current week
  const p4 = `$${offset + 3}`; // current month
  const p5 = `$${offset + 4}`; // current trimester

  return `
    (
      -- 1. Direct notification to specific user
      n.target_user_id = ${p1}
      OR
      -- 2. Doctor group broadcast
      (n.target_group = 'doctors' AND ${p2} = 'doctor')
      OR
      -- 3. General broadcast to all users (not filtered by week/month/trimester)
      (n.target_group = 'all' AND n.week IS NULL AND n.trimester IS NULL AND n.month IS NULL)
      OR
      -- 4. Mother-specific notifications
      (${p2} = 'mother' AND (
        -- General to all mothers (no stage targeting)
        (n.target_group = 'mothers' AND n.week IS NULL AND n.trimester IS NULL AND n.month IS NULL)
        OR
        -- Targeted specifically by week (matches mother's current week)
        (n.week IS NOT NULL AND n.week = ${p3})
        OR
        -- Targeted specifically by month (without specific week; matches mother's current month)
        (n.week IS NULL AND n.month IS NOT NULL AND n.month = ${p4})
        OR
        -- Targeted specifically by trimester (without specific week or month; matches current trimester)
        (n.week IS NULL AND n.month IS NULL AND n.trimester IS NOT NULL AND n.trimester = ${p5})
      ))
    )
    AND n.sent_at IS NOT NULL
  `;
}

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
    
    let finalWeek = (week !== undefined && week !== '' && week !== null) ? parseInt(week, 10) : null;
    let finalMonth = (month !== undefined && month !== '' && month !== null) ? parseInt(month, 10) : null;
    let finalTrimester = (trimester !== undefined && trimester !== '' && trimester !== null)
      ? parseInt(trimester, 10)
      : (audience && audience.type === 'trimester' ? parseInt(audience.value, 10) : null);

    // Auto-derive trimester and month if week is explicitly provided
    if (finalWeek) {
      const derived = getStageFromWeek(finalWeek);
      if (!finalTrimester) finalTrimester = derived.trimester;
      if (!finalMonth) finalMonth = derived.month;
    } else if (finalMonth && !finalTrimester) {
      finalTrimester = getTrimesterFromMonth(finalMonth);
    }

    const finalSchedule = scheduledAt || scheduled_at || schedule || null;
    const isFutureSchedule = finalSchedule && new Date(finalSchedule) > new Date();

    const mergedData = {
      screen: 'notifications',
      type: notifType,
      week: finalWeek,
      month: finalMonth,
      trimester: finalTrimester,
      ...data,
    };

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
        JSON.stringify(mergedData),
      ]
    );
    const notification = result.rows[0];

    if (!isFutureSchedule) {
      const delivery = await dispatchNotification(notification);
      await query('UPDATE notifications SET sent_count = $1 WHERE id = $2', [delivery.delivered, notification.id]);

      await logAdminAction(req.user.id, 'SEND', 'notifications', notification.id, {
        targetGroup: finalTargetGroup, title: tEn || tAm, type: notifType, week: finalWeek, trimester: finalTrimester, month: finalMonth,
      });

      return sendSuccess(res, 200, 'Notification sent', { notification, delivery });
    }

    await logAdminAction(req.user.id, 'SCHEDULE', 'notifications', notification.id, {
      targetGroup: finalTargetGroup, scheduledAt: finalSchedule, type: notifType, week: finalWeek, trimester: finalTrimester, month: finalMonth,
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
    
    let finalWeek = (week !== undefined && week !== '' && week !== null) ? parseInt(week, 10) : null;
    let finalMonth = (month !== undefined && month !== '' && month !== null) ? parseInt(month, 10) : null;
    let finalTrimester = (trimester !== undefined && trimester !== '' && trimester !== null)
      ? parseInt(trimester, 10)
      : (audience && audience.type === 'trimester' ? parseInt(audience.value, 10) : null);

    if (finalWeek) {
      const derived = getStageFromWeek(finalWeek);
      if (!finalTrimester) finalTrimester = derived.trimester;
      if (!finalMonth) finalMonth = derived.month;
    } else if (finalMonth && !finalTrimester) {
      finalTrimester = getTrimesterFromMonth(finalMonth);
    }

    const mergedData = {
      screen: 'notifications',
      type: notifType,
      week: finalWeek,
      month: finalMonth,
      trimester: finalTrimester,
      ...data,
    };

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
        new Date(finalSchedule), JSON.stringify(mergedData),
      ]
    );

    await logAdminAction(req.user.id, 'SCHEDULE', 'notifications', result.rows[0].id, {
      targetGroup: finalTargetGroup, scheduledAt: finalSchedule, type: notifType, week: finalWeek, trimester: finalTrimester, month: finalMonth,
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

    const stage = await getUserPregnancyStage(userId, userRole);
    const whereClause = buildInboxCondition(1);
    const params = [userId, userRole, stage.week, stage.month, stage.trimester];

    const countResult = await query(
      `SELECT COUNT(*) FROM notifications n WHERE ${whereClause}`,
      params
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
       WHERE ${whereClause}
       ORDER BY n.created_at DESC
       LIMIT $6 OFFSET $7`,
      [...params, Number(limit), offset]
    );

    return sendPaginated(res, result.rows.map((r) => localize(r, lang)), page, limit, total);
  } catch (err) {
    next(err);
  }
};

// ── GET /api/v1/notifications/unread-count ───────────────────────────
exports.getUnreadCount = async (req, res, next) => {
  try {
    const userId = req.user.id;
    const userRole = req.user.role;
    const stage = await getUserPregnancyStage(userId, userRole);
    const whereClause = buildInboxCondition(1);

    const result = await query(
      `SELECT COUNT(*) FROM notifications n
       WHERE ${whereClause}
         AND NOT EXISTS (
           SELECT 1 FROM notification_reads nr
           WHERE nr.notification_id = n.id AND nr.user_id = $1
         )`,
      [userId, userRole, stage.week, stage.month, stage.trimester]
    );
    return sendSuccess(res, 200, 'Unread count', { count: parseInt(result.rows[0].count, 10) });
  } catch (err) {
    next(err);
  }
};

// ── PUT /api/v1/notifications/read-all ───────────────────────────────
exports.markAllRead = async (req, res, next) => {
  try {
    const userId = req.user.id;
    const userRole = req.user.role;
    const stage = await getUserPregnancyStage(userId, userRole);
    const whereClause = buildInboxCondition(1);

    await query(
      `INSERT INTO notification_reads (notification_id, user_id)
       SELECT n.id, $1 FROM notifications n WHERE ${whereClause}
       ON CONFLICT (notification_id, user_id) DO NOTHING`,
      [userId, userRole, stage.week, stage.month, stage.trimester]
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
    const stage = await getUserPregnancyStage(userId, userRole);

    const existing = await query(
      'SELECT id, target_group, target_user_id, trimester, week, month FROM notifications WHERE id = $1 AND sent_at IS NOT NULL',
      [id]
    );
    if (existing.rows.length === 0) return sendError(res, 404, 'Notification not found.');

    const n = existing.rows[0];
    const isDirect = String(n.target_user_id) === String(userId);
    const isDoctor = n.target_group === 'doctors' && userRole === 'doctor';
    const isAllGeneral = n.target_group === 'all' && !n.week && !n.trimester && !n.month;
    const isMotherGeneral = userRole === 'mother' && n.target_group === 'mothers' && !n.week && !n.trimester && !n.month;
    const isMotherWeek = userRole === 'mother' && n.week !== null && Number(n.week) === stage.week;
    const isMotherMonth = userRole === 'mother' && n.week === null && n.month !== null && Number(n.month) === stage.month;
    const isMotherTrimester = userRole === 'mother' && n.week === null && n.month === null && n.trimester !== null && Number(n.trimester) === stage.trimester;

    const inScope = isDirect || isDoctor || isAllGeneral || isMotherGeneral || isMotherWeek || isMotherMonth || isMotherTrimester;
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
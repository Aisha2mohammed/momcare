const admin = require('firebase-admin');
const { query } = require('../config/db');
const { getIO } = require('../config/socket');
const { normalizeLang } = require('../utils/normalizeLang');

// Initialise Firebase once (skip if you already do it elsewhere)
if (!admin.apps.length) {
  admin.initializeApp({
    credential: admin.credential.cert(require('../../secrets/firebase-key.json')),
  });
}

function localize(n, lang) {
  const l = normalizeLang(lang);
  const oromoTitle = n.title_or || n.title_om;
  const oromoBody = n.body_or || n.body_om;
  const byLangTitle = l === 'om' || l === 'or' ? oromoTitle : n[`title_${l}`];
  const byLangBody = l === 'om' || l === 'or' ? oromoBody : n[`body_${l}`];
  return {
    title: byLangTitle || n.title_en || n.title_am || oromoTitle || n.title_so || '',
    body: byLangBody || n.body_en || n.body_am || oromoBody || n.body_so || '',
  };
}

// Who should receive this notification?
async function getRecipients(n) {
  let r;
  const tg = String(n.target_group || '').toLowerCase();
  if ((tg === 'specific_user' || tg === 'user') && n.target_user_id) {
    r = await query('SELECT id, language FROM users WHERE id = $1', [n.target_user_id]);
  } else if (tg === 'mothers') {
    r = await query(`SELECT id, language FROM users WHERE role = 'mother'`);
  } else if (tg === 'doctors') {
    r = await query(`SELECT id, language FROM users WHERE role = 'doctor'`);
  } else if (tg === 'trimester' || n.trimester) {
    const trim = Number(n.trimester || 1);
    const weekMin = trim === 1 ? 1 : trim === 2 ? 14 : 27;
    const weekMax = trim === 1 ? 13 : trim === 2 ? 26 : 42;
    r = await query(`
      SELECT u.id, u.language FROM users u
      LEFT JOIN mother_profiles mp ON mp.user_id = u.id
      WHERE u.role = 'mother' AND (
        (mp.gestational_week BETWEEN $1 AND $2) OR
        (mp.lmp_date IS NOT NULL AND ((CURRENT_DATE - mp.lmp_date::date)/7 + 1) BETWEEN $1 AND $2)
      )
    `, [weekMin, weekMax]);
  } else if (tg === 'week' || n.week) {
    const wk = Number(n.week);
    r = await query(`
      SELECT u.id, u.language FROM users u
      LEFT JOIN mother_profiles mp ON mp.user_id = u.id
      WHERE u.role = 'mother' AND (
        mp.gestational_week = $1 OR
        (mp.lmp_date IS NOT NULL AND ((CURRENT_DATE - mp.lmp_date::date)/7 + 1) = $1)
      )
    `, [wk]);
  } else if (tg === 'month' || n.month) {
    const mo = Number(n.month);
    const weekMin = (mo - 1) * 4 + 1;
    const weekMax = mo * 4 + (mo === 9 ? 6 : 0);
    r = await query(`
      SELECT u.id, u.language FROM users u
      LEFT JOIN mother_profiles mp ON mp.user_id = u.id
      WHERE u.role = 'mother' AND (
        (mp.gestational_week BETWEEN $1 AND $2) OR
        (mp.lmp_date IS NOT NULL AND ((CURRENT_DATE - mp.lmp_date::date)/7 + 1) BETWEEN $1 AND $2)
      )
    `, [weekMin, weekMax]);
  } else {
    r = await query('SELECT id, language FROM users');
  }
  return r.rows;
}

// All phone tokens for these users (new devices table + old users.fcm_token)
async function getTokens(userIds) {
  if (!userIds.length) return [];
  const r = await query(
    `SELECT user_id, fcm_token FROM devices WHERE user_id = ANY($1)
     UNION
     SELECT id AS user_id, fcm_token FROM users
      WHERE id = ANY($1) AND fcm_token IS NOT NULL AND fcm_token <> ''`,
    [userIds]
  );
  return r.rows;
}

async function removeToken(token) {
  await query('DELETE FROM devices WHERE fcm_token = $1', [token]);
  await query('UPDATE users SET fcm_token = NULL WHERE fcm_token = $1', [token]);
}

/**
 * Deliver one saved notification row (WebSocket for online users, FCM for offline).
 * Returns { recipients, viaSocket, pushSent, pushFailed, delivered }
 */
async function dispatchNotification(n) {
  const recipients = await getRecipients(n);
  const io = getIO();

  const online = [];
  const offline = [];
  recipients.forEach((u) => {
    const isOnline = io && io.sockets.adapter.rooms.has(`user:${u.id}`);
    (isOnline ? online : offline).push(u);
  });

  // 1. Online -> WebSocket (in-app, instant)
  online.forEach((u) => {
    const loc = localize(n, u.language);
    const payload = {
      id: String(n.id),
      title: loc.title,
      body: loc.body,
      type: n.type || 'reminder',
      week: n.week ? Number(n.week) : null,
      month: n.month ? Number(n.month) : null,
      trimester: n.trimester ? Number(n.trimester) : null,
      targetGroup: n.target_group,
      data: {
        screen: (n.data && n.data.screen) || 'notifications',
        notificationId: String(n.id),
        type: String(n.type || 'reminder'),
        week: n.week ? String(n.week) : '',
        month: n.month ? String(n.month) : '',
        trimester: n.trimester ? String(n.trimester) : '',
        ...n.data,
      },
    };
    io.to(`user:${u.id}`).emit('notification', payload);
    io.to(`user:${u.id}`).emit('notification:new', payload);
    io.to(`user:${u.id}`).emit('notification:count_update');
  });

  // Broadcast to role or all rooms for instant active client updates
  if (io) {
    const locEn = localize(n, 'en');
    const groupPayload = {
      id: String(n.id),
      title: locEn.title,
      body: locEn.body,
      type: n.type || 'reminder',
      week: n.week ? Number(n.week) : null,
      month: n.month ? Number(n.month) : null,
      trimester: n.trimester ? Number(n.trimester) : null,
      targetGroup: n.target_group,
      data: {
        screen: (n.data && n.data.screen) || 'notifications',
        notificationId: String(n.id),
        type: String(n.type || 'reminder'),
        week: n.week ? String(n.week) : '',
        month: n.month ? String(n.month) : '',
        trimester: n.trimester ? String(n.trimester) : '',
        ...n.data,
      },
    };

    if (n.target_group === 'all' || !n.target_group) {
      io.to('all').emit('notification', groupPayload);
      io.to('all').emit('notification:new', groupPayload);
      io.to('all').emit('notification:count_update');
    } else if (
      n.target_group === 'mothers' ||
      ['trimester', 'week', 'month'].includes(n.target_group) ||
      n.trimester ||
      n.week ||
      n.month
    ) {
      io.to('role:mother').emit('notification', groupPayload);
      io.to('role:mother').emit('notification:new', groupPayload);
      io.to('role:mother').emit('notification:count_update');
    }
  }

  // 2. Offline -> FCM push, grouped by language
  let pushSent = 0;
  let pushFailed = 0;

  if (offline.length) {
    const langOf = new Map(offline.map((u) => [String(u.id), normalizeLang(u.language)]));
    const rows = await getTokens(offline.map((u) => u.id));

    const groups = {}; // { am: Set(tokens), or: Set(...), en: Set(...) }
    rows.forEach((row) => {
      const lang = langOf.get(String(row.user_id)) || 'am';
      (groups[lang] ||= new Set()).add(row.fcm_token);
    });

    const notifType = String(n.type || 'reminder').toLowerCase();
    const channelId = notifType === 'alert' ? 'alerts' : notifType === 'tip' ? 'tips' : 'reminders';

    const data = {
      screen: (n.data && n.data.screen) || 'notifications',
      notificationId: String(n.id),
      type: String(n.type || 'reminder'),
      week: n.week ? String(n.week) : '',
      month: n.month ? String(n.month) : '',
      trimester: n.trimester ? String(n.trimester) : '',
      targetGroup: String(n.target_group || 'all'),
      ...Object.fromEntries(Object.entries(n.data || {}).map(([k, v]) => [k, String(v)])),
    };

    for (const [lang, set] of Object.entries(groups)) {
      const tokens = [...set];
      const { title, body } = localize(n, lang);

      for (let i = 0; i < tokens.length; i += 500) { // FCM max 500 per call
        const batch = tokens.slice(i, i + 500);
        const res = await admin.messaging().sendEachForMulticast({
          tokens: batch,
          notification: { title, body },
          data,
          android: {
            priority: 'high',
            notification: {
              channelId: channelId,
              sound: 'default',
              clickAction: 'FLUTTER_NOTIFICATION_CLICK',
            },
          },
          apns: { payload: { aps: { sound: 'default', badge: 1 } } },
        });

        pushSent += res.successCount;
        pushFailed += res.failureCount;

        for (let k = 0; k < res.responses.length; k++) {
          const code = res.responses[k].error && res.responses[k].error.code;
          if (
            code === 'messaging/registration-token-not-registered' ||
            code === 'messaging/invalid-registration-token'
          ) {
            await removeToken(batch[k]);
          }
        }
      }
    }
  }

  // 3. Tell the admin dashboard (if sockets put admins in the 'admins' room)
  if (io) io.to('admins').emit('notification:sent', { id: n.id, viaSocket: online.length, pushSent });

  return {
    recipients: recipients.length,
    viaSocket: online.length,
    pushSent,
    pushFailed,
    delivered: online.length + pushSent,
  };
}

module.exports = { dispatchNotification };
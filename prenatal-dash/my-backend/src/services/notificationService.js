const { admin } = require('../config/firebase');

const sendToUser = async (fcmToken, title, body, data = {}) => {
    if (!admin || !admin.messaging) {
        console.warn('Firebase not initialized. Skipping push notification.');
        return { success: false, reason: 'Firebase not initialized' };
    }
    if (!fcmToken) return { success: false, reason: 'No FCM token provided' };
    try {
        const message = { token: fcmToken, notification: { title, body }, data: { ...data }, android: { priority: 'high' }, apns: { payload: { aps: { sound: 'default' } } } };
        const response = await admin.messaging().send(message);
        return { success: true, messageId: response };
    } catch (err) {
        console.error('FCM sendToUser error:', err.message);
        return { success: false, reason: err.message };
    }
};

const sendToGroup = async (fcmTokens, title, body, data = {}) => {
    if (!admin || !admin.messaging) { console.warn('Firebase not initialized.'); return { success: false, reason: 'Firebase not initialized' }; }
    const validTokens = fcmTokens.filter(Boolean);
    if (validTokens.length === 0) return { success: false, reason: 'No valid FCM tokens' };
    try {
        const message = { notification: { title, body }, data: { ...data }, android: { priority: 'high' }, apns: { payload: { aps: { sound: 'default' } } }, tokens: validTokens };
        const response = await admin.messaging().sendMulticast(message);
        return { success: true, successCount: response.successCount, failureCount: response.failureCount, responses: response.responses };
    } catch (err) { console.error('FCM sendToGroup error:', err.message); return { success: false, reason: err.message }; }
};

const sendToAll = async (language, trimester, title, body, data = {}) => {
    const { query } = require('../config/db');
    try {
        let sql = 'SELECT fcm_token FROM users WHERE status = $1 AND fcm_token IS NOT NULL';
        const params = ['active'];
        let idx = 2;
        if (language !== 'all') { sql += ` AND language = $${idx++}`; params.push(language); }
        if (trimester && trimester !== 0) {
          const weekRange = getTrimesterWeekRange(trimester);
          if (weekRange) {
            sql += ` AND gestational_week >= $${idx} AND gestational_week <= $${idx + 1}`;
            params.push(weekRange.min, weekRange.max);
          }
        }
        const result = await query(sql, params);
        const tokens = result.rows.map(r => r.fcm_token).filter(Boolean);
        if (tokens.length === 0) return { success: false, reason: 'No matching users with FCM tokens', sentCount: 0 };
        const fcmResult = await sendToGroup(tokens, title, body, data);
        return { ...fcmResult, sentCount: tokens.length };
    } catch (err) { console.error('sendToAll error:', err.message); return { success: false, reason: err.message, sentCount: 0 }; }
};

const getTrimesterWeekRange = (trimester) => {
    const ranges = { 1: { min: 1, max: 13 }, 2: { min: 14, max: 26 }, 3: { min: 27, max: 42 } };
    return ranges[trimester] || null;
};

const sendToGroupByTarget = async (targetGroup, title, body, data = {}) => {
  const { query } = require('../config/db');
  try {
    let sql = 'SELECT fcm_token FROM users WHERE status = $1 AND fcm_token IS NOT NULL';
    const params = ['active'];
    if (targetGroup === 'mothers') { sql += " AND role = 'mother'"; }
    else if (targetGroup === 'doctors') { sql += " AND role = 'doctor'"; }
    else if (targetGroup === 'specific_user' && data.targetUserId) { sql += ' AND id = $2'; params.push(data.targetUserId); }
    const result = await query(sql, params);
    const tokens = result.rows.map(r => r.fcm_token).filter(Boolean);
    if (tokens.length === 0) return { success: false, reason: 'No matching users with FCM tokens', sentCount: 0 };
    const fcmResult = await sendToGroup(tokens, title, body, data);
    return { ...fcmResult, sentCount: tokens.length };
  } catch (err) { console.error('sendToGroupByTarget error:', err.message); return { success: false, reason: err.message, sentCount: 0 }; }
};

module.exports = { sendToUser, sendToGroup, sendToAll, sendToGroupByTarget };

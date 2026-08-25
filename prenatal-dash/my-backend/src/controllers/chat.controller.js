const { query } = require('../config/db');
const { sendSuccess, sendError, sendPaginated } = require('../utils/apiResponse');
const { getIO } = require('../config/socket');

// ── GET /api/v1/chat/:motherId/:doctorId/messages ─────────────────────
exports.getMessages = async (req, res, next) => {
  try {
    const { motherId, doctorId } = req.params;
    const { page = 1, limit = 50 } = req.query;
    const offset = (Number(page) - 1) * Number(limit);

    const countResult = await query(
      `SELECT COUNT(*) FROM chat_messages
       WHERE mother_id = $1 AND doctor_id = $2`,
      [motherId, doctorId]
    );
    const total = parseInt(countResult.rows[0].count, 10);

    const result = await query(
      `SELECT * FROM chat_messages
       WHERE mother_id = $1 AND doctor_id = $2
       ORDER BY created_at DESC
       LIMIT $3 OFFSET $4`,
      [motherId, doctorId, Number(limit), offset]
    );

    // Mark messages as read
    await query(
      `UPDATE chat_messages SET is_read = true
       WHERE mother_id = $1 AND doctor_id = $2 AND sender_role != $3`,
      [motherId, doctorId, req.user.role === 'mother' ? 'mother' : 'doctor']
    );

    return sendPaginated(res, result.rows.reverse(), page, limit, total);
  } catch (err) {
    next(err);
  }
};

// ── POST /api/v1/chat/:motherId/:doctorId/messages ────────────────────
exports.sendMessage = async (req, res, next) => {
  try {
    const { motherId, doctorId } = req.params;
    const { messageText, attachmentUrl } = req.body;

    const senderRole = req.user.role === 'mother' ? 'mother' : 'doctor';

    const result = await query(
      `INSERT INTO chat_messages (mother_id, doctor_id, sender_role, message_text, attachment_url)
       VALUES ($1, $2, $3, $4, $5) RETURNING *`,
      [motherId, doctorId, senderRole, messageText || null, attachmentUrl || null]
    );

    const message = result.rows[0];

    // Emit via Socket.io
    const io = getIO();
    if (io) {
      const roomName = `chat:${Math.min(motherId, doctorId)}:${Math.max(motherId, doctorId)}`;
      io.to(roomName).emit('chat:message', message);
    }

    // Send push notification
    const notificationService = require('../services/notificationService');
    const targetUserId = senderRole === 'mother' ? doctorId : motherId;
    const targetUser = await query('SELECT fcm_token FROM users WHERE id = $1', [targetUserId]);

    if (targetUser.rows[0]?.fcm_token) {
      await notificationService.sendToUser(
        targetUser.rows[0].fcm_token,
        senderRole === 'mother' ? 'New message from your patient' : 'New message from your doctor',
        messageText?.substring(0, 100) || 'Sent an attachment'
      );
    }

    return sendSuccess(res, 201, 'Message sent', message);
  } catch (err) {
    next(err);
  }
};

const { query } = require('../config/db');
const { sendSuccess, sendError, sendPaginated } = require('../utils/apiResponse');
const { getIO } = require('../config/socket');
const notificationService = require('../services/notificationService');

// ── POST /api/v1/appointments ──────────────────────────────────────────
exports.bookAppointment = async (req, res, next) => {
  try {
    const { id: motherId } = req.user;
    const { doctorId, slotDatetime } = req.body;

    if (!doctorId || !slotDatetime) {
      return sendError(res, 400, 'doctorId and slotDatetime are required.');
    }

    // Verify doctor exists and is approved
    const doctorResult = await query(
      `SELECT dp.id FROM doctor_profiles dp
       WHERE dp.user_id = $1 AND dp.approval_status = 'approved'`,
      [doctorId]
    );

    if (doctorResult.rows.length === 0) {
      return sendError(res, 404, 'Approved doctor not found.');
    }

    // Check for conflicting appointments
    const conflict = await query(
      `SELECT id FROM appointments
       WHERE doctor_id = $1 AND slot_datetime = $2
       AND status NOT IN ('cancelled', 'rejected')`,
      [doctorId, slotDatetime]
    );

    if (conflict.rows.length > 0) {
      return sendError(res, 409, 'This time slot is already booked.');
    }

    const result = await query(
      `INSERT INTO appointments (mother_id, doctor_id, slot_datetime, status)
       VALUES ($1, $2, $3, 'pending')
       RETURNING *`,
      [motherId, doctorId, slotDatetime]
    );

    const appointment = result.rows[0];

    // Emit socket event to doctor
    const io = getIO();
    if (io) {
      io.to(`doctor:${doctorId}`).emit('appointment:new', {
        appointment,
        message: 'New appointment booking request received.',
      });
    }

    // Send push notification to doctor
    const doctorUser = await query('SELECT fcm_token FROM users WHERE id = $1', [doctorId]);
    if (doctorUser.rows[0]?.fcm_token) {
      await notificationService.sendToUser(
        doctorUser.rows[0].fcm_token,
        'New Appointment Request',
        `A new appointment has been booked for ${new Date(slotDatetime).toLocaleString()}`
      );
    }

    return sendSuccess(res, 201, 'Appointment booked successfully', appointment);
  } catch (err) {
    next(err);
  }
};

// ── GET /api/v1/appointments/:id ──────────────────────────────────────
exports.getAppointment = async (req, res, next) => {
  try {
    const { id } = req.params;

    const result = await query(
      `SELECT a.*,
              mu.name as mother_name, mu.phone as mother_phone,
              du.name as doctor_name, du.phone as doctor_phone,
              dp.specialization
       FROM appointments a
       JOIN users mu ON a.mother_id = mu.id
       JOIN users du ON a.doctor_id = du.id
       LEFT JOIN doctor_profiles dp ON a.doctor_id = dp.user_id
       WHERE a.id = $1`,
      [id]
    );

    if (result.rows.length === 0) {
      return sendError(res, 404, 'Appointment not found.');
    }

    return sendSuccess(res, 200, 'Appointment retrieved', result.rows[0]);
  } catch (err) {
    next(err);
  }
};

// ── PUT /api/v1/appointments/:id/status ───────────────────────────────
exports.updateAppointmentStatus = async (req, res, next) => {
  try {
    const { id } = req.params;
    const { status } = req.body;

    const validStatuses = ['confirmed', 'rejected', 'completed', 'cancelled'];
    if (!validStatuses.includes(status)) {
      return sendError(res, 400, `Status must be one of: ${validStatuses.join(', ')}`);
    }

    const result = await query(
      `UPDATE appointments SET status = $1 WHERE id = $2 RETURNING *`,
      [status, id]
    );

    if (result.rows.length === 0) {
      return sendError(res, 404, 'Appointment not found.');
    }

    const appointment = result.rows[0];

    // Emit socket event
    const io = getIO();
    if (io) {
      io.to(`user:${appointment.mother_id}`).emit('appointment:status', {
        appointmentId: parseInt(id),
        status,
        message: `Appointment status updated to ${status}`,
      });
      io.to(`doctor:${appointment.doctor_id}`).emit('appointment:status', {
        appointmentId: parseInt(id),
        status,
        message: `Appointment status updated to ${status}`,
      });
    }

    // Send FCM notification
    const motherUser = await query('SELECT fcm_token FROM users WHERE id = $1', [appointment.mother_id]);
    if (motherUser.rows[0]?.fcm_token) {
      await notificationService.sendToUser(
        motherUser.rows[0].fcm_token,
        'Appointment Update',
        `Your appointment has been ${status}`
      );
    }

    return sendSuccess(res, 200, `Appointment ${status}`, appointment);
  } catch (err) {
    next(err);
  }
};

// ── PUT /api/v1/appointments/:id/respond (doctor) ─────────────────────
exports.respondToAppointment = async (req, res, next) => {
  try {
    const { id } = req.params;
    const { status, alternativeTimeSuggested } = req.body;

    if (!['confirmed', 'rejected'].includes(status)) {
      return sendError(res, 400, 'Status must be confirmed or rejected.');
    }

    const result = await query(
      `UPDATE appointments
       SET status = $1,
           alternative_time_suggested = $2,
           updated_at = NOW()
       WHERE id = $3 RETURNING *`,
      [status, alternativeTimeSuggested || null, id]
    );

    if (result.rows.length === 0) {
      return sendError(res, 404, 'Appointment not found.');
    }

    const appointment = result.rows[0];

    // Emit socket event to mother
    const io = getIO();
    if (io) {
      io.to(`user:${appointment.mother_id}`).emit('appointment:response', {
        appointmentId: parseInt(id),
        status,
        alternativeTimeSuggested,
      });
    }

    return sendSuccess(res, 200, `Appointment ${status}`, appointment);
  } catch (err) {
    next(err);
  }
};

// ── POST /api/v1/appointments/:id/clinical-record ─────────────────────
exports.addClinicalRecord = async (req, res, next) => {
  try {
    const { id } = req.params;
    const { notesText, prescriptionText, prescriptionFileUrl, riskIndicator } = req.body;

    // Verify appointment exists
    const appointment = await query('SELECT * FROM appointments WHERE id = $1', [id]);
    if (appointment.rows.length === 0) {
      return sendError(res, 404, 'Appointment not found.');
    }

    const result = await query(
      `INSERT INTO clinical_records (appointment_id, notes_text, prescription_text, prescription_file_url, risk_indicator)
       VALUES ($1, $2, $3, $4, $5) RETURNING *`,
      [id, notesText || null, prescriptionText || null, prescriptionFileUrl || null, riskIndicator || 'low']
    );

    return sendSuccess(res, 201, 'Clinical record created', result.rows[0]);
  } catch (err) {
    next(err);
  }
};

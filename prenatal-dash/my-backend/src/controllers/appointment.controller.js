const { query, getClient } = require('../config/db');
const { sendSuccess, sendError } = require('../utils/apiResponse');
const { getIO } = require('../config/socket');
const { callerIsAdmin } = require('../middlewares/ownership');
const notificationService = require('../services/notificationService');

const VALID_TARGET_STATUSES = ['confirmed', 'rejected', 'completed', 'cancelled'];
const AVAILABILITY_TIMEZONE = 'Africa/Addis_Ababa';
const canonicalUuid = (value) => String(value).toLowerCase();

// Status transitions allowed in the current workflow. Terminal states
// (rejected, completed, cancelled) are deliberately absent, so they cannot be
// moved back to an earlier state. "pending" is never a valid target.
const STATUS_TRANSITIONS = {
  mother: {
    pending: ['cancelled'],
    confirmed: ['cancelled'],
  },
  doctor: {
    pending: ['confirmed', 'rejected'],
    confirmed: ['completed', 'cancelled'],
  },
};

const isAppointmentDoctor = (req, appointment) =>
  req.userRole === 'doctor' && appointment.doctor_id === req.userId;

const isAppointmentMother = (req, appointment) =>
  req.userRole === 'mother' && appointment.mother_id === req.userId;

const canReadAppointment = (req, appointment) =>
  callerIsAdmin(req) || isAppointmentDoctor(req, appointment) || isAppointmentMother(req, appointment);

const UUID_RE = /^[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;
const isValidUuid = (value) => typeof value === 'string' && UUID_RE.test(value);

const findAppointment = async (id) => {
  // A malformed id would otherwise reach PostgreSQL and raise a 22P02 error.
  if (!isValidUuid(id)) return null;
  const result = await query('SELECT * FROM appointments WHERE id = $1', [id]);
  return result.rows[0] || null;
};

// getIO() throws when Socket.io has not been initialized (for example in
// integration tests or a worker process). Sockets are best-effort here.
const safeIO = () => {
  try {
    return getIO();
  } catch (_) {
    return null;
  }
};

// ── POST /api/v1/appointments ──────────────────────────────────────────
exports.bookAppointment = async (req, res, next) => {
  let client;
  try {
    const { id: motherId } = req.user;
    const { doctorId, slotDatetime } = req.body;
    const canonicalDoctorId = canonicalUuid(doctorId);

    if (!doctorId || !slotDatetime) {
      return sendError(res, 400, 'doctorId and slotDatetime are required.');
    }

    const slotDate = new Date(slotDatetime);
    if (Number.isNaN(slotDate.getTime())) {
      return sendError(res, 400, 'slotDatetime must be a valid date.');
    }
    if (slotDate.getTime() <= Date.now()) {
      return sendError(res, 400, 'Appointments cannot be booked in the past.');
    }
    const normalizedSlot = slotDate.toISOString();

    client = await getClient();
    await client.query('BEGIN');

    // Serialize concurrent bookings per doctor. This makes the conflict check
    // below safe under concurrency; a unique index also backstops exact
    // duplicate starts at the database level.
    await client.query('SELECT pg_advisory_xact_lock(hashtext($1::text))', [canonicalDoctorId]);

    // Verify doctor exists, is approved and is still active
    const doctorResult = await client.query(
      `SELECT dp.id FROM doctor_profiles dp
       JOIN users u ON u.id = dp.user_id
       WHERE dp.user_id = $1 AND dp.approval_status = 'approved' AND u.status = 'active'`,
      [canonicalDoctorId]
    );

    if (doctorResult.rows.length === 0) {
      await client.query('ROLLBACK');
      return sendError(res, 404, 'Approved doctor not found.');
    }

    const availability = await client.query(
      `WITH requested AS (
         SELECT ($1::timestamptz AT TIME ZONE $2) AS local_ts
       ),
       candidate AS (
         SELECT s.id,
                COALESCE(s.slot_duration_minutes, 30)::int AS duration_minutes,
                EXTRACT(EPOCH FROM (r.local_ts::time - s.start_time)) / 60.0 AS offset_minutes,
                EXTRACT(EPOCH FROM (s.end_time - s.start_time)) / 60.0 AS window_minutes
         FROM doctor_availability_slots s
         CROSS JOIN requested r
         WHERE s.doctor_id = $3
           AND s.is_active = true
           AND s.day_of_week = EXTRACT(DOW FROM r.local_ts)::int
           AND s.start_time <= r.local_ts::time
           AND s.end_time > r.local_ts::time
       ),
       matching AS (
         SELECT id, duration_minutes, offset_minutes
         FROM candidate
         WHERE duration_minutes BETWEEN 5 AND 240
           AND offset_minutes >= 0
           AND MOD(offset_minutes, duration_minutes::numeric) = 0
           AND offset_minutes + duration_minutes <= window_minutes
       )
       SELECT id, duration_minutes
       FROM matching
       ORDER BY offset_minutes, id`,
      [normalizedSlot, AVAILABILITY_TIMEZONE, canonicalDoctorId]
    );

    if (availability.rows.length === 0) {
      await client.query('ROLLBACK');
      return sendError(res, 409, "Selected time is not within the doctor's active availability.");
    }

    const matchingDurations = [
      ...new Set(availability.rows.map((row) => row.duration_minutes)),
    ];
    if (matchingDurations.length > 1) {
      await client.query('ROLLBACK');
      return sendError(res, 409, 'Doctor availability is ambiguous for this time.');
    }

    const durationMinutes = matchingDurations[0];
    const appointmentEnd = new Date(
      new Date(normalizedSlot).getTime() + durationMinutes * 60 * 1000
    ).toISOString();

    // Reject any active half-open [start, end) range that overlaps this booking.
    // Legacy rows without a stored duration use the historical 30-minute fallback
    // for conflict detection only.
    const conflict = await client.query(
      `SELECT id FROM appointments
       WHERE doctor_id = $1
         AND status IN ('pending', 'confirmed')
         AND slot_datetime < $3::timestamptz
         AND slot_datetime + make_interval(mins => COALESCE(duration_minutes, 30))
           > $2::timestamptz
       LIMIT 1`,
      [canonicalDoctorId, normalizedSlot, appointmentEnd]
    );

    if (conflict.rows.length > 0) {
      await client.query('ROLLBACK');
      return sendError(res, 409, 'This time slot is already booked.');
    }

    const result = await client.query(
      `INSERT INTO appointments (mother_id, doctor_id, slot_datetime, duration_minutes, status)
       VALUES ($1, $2, $3, $4, 'pending')
       RETURNING *,
         CASE
           WHEN duration_minutes IS NULL THEN NULL
           ELSE slot_datetime + make_interval(mins => duration_minutes)
         END AS end_datetime`,
      [motherId, canonicalDoctorId, normalizedSlot, durationMinutes]
    );

    await client.query('COMMIT');

    const appointment = result.rows[0];

    // Emit socket event to doctor
    const io = safeIO();
    if (io) {
      io.to(`doctor:${canonicalDoctorId}`).emit('appointment:new', {
        appointment,
        message: 'New appointment booking request received.',
      });
    }

    // Send push notification to doctor
    const doctorUser = await query('SELECT fcm_token FROM users WHERE id = $1', [canonicalDoctorId]);
    if (doctorUser.rows[0]?.fcm_token) {
      await notificationService.sendToUser(
        doctorUser.rows[0].fcm_token,
        'New Appointment Request',
        `A new appointment has been booked for ${new Date(slotDatetime).toLocaleString()}`
      );
    }

    return sendSuccess(res, 201, 'Appointment booked successfully', appointment);
  } catch (err) {
    if (client) {
      try {
        await client.query('ROLLBACK');
      } catch (_) {
        // Transaction may already be closed; ignore.
      }
    }
    if (err.code === '23505') {
      return sendError(res, 409, 'This time slot is already booked.');
    }
    return next(err);
  } finally {
    if (client) client.release();
  }
};

// ── GET /api/v1/appointments/:id ──────────────────────────────────────
exports.getAppointment = async (req, res, next) => {
  try {
    const { id } = req.params;

    if (!isValidUuid(id)) {
      return sendError(res, 404, 'Appointment not found.');
    }

    const result = await query(
      `SELECT a.*,
              CASE
                WHEN a.duration_minutes IS NULL THEN NULL
                ELSE a.slot_datetime + make_interval(mins => a.duration_minutes)
              END AS end_datetime,
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

    const appointment = result.rows[0];
    if (!canReadAppointment(req, appointment)) {
      return sendError(res, 403, 'Forbidden. You may only view your own appointments.');
    }

    return sendSuccess(res, 200, 'Appointment retrieved', appointment);
  } catch (err) {
    next(err);
  }
};

// ── PUT /api/v1/appointments/:id/status ───────────────────────────────
exports.updateAppointmentStatus = async (req, res, next) => {
  try {
    const { id } = req.params;
    const { status } = req.body;

    if (!VALID_TARGET_STATUSES.includes(status)) {
      return sendError(res, 400, `Status must be one of: ${VALID_TARGET_STATUSES.join(', ')}`);
    }

    const appointment = await findAppointment(id);
    if (!appointment) {
      return sendError(res, 404, 'Appointment not found.');
    }

    const role = req.userRole;
    if (role !== 'mother' && role !== 'doctor') {
      return sendError(res, 403, 'Forbidden. Only mothers and doctors may update appointment status.');
    }
    if (role === 'doctor' && !isAppointmentDoctor(req, appointment)) {
      return sendError(res, 403, 'Forbidden. You may only update your own appointments.');
    }
    if (role === 'mother' && !isAppointmentMother(req, appointment)) {
      return sendError(res, 403, 'Forbidden. You may only update your own appointments.');
    }

    const allowedTargets = STATUS_TRANSITIONS[role][appointment.status] || [];
    const roleTargets = Object.values(STATUS_TRANSITIONS[role]).flat();
    if (!roleTargets.includes(status)) {
      return sendError(res, 403, `Your role may not set appointment status to '${status}'.`);
    }
    if (!allowedTargets.includes(status)) {
      return sendError(
        res,
        409,
        `Cannot change appointment status from '${appointment.status}' to '${status}'.`
      );
    }

    // Conditional update keeps the transition atomic if another request
    // changes the status between the read above and this write.
    const ownerColumn = role === 'doctor' ? 'doctor_id' : 'mother_id';
    const result = await query(
      `UPDATE appointments
       SET status = $1, updated_at = NOW()
       WHERE id = $2 AND ${ownerColumn} = $3 AND status = $4
       RETURNING *,
         CASE
           WHEN duration_minutes IS NULL THEN NULL
           ELSE slot_datetime + make_interval(mins => duration_minutes)
         END AS end_datetime`,
      [status, id, req.userId, appointment.status]
    );

    if (result.rows.length === 0) {
      return sendError(res, 409, 'The appointment status changed. Please refresh and try again.');
    }

    const updated = result.rows[0];

    // Emit socket event
    const io = safeIO();
    if (io) {
      io.to(`user:${updated.mother_id}`).emit('appointment:status', {
        appointmentId: updated.id,
        status,
        message: `Appointment status updated to ${status}`,
      });
      io.to(`doctor:${updated.doctor_id}`).emit('appointment:status', {
        appointmentId: updated.id,
        status,
        message: `Appointment status updated to ${status}`,
      });
    }

    // Preserve existing notification behavior: notify the mother.
    const motherUser = await query('SELECT fcm_token FROM users WHERE id = $1', [updated.mother_id]);
    if (motherUser.rows[0]?.fcm_token) {
      await notificationService.sendToUser(
        motherUser.rows[0].fcm_token,
        'Appointment Update',
        `Your appointment has been ${status}`
      );
    }

    return sendSuccess(res, 200, `Appointment ${status}`, updated);
  } catch (err) {
    next(err);
  }
};

// ── PUT /api/v1/appointments/:id/respond (doctor) ─────────────────────
exports.respondToAppointment = async (req, res, next) => {
  try {
    const { id } = req.params;
    const { status } = req.body;
    const alternativeTimeSuggested =
      req.body.alternativeTimeSuggested ?? req.body.alternative_time ?? null;

    if (!['confirmed', 'rejected'].includes(status)) {
      return sendError(res, 400, 'Status must be confirmed or rejected.');
    }

    const appointment = await findAppointment(id);
    if (!appointment) {
      return sendError(res, 404, 'Appointment not found.');
    }
    if (!isAppointmentDoctor(req, appointment)) {
      return sendError(res, 403, 'Forbidden. You may only respond to your own appointments.');
    }
    if (appointment.status !== 'pending') {
      return sendError(res, 409, 'Only pending appointments can be confirmed or rejected.');
    }

    const result = await query(
      `UPDATE appointments
       SET status = $1,
           alternative_time_suggested = $2,
           updated_at = NOW()
       WHERE id = $3 AND doctor_id = $4 AND status = 'pending'
       RETURNING *,
         CASE
           WHEN duration_minutes IS NULL THEN NULL
           ELSE slot_datetime + make_interval(mins => duration_minutes)
         END AS end_datetime`,
      [status, alternativeTimeSuggested, id, req.userId]
    );

    if (result.rows.length === 0) {
      return sendError(res, 409, 'The appointment status changed. Please refresh and try again.');
    }

    const updated = result.rows[0];

    // Emit socket event to mother
    const io = safeIO();
    if (io) {
      io.to(`user:${updated.mother_id}`).emit('appointment:response', {
        appointmentId: updated.id,
        status,
        alternativeTimeSuggested,
      });
    }

    return sendSuccess(res, 200, `Appointment ${status}`, updated);
  } catch (err) {
    next(err);
  }
};

// ── POST /api/v1/appointments/:id/clinical-record ─────────────────────
exports.addClinicalRecord = async (req, res, next) => {
  try {
    const { id } = req.params;
    const body = req.body || {};
    const hasNotes = body.notesText !== undefined || body.notes_text !== undefined;
    const hasPrescription = body.prescriptionText !== undefined || body.prescription_text !== undefined;
    const hasPrescriptionFile =
      body.prescriptionFileUrl !== undefined || body.prescription_file_url !== undefined;
    const notesText = body.notesText ?? body.notes_text ?? null;
    const prescriptionText = body.prescriptionText ?? body.prescription_text ?? null;
    const prescriptionFileUrl = body.prescriptionFileUrl ?? body.prescription_file_url ?? null;
    const riskIndicator = body.riskIndicator || body.risk_indicator || null;
    const hasRisk = riskIndicator !== null;

    // Verify appointment exists and belongs to this doctor before writing.
    const appointment = await findAppointment(id);
    if (!appointment) {
      return sendError(res, 404, 'Appointment not found.');
    }
    if (!isAppointmentDoctor(req, appointment)) {
      return sendError(res, 403, 'Forbidden. You may only write records for your own appointments.');
    }

    // One clinical record per appointment: a repeat POST updates the latest
    // record instead of creating a duplicate. First write still returns 201.
    const existing = await query(
      'SELECT id FROM clinical_records WHERE appointment_id = $1 ORDER BY created_at DESC LIMIT 1',
      [id]
    );

    if (existing.rows.length > 0) {
      const sets = [];
      const values = [];
      const add = (column, value) => {
        values.push(value);
        sets.push(`${column} = $${values.length}`);
      };

      if (hasNotes) add('notes_text', notesText);
      if (hasPrescription) add('prescription_text', prescriptionText);
      if (hasPrescriptionFile) add('prescription_file_url', prescriptionFileUrl);
      if (hasRisk) add('risk_indicator', riskIndicator);

      if (sets.length === 0) {
        const current = await query('SELECT * FROM clinical_records WHERE id = $1', [existing.rows[0].id]);
        return sendSuccess(res, 200, 'Clinical record updated', current.rows[0]);
      }

      values.push(existing.rows[0].id);
      const updated = await query(
        `UPDATE clinical_records SET ${sets.join(', ')} WHERE id = $${values.length} RETURNING *`,
        values
      );
      return sendSuccess(res, 200, 'Clinical record updated', updated.rows[0]);
    }

    const result = await query(
      `INSERT INTO clinical_records (appointment_id, notes_text, prescription_text, prescription_file_url, risk_indicator)
       VALUES ($1, $2, $3, $4, $5) RETURNING *`,
      [id, notesText, prescriptionText, prescriptionFileUrl, riskIndicator || 'low']
    );

    return sendSuccess(res, 201, 'Clinical record created', result.rows[0]);
  } catch (err) {
    next(err);
  }
};

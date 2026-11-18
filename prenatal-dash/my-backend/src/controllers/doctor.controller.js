const { query, getClient } = require('../config/db');
const { sendSuccess, sendError, sendPaginated } = require('../utils/apiResponse');
const { getPregnancyProgress } = require('../services/pregnancyCalculator');
const { getIO } = require('../config/socket');
const { sendToUser } = require('../services/notificationService');
const notificationService = require('../services/notificationService');
const { callerIsAdmin } = require('../middlewares/ownership');

// ── GET /api/v1/doctors/health-providers ──────────────────────────────
exports.getHealthProviders = async (req, res, next) => {
  try {
    const result = await query(
      'SELECT * FROM health_providers WHERE status = $1 ORDER BY name',
      ['active']
    );
    return sendSuccess(res, 200, 'Health providers retrieved', result.rows);
  } catch (err) {
    next(err);
  }
};

// ── GET /api/v1/doctors/health-providers/:id/doctors ─────────────────
exports.getDoctorsByProvider = async (req, res, next) => {
  try {
    const { id } = req.params;
    const result = await query(
      `SELECT u.id, u.name, u.phone, dp.specialization, dp.location, dp.photo_url, dp.bio
       FROM doctor_profiles dp
       JOIN users u ON dp.user_id = u.id
       WHERE dp.health_provider_id = $1 AND dp.approval_status = 'approved' AND u.status = 'active'
       ORDER BY u.name`,
      [id]
    );
    return sendSuccess(res, 200, 'Doctors retrieved', result.rows);
  } catch (err) {
    next(err);
  }
};

// ── GET /api/v1/doctors/:id (public profile) ─────────────────────────
exports.getDoctorPublicProfile = async (req, res, next) => {
  try {
    const { id } = req.params;
    const result = await query(
      `SELECT u.id, u.name, u.phone, u.email,
              dp.specialization, dp.location, dp.photo_url, dp.bio,
              dp.working_hours_json, hp.name as hospital_name, hp.location as hospital_location
       FROM doctor_profiles dp
       JOIN users u ON dp.user_id = u.id
       LEFT JOIN health_providers hp ON dp.health_provider_id = hp.id
       WHERE dp.user_id = $1 AND dp.approval_status = 'approved' AND u.status = 'active'`,
      [id]
    );

    if (result.rows.length === 0) {
      return sendError(res, 404, 'Doctor not found or not yet approved.');
    }

    return sendSuccess(res, 200, 'Doctor profile retrieved', result.rows[0]);
  } catch (err) {
    next(err);
  }
};

// ── POST /doctors/register (after user registration) ──────────────────
exports.registerDoctor = async (req, res, next) => {
  try {
    const userId = req.userId;
    const {
      healthProviderId, licenseNumber, specialization,
      location, workingHoursJson, credentialDocsJson, photoUrl, bio,
    } = req.body;

    // Upsert: /auth/register pre-creates a pending placeholder row, so fill it
    // in with real data rather than rejecting with 409.
    const result = await query(
      `INSERT INTO doctor_profiles
       (user_id, health_provider_id, license_number, specialization, location,
        working_hours_json, credential_docs_json, photo_url, bio, approval_status)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, 'pending')
       ON CONFLICT (user_id) DO UPDATE SET
         health_provider_id = EXCLUDED.health_provider_id,
         license_number = EXCLUDED.license_number,
         specialization = EXCLUDED.specialization,
         location = EXCLUDED.location,
         working_hours_json = EXCLUDED.working_hours_json,
         credential_docs_json = EXCLUDED.credential_docs_json,
         photo_url = EXCLUDED.photo_url,
         bio = EXCLUDED.bio,
         approval_status = 'pending',
         updated_at = NOW()
       RETURNING *, (xmax = 0) AS inserted`,
      [userId, healthProviderId || null, licenseNumber, specialization, location,
        workingHoursJson ? JSON.stringify(workingHoursJson) : null,
        credentialDocsJson ? JSON.stringify(credentialDocsJson) : null,
        photoUrl || null, bio || null]
    );

    const inserted = result.rows[0].inserted === true;
    const row = { ...result.rows[0] };
    delete row.inserted;

    return sendSuccess(
      res,
      inserted ? 201 : 200,
      inserted
        ? 'Doctor profile created. Awaiting admin approval.'
        : 'Doctor profile updated. Awaiting admin approval.',
      row
    );
  } catch (err) {
    next(err);
  }
};

// ── GET /doctors/:id/profile ──────────────────────────────────────────
exports.getDoctorProfile = async (req, res, next) => {
  try {
    const { id } = req.params;
    const result = await query(
      `SELECT u.id, u.name, u.phone, u.email, u.language,
              dp.*, hp.name as hospital_name
       FROM doctor_profiles dp
       JOIN users u ON dp.user_id = u.id
       LEFT JOIN health_providers hp ON dp.health_provider_id = hp.id
       WHERE dp.user_id = $1`,
      [id]
    );

    if (result.rows.length === 0) {
      // Check if user exists
      const userRes = await query('SELECT id, name, phone, email, language FROM users WHERE id = $1 AND role = $2', [id, 'doctor']);
      if (userRes.rows.length === 0) {
        return sendError(res, 404, 'Doctor profile not found.');
      }
      // Create empty profile placeholder
      await query(
        `INSERT INTO doctor_profiles (user_id, approval_status, specialization)
         VALUES ($1, 'pending', 'Obstetrics & Gynecology')
         ON CONFLICT (user_id) DO NOTHING`,
        [id]
      );
      const newRes = await query(
        `SELECT u.id, u.name, u.phone, u.email, u.language,
                dp.*, hp.name as hospital_name
         FROM doctor_profiles dp
         JOIN users u ON dp.user_id = u.id
         LEFT JOIN health_providers hp ON dp.health_provider_id = hp.id
         WHERE dp.user_id = $1`,
        [id]
      );
      return sendSuccess(res, 200, 'Doctor profile retrieved', newRes.rows[0] || userRes.rows[0]);
    }

    return sendSuccess(res, 200, 'Doctor profile retrieved', result.rows[0]);
  } catch (err) {
    next(err);
  }
};

// ── PUT /doctors/:id/profile ─────────────────────────────────────────
exports.updateDoctorProfile = async (req, res, next) => {
  try {
    const { id } = req.params;

    // 1. Update users table if name, phone, email or language are provided
    const userUpdates = [];
    const userValues = [];
    let uIdx = 1;
    if (req.body.name !== undefined) { userUpdates.push(`name = $${uIdx++}`); userValues.push(req.body.name); }
    if (req.body.email !== undefined) { userUpdates.push(`email = $${uIdx++}`); userValues.push(req.body.email); }
    if (req.body.phone !== undefined) { userUpdates.push(`phone = $${uIdx++}`); userValues.push(req.body.phone); }
    if (req.body.language !== undefined) { userUpdates.push(`language = $${uIdx++}`); userValues.push(req.body.language); }

    if (userUpdates.length > 0) {
      userValues.push(id);
      await query(`UPDATE users SET ${userUpdates.join(', ')} WHERE id = $${uIdx}`, userValues);
    }

    // 2. Update doctor_profiles table
    const updates = [];
    const values = [];
    let index = 1;

    const fieldMap = {
      healthProviderId: 'health_provider_id',
      licenseNumber: 'license_number',
      specialization: 'specialization',
      location: 'location',
      photoUrl: 'photo_url',
      bio: 'bio',
      yearsExperience: 'years_experience',
      hospitalClinicName: 'hospital_clinic_name',
      licenseExpiryDate: 'license_expiry_date',
      nationalId: 'national_id',
      credentialDocumentUrl: 'credential_document_url',
    };

    for (const [key, dbField] of Object.entries(fieldMap)) {
      if (req.body[key] !== undefined) {
        updates.push(`${dbField} = $${index++}`);
        values.push(req.body[key]);
      }
    }

    if (req.body.workingHoursJson) {
      updates.push(`working_hours_json = $${index++}`);
      values.push(JSON.stringify(req.body.workingHoursJson));
    }

    if (updates.length > 0) {
      values.push(id);
      await query(
        `INSERT INTO doctor_profiles (user_id, specialization)
         VALUES ($${index}, 'Obstetrics & Gynecology')
         ON CONFLICT (user_id) DO NOTHING`,
        [id]
      );
      await query(
        `UPDATE doctor_profiles SET ${updates.join(', ')}, updated_at = NOW() WHERE user_id = $${index}`,
        values
      );
    }

    // Return the fresh joined profile
    const freshResult = await query(
      `SELECT u.id, u.name, u.phone, u.email, u.language,
              dp.*, hp.name as hospital_name
       FROM doctor_profiles dp
       JOIN users u ON dp.user_id = u.id
       LEFT JOIN health_providers hp ON dp.health_provider_id = hp.id
       WHERE dp.user_id = $1`,
      [id]
    );

    return sendSuccess(res, 200, 'Doctor profile updated', freshResult.rows[0]);
  } catch (err) {
    next(err);
  }
};

exports.updateProfilePhoto = async (req, res, next) => {
  try {
    if (!req.file) return sendError(res, 400, 'No photo uploaded. Send the file under field "photo".');
    const { id } = req.params;
    const url = `/uploads/${req.file.filename}`;
    const result = await query(
      'UPDATE doctor_profiles SET photo_url = $1 WHERE user_id = $2 RETURNING photo_url',
      [url, id]
    );
    if (result.rows.length === 0) return sendError(res, 404, 'Doctor profile not found.');
    return sendSuccess(res, 200, 'Profile photo updated', { photoUrl: url });
  } catch (err) { next(err); }
};

const TIME_OF_DAY_RE = /^([01]\d|2[0-3]):([0-5]\d)(?::00)?$/;
const AVAILABILITY_TIMEZONE = 'Africa/Addis_Ababa';

const normalizeTime = (value) => {
  const [hours, minutes] = String(value).split(':');
  return `${hours}:${minutes}:00`;
};

const timeToMinutes = (value) => {
  if (typeof value !== 'string' || !TIME_OF_DAY_RE.test(value)) return null;
  const [hours, minutes] = value.split(':').map(Number);
  return hours * 60 + minutes;
};

const canonicalUuid = (value) => String(value).toLowerCase();

const availabilityError = (status, message) => {
  const error = new Error(message);
  error.status = status;
  return error;
};

const withDoctorLock = async (doctorId, callback) => {
  const client = await getClient();
  try {
    await client.query('BEGIN');
    await client.query('SELECT pg_advisory_xact_lock(hashtext($1::text))', [canonicalUuid(doctorId)]);
    const result = await callback(client);
    await client.query('COMMIT');
    return result;
  } catch (err) {
    try {
      await client.query('ROLLBACK');
    } catch (_) {}
    throw err;
  } finally {
    client.release();
  }
};

const validateMergedWindow = (slot) => {
  const start = timeToMinutes(slot.startTime);
  const end = timeToMinutes(slot.endTime);
  if (start === null || end === null || start >= end) {
    return 'startTime must be earlier than endTime';
  }
  const duration = slot.slotDurationMinutes === null ? 30 : slot.slotDurationMinutes;
  if (!Number.isInteger(duration) || duration < 5 || duration > 240) {
    return 'slotDurationMinutes must be an integer between 5 and 240';
  }
  if (duration > end - start) {
    return 'slotDurationMinutes must fit within the availability window';
  }
  return null;
};

// ── GET /doctors/:id/availability-slots ──────────────────────────────
exports.getAvailabilitySlots = async (req, res, next) => {
  try {
    const { id } = req.params;
    const canonicalId = canonicalUuid(id);
    const doctorResult = await query(
      `SELECT u.id, u.status, dp.approval_status
       FROM users u
       LEFT JOIN doctor_profiles dp ON dp.user_id = u.id
       WHERE u.id = $1 AND u.role = 'doctor'`,
      [canonicalId]
    );

    if (doctorResult.rows.length === 0) {
      return sendError(res, 404, 'Doctor not found.');
    }

    const doctor = doctorResult.rows[0];
    const canManage = callerIsAdmin(req) || canonicalUuid(req.userId) === canonicalId;
    if (!canManage && (doctor.status !== 'active' || doctor.approval_status !== 'approved')) {
      return sendError(res, 404, 'Doctor not found.');
    }

    const includeInactive = req.query.includeInactive === true;
    if (includeInactive && !canManage) {
      return sendError(res, 403, 'Forbidden. Only the doctor or an administrator may view inactive slots.');
    }

    const result = includeInactive
      ? await query(
          `SELECT * FROM doctor_availability_slots
           WHERE doctor_id = $1
           ORDER BY day_of_week, start_time, id`,
          [canonicalId]
        )
      : await query(
          `SELECT * FROM doctor_availability_slots
           WHERE doctor_id = $1 AND is_active = true
           ORDER BY day_of_week, start_time, id`,
          [canonicalId]
        );

    return sendSuccess(res, 200, 'Availability slots retrieved', result.rows);
  } catch (err) {
    next(err);
  }
};

// ── GET /doctors/:id/available-slots ─────────────────────────────────
exports.getAvailableSlots = async (req, res, next) => {
  try {
    const { id } = req.params;
    const canonicalId = canonicalUuid(id);

    const doctorResult = await query(
      `SELECT u.id
       FROM users u
       JOIN doctor_profiles dp ON dp.user_id = u.id
       WHERE u.id = $1
         AND u.role = 'doctor'
         AND u.status = 'active'
         AND dp.approval_status = 'approved'`,
      [canonicalId]
    );
    if (doctorResult.rows.length === 0) {
      return sendError(res, 404, 'Doctor not found.');
    }

    const fromParam = req.query.from || null;
    const toParam = req.query.to || null;
    const rangeResult = await query(
      `WITH resolved AS (
         SELECT COALESCE($1::date, (CURRENT_TIMESTAMP AT TIME ZONE $3)::date) AS from_date,
                $2::date AS requested_to
       )
       SELECT to_char(from_date, 'YYYY-MM-DD') AS from_date,
              to_char(COALESCE(requested_to, from_date + 6), 'YYYY-MM-DD') AS to_date,
              (COALESCE(requested_to, from_date + 6) - from_date)::int AS span_days
       FROM resolved`,
      [fromParam, toParam, AVAILABILITY_TIMEZONE]
    );

    const {
      from_date: fromDate,
      to_date: toDate,
      span_days: spanDays,
    } = rangeResult.rows[0];

    if (spanDays < 0) {
      return sendError(res, 422, 'from must be on or before to.');
    }
    if (spanDays > 30) {
      return sendError(res, 422, 'Date range must not exceed 31 local calendar days.');
    }

    const result = await query(
      `WITH params AS (
         SELECT $1::date AS from_date,
                $2::date AS to_date,
                $3::text AS timezone,
                $4::uuid AS doctor_id
       ),
       local_days AS (
         SELECT (p.from_date + day_offset)::date AS local_date
         FROM params p
         CROSS JOIN LATERAL generate_series(
           0,
           (p.to_date - p.from_date)::int
         ) AS day_offset
       ),
       active_windows AS (
         SELECT s.day_of_week,
                s.start_time,
                s.end_time,
                COALESCE(s.slot_duration_minutes, 30)::int AS duration_minutes,
                EXTRACT(EPOCH FROM (s.end_time - s.start_time)) / 60.0 AS window_minutes
         FROM doctor_availability_slots s
         CROSS JOIN params p
         WHERE s.doctor_id = p.doctor_id
           AND s.is_active = true
           AND COALESCE(s.slot_duration_minutes, 30) BETWEEN 5 AND 240
       ),
       candidates AS (
         SELECT DISTINCT
                (ld.local_date + w.start_time + make_interval(mins => slots.offset_minutes))
                  AT TIME ZONE p.timezone AS slot_datetime
         FROM local_days ld
         CROSS JOIN params p
         JOIN active_windows w
           ON w.day_of_week = EXTRACT(DOW FROM ld.local_date)::int
         CROSS JOIN LATERAL generate_series(
           0,
           floor(w.window_minutes - w.duration_minutes)::int,
           w.duration_minutes
         ) AS slots(offset_minutes)
         WHERE w.window_minutes >= w.duration_minutes
       ),
       matching AS (
         SELECT c.slot_datetime,
                ARRAY_AGG(DISTINCT w.duration_minutes ORDER BY w.duration_minutes) AS durations
         FROM candidates c
         CROSS JOIN params p
         JOIN active_windows w
           ON w.day_of_week = EXTRACT(DOW FROM (c.slot_datetime AT TIME ZONE p.timezone))::int
          AND w.start_time <= (c.slot_datetime AT TIME ZONE p.timezone)::time
          AND w.end_time > (c.slot_datetime AT TIME ZONE p.timezone)::time
          AND (EXTRACT(EPOCH FROM ((c.slot_datetime AT TIME ZONE p.timezone)::time - w.start_time)) / 60.0) >= 0
          AND MOD(
                (EXTRACT(EPOCH FROM ((c.slot_datetime AT TIME ZONE p.timezone)::time - w.start_time)) / 60.0),
                w.duration_minutes::numeric
              ) = 0
          AND (EXTRACT(EPOCH FROM ((c.slot_datetime AT TIME ZONE p.timezone)::time - w.start_time)) / 60.0)
              + w.duration_minutes <= w.window_minutes
         GROUP BY c.slot_datetime
       ),
       available AS (
         SELECT m.slot_datetime,
                (m.durations)[1] AS duration_minutes
         FROM matching m
         WHERE cardinality(m.durations) = 1
           AND m.slot_datetime > NOW()
       )
       SELECT a.slot_datetime,
              to_char(a.slot_datetime AT TIME ZONE p.timezone, 'YYYY-MM-DD') AS local_date,
              to_char(a.slot_datetime AT TIME ZONE p.timezone, 'HH24:MI') AS local_start_time,
              to_char(
                a.slot_datetime AT TIME ZONE p.timezone + make_interval(mins => a.duration_minutes),
                'HH24:MI'
              ) AS local_end_time,
              a.duration_minutes,
              a.slot_datetime + make_interval(mins => a.duration_minutes) AS end_datetime
       FROM available a
       CROSS JOIN params p
       WHERE NOT EXISTS (
         SELECT 1
         FROM appointments ap
         WHERE ap.doctor_id = p.doctor_id
           AND ap.status IN ('pending', 'confirmed')
           AND ap.slot_datetime < a.slot_datetime + make_interval(mins => a.duration_minutes)
           AND ap.slot_datetime + make_interval(mins => COALESCE(ap.duration_minutes, 30)) > a.slot_datetime
       )
       ORDER BY a.slot_datetime`,
      [fromDate, toDate, AVAILABILITY_TIMEZONE, canonicalId]
    );

    return sendSuccess(res, 200, 'Available slots retrieved', result.rows);
  } catch (err) {
    next(err);
  }
};

// ── POST /doctors/:id/availability-slots ─────────────────────────────
exports.createAvailabilitySlot = async (req, res, next) => {
  try {
    const { id } = req.params;
    const canonicalId = canonicalUuid(id);
    const slot = {
      dayOfWeek: req.body.dayOfWeek,
      startTime: normalizeTime(req.body.startTime),
      endTime: normalizeTime(req.body.endTime),
      slotDurationMinutes: req.body.slotDurationMinutes ?? 30,
      isActive: req.body.isActive ?? true,
    };

    const created = await withDoctorLock(canonicalId, async (client) => {
      const duplicate = await client.query(
        `SELECT id FROM doctor_availability_slots
         WHERE doctor_id = $1 AND day_of_week = $2
           AND start_time = $3::time AND end_time = $4::time
         LIMIT 1`,
        [canonicalId, slot.dayOfWeek, slot.startTime, slot.endTime]
      );
      if (duplicate.rows.length > 0) {
        throw availabilityError(409, 'An availability slot with the same day and time already exists.');
      }

      if (slot.isActive) {
        const overlap = await client.query(
          `SELECT id FROM doctor_availability_slots
           WHERE doctor_id = $1 AND is_active = true AND day_of_week = $2
             AND start_time < $4::time AND end_time > $3::time
           LIMIT 1`,
          [canonicalId, slot.dayOfWeek, slot.startTime, slot.endTime]
        );
        if (overlap.rows.length > 0) {
          throw availabilityError(409, 'This availability window overlaps an active slot.');
        }
      }

      const result = await client.query(
        `INSERT INTO doctor_availability_slots
           (doctor_id, day_of_week, start_time, end_time, slot_duration_minutes, is_active)
         VALUES ($1, $2, $3, $4, $5, $6)
         RETURNING *`,
        [
          canonicalId,
          slot.dayOfWeek,
          slot.startTime,
          slot.endTime,
          slot.slotDurationMinutes,
          slot.isActive,
        ]
      );
      return result.rows[0];
    });

    return sendSuccess(res, 201, 'Availability slot created', created);
  } catch (err) {
    if (err.status) return sendError(res, err.status, err.message);
    next(err);
  }
};

// ── PUT /doctors/:id/availability-slots/:slotId ──────────────────────
exports.updateAvailabilitySlot = async (req, res, next) => {
  try {
    const { id, slotId } = req.params;
    const canonicalId = canonicalUuid(id);
    const canonicalSlotId = canonicalUuid(slotId);

    const updated = await withDoctorLock(canonicalId, async (client) => {
      const currentResult = await client.query(
        `SELECT * FROM doctor_availability_slots
         WHERE id = $1 AND doctor_id = $2
         FOR UPDATE`,
        [canonicalSlotId, canonicalId]
      );
      if (currentResult.rows.length === 0) {
        throw availabilityError(404, 'Availability slot not found.');
      }

      const current = currentResult.rows[0];
      const has = (field) => req.body[field] !== undefined;
      const changesWindow = ['dayOfWeek', 'startTime', 'endTime', 'slotDurationMinutes'].some(has);
      const next = {
        dayOfWeek: has('dayOfWeek') ? req.body.dayOfWeek : current.day_of_week,
        startTime: normalizeTime(has('startTime') ? req.body.startTime : current.start_time),
        endTime: normalizeTime(has('endTime') ? req.body.endTime : current.end_time),
        slotDurationMinutes: has('slotDurationMinutes')
          ? req.body.slotDurationMinutes
          : current.slot_duration_minutes,
        isActive: has('isActive') ? req.body.isActive : current.is_active,
      };

      if (changesWindow) {
        const windowError = validateMergedWindow(next);
        if (windowError) throw availabilityError(422, windowError);

        const duplicate = await client.query(
          `SELECT id FROM doctor_availability_slots
           WHERE doctor_id = $1 AND day_of_week = $2
             AND start_time = $3::time AND end_time = $4::time
             AND id <> $5
           LIMIT 1`,
           [canonicalId, next.dayOfWeek, next.startTime, next.endTime, canonicalSlotId]
        );
        if (duplicate.rows.length > 0) {
          throw availabilityError(409, 'An availability slot with the same day and time already exists.');
        }
      }

      if (next.isActive && (changesWindow || !current.is_active)) {
        const overlap = await client.query(
          `SELECT id FROM doctor_availability_slots
           WHERE doctor_id = $1 AND is_active = true AND day_of_week = $2
             AND start_time < $4::time AND end_time > $3::time
             AND id <> $5
           LIMIT 1`,
           [canonicalId, next.dayOfWeek, next.startTime, next.endTime, canonicalSlotId]
        );
        if (overlap.rows.length > 0) {
          throw availabilityError(409, 'This availability window overlaps an active slot.');
        }
      }

      const result = await client.query(
        `UPDATE doctor_availability_slots
         SET day_of_week = $1,
             start_time = $2,
             end_time = $3,
             slot_duration_minutes = $4,
             is_active = $5,
             updated_at = NOW()
         WHERE id = $6 AND doctor_id = $7
         RETURNING *`,
        [
          next.dayOfWeek,
          next.startTime,
          next.endTime,
           next.slotDurationMinutes,
           next.isActive,
           canonicalSlotId,
           canonicalId,
         ]
      );
      return result.rows[0];
    });

    return sendSuccess(res, 200, 'Availability slot updated', updated);
  } catch (err) {
    if (err.status) return sendError(res, err.status, err.message);
    next(err);
  }
};

// ── GET /doctors/:id/appointments ────────────────────────────────────
exports.getDoctorAppointments = async (req, res, next) => {
  try {
    const { id } = req.params;
    const { status, date, page = 1, limit = 20 } = req.query;
    const offset = (Number(page) - 1) * Number(limit);

    let whereClause = 'a.doctor_id = $1';
    let params = [id];
    let paramIndex = 2;

    if (status) {
      whereClause += ` AND a.status = $${paramIndex++}`;
      params.push(status);
    }
    if (date) {
      whereClause += ` AND DATE(a.slot_datetime) = $${paramIndex++}`;
      params.push(date);
    }

    const countResult = await query(
      `SELECT COUNT(*) FROM appointments a WHERE ${whereClause}`,
      params
    );
    const total = parseInt(countResult.rows[0].count, 10);

    params.push(Number(limit), offset);
    const result = await query(
      `SELECT a.*,
              CASE
                WHEN a.duration_minutes IS NULL THEN NULL
                ELSE a.slot_datetime + make_interval(mins => a.duration_minutes)
              END AS end_datetime,
              u.name as mother_name, u.phone as mother_phone
       FROM appointments a
       JOIN users u ON a.mother_id = u.id
       WHERE ${whereClause}
       ORDER BY a.slot_datetime DESC
       LIMIT $${paramIndex++} OFFSET $${paramIndex}`,
      params
    );

    return sendPaginated(res, result.rows, page, limit, total);
  } catch (err) {
    next(err);
  }
};

// ── GET /doctors/:id/patients ─────────────────────────────────────────
exports.getDoctorPatients = async (req, res, next) => {
  try {
    const { id } = req.params;
    const { sortByRisk } = req.query;

    const result = await query(
      `SELECT DISTINCT u.id, u.name, u.phone, u.language,
              mp.lmp_date, mp.due_date, mp.gestational_week,
              (SELECT symptom_severity FROM user_health_logs WHERE mother_id = u.id ORDER BY log_date DESC LIMIT 1) as latest_symptom_severity,
              (SELECT risk_indicator FROM clinical_records cr
               JOIN appointments a ON cr.appointment_id = a.id
               WHERE a.mother_id = u.id ORDER BY cr.created_at DESC LIMIT 1) as latest_risk_indicator
       FROM appointments a
       JOIN users u ON a.mother_id = u.id
       LEFT JOIN mother_profiles mp ON u.id = mp.user_id
       WHERE a.doctor_id = $1 AND a.status IN ('confirmed', 'completed')
       ORDER BY ${sortByRisk === 'true' ? 'latest_risk_indicator DESC NULLS LAST, latest_symptom_severity DESC NULLS LAST' : 'u.name'}`,
      [id]
    );

    // Add computed risk score
    const patientsWithRisk = result.rows.map((p) => {
      const riskScore = calculatePatientRisk(p);
      return { ...p, computedRiskScore: riskScore };
    });

    return sendSuccess(res, 200, 'Patients retrieved', patientsWithRisk);
  } catch (err) {
    next(err);
  }
};

// ── Helper: Calculate patient risk ─────────────────────────────────────
function calculatePatientRisk(patient) {
  let score = 0;
  const riskMap = { low: 1, medium: 2, high: 3 };
  const severityMap = { mild: 1, moderate: 2, severe: 3 };

  if (patient.latest_risk_indicator) {
    score += riskMap[patient.latest_risk_indicator] || 0;
  }
  if (patient.latest_symptom_severity) {
    score += severityMap[patient.latest_symptom_severity] || 0;
  }

  return score;
}

// ── POST /doctors/:id/notify ─────────────────────────────────────────
exports.notifyPatients = async (req, res, next) => {
  try {
    const { id } = req.params;
    const { targetUserId, title, body } = req.body;

    if (!title || !body) {
      return sendError(res, 400, 'Title and body are required.');
    }

    if (targetUserId) {
      // Send to specific patient
      const userResult = await query(
        'SELECT fcm_token FROM users WHERE id = $1',
        [targetUserId]
      );
      if (userResult.rows[0]?.fcm_token) {
        await notificationService.sendToUser(userResult.rows[0].fcm_token, title, body);
      }
      return sendSuccess(res, 200, 'Notification sent to patient.');
    } else {
      // Send to all patients of this doctor
      const patients = await query(
        `SELECT DISTINCT u.fcm_token FROM appointments a
         JOIN users u ON a.mother_id = u.id
         WHERE a.doctor_id = $1 AND a.status IN ('confirmed', 'completed')
         AND u.fcm_token IS NOT NULL`,
        [id]
      );

      const tokens = patients.rows.map((p) => p.fcm_token).filter(Boolean);
      if (tokens.length > 0) {
        await notificationService.sendToGroup(tokens, title, body);
      }

      return sendSuccess(res, 200, `Notification sent to ${tokens.length} patients.`);
    }
  } catch (err) {
    next(err);
  }
};

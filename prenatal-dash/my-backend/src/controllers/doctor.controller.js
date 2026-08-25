const { query } = require('../config/db');
const { sendSuccess, sendError, sendPaginated } = require('../utils/apiResponse');
const { getPregnancyProgress } = require('../services/pregnancyCalculator');
const { getIO } = require('../config/socket');
const { sendToUser } = require('../services/notificationService');
const notificationService = require('../services/notificationService');

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
    const { userId } = req.user;
    const {
      healthProviderId, licenseNumber, specialization,
      location, workingHoursJson, credentialDocsJson, photoUrl, bio,
    } = req.body;

    // Check if profile already exists
    const existing = await query(
      'SELECT id FROM doctor_profiles WHERE user_id = $1',
      [userId]
    );

    if (existing.rows.length > 0) {
      return sendError(res, 409, 'Doctor profile already exists. Use PUT to update.');
    }

    const result = await query(
      `INSERT INTO doctor_profiles
       (user_id, health_provider_id, license_number, specialization, location,
        working_hours_json, credential_docs_json, photo_url, bio, approval_status)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, 'pending')
       RETURNING *`,
      [userId, healthProviderId || null, licenseNumber, specialization, location,
        workingHoursJson ? JSON.stringify(workingHoursJson) : null,
        credentialDocsJson ? JSON.stringify(credentialDocsJson) : null,
        photoUrl || null, bio || null]
    );

    return sendSuccess(res, 201, 'Doctor profile created. Awaiting admin approval.', result.rows[0]);
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
      return sendError(res, 404, 'Doctor profile not found.');
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
    const updates = [];
    const values = [];
    let index = 1;

    const allowedFields = ['healthProviderId', 'licenseNumber', 'specialization', 'location', 'photoUrl', 'bio'];
    const fieldMap = {
      healthProviderId: 'health_provider_id',
      licenseNumber: 'license_number',
      specialization: 'specialization',
      location: 'location',
      photoUrl: 'photo_url',
      bio: 'bio',
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

    if (updates.length === 0) {
      return sendError(res, 400, 'No fields to update.');
    }

    values.push(id);
    const result = await query(
      `UPDATE doctor_profiles SET ${updates.join(', ')} WHERE user_id = $${index} RETURNING *`,
      values
    );

    if (result.rows.length === 0) {
      return sendError(res, 404, 'Doctor profile not found.');
    }

    return sendSuccess(res, 200, 'Doctor profile updated', result.rows[0]);
  } catch (err) {
    next(err);
  }
};

// ── GET /doctors/:id/availability-slots ──────────────────────────────
exports.getAvailabilitySlots = async (req, res, next) => {
  try {
    const { id } = req.params;
    const result = await query(
      `SELECT * FROM doctor_availability_slots
       WHERE doctor_id = $1 AND is_active = true
       ORDER BY day_of_week, start_time`,
      [id]
    );
    return sendSuccess(res, 200, 'Availability slots retrieved', result.rows);
  } catch (err) {
    next(err);
  }
};

// ── POST /doctors/:id/availability-slots ─────────────────────────────
exports.createAvailabilitySlot = async (req, res, next) => {
  try {
    const { id } = req.params;
    const { dayOfWeek, startTime, endTime, slotDurationMinutes } = req.body;

    if (dayOfWeek < 0 || dayOfWeek > 6) {
      return sendError(res, 400, 'dayOfWeek must be 0 (Sun) - 6 (Sat).');
    }

    const result = await query(
      `INSERT INTO doctor_availability_slots (doctor_id, day_of_week, start_time, end_time, slot_duration_minutes)
       VALUES ($1, $2, $3, $4, $5) RETURNING *`,
      [id, dayOfWeek, startTime, endTime, slotDurationMinutes || 30]
    );

    return sendSuccess(res, 201, 'Availability slot created', result.rows[0]);
  } catch (err) {
    next(err);
  }
};

// ── PUT /doctors/:id/availability-slots/:slotId ──────────────────────
exports.updateAvailabilitySlot = async (req, res, next) => {
  try {
    const { id, slotId } = req.params;
    const { dayOfWeek, startTime, endTime, slotDurationMinutes, isActive } = req.body;

    const result = await query(
      `UPDATE doctor_availability_slots
       SET day_of_week = COALESCE($1, day_of_week),
           start_time = COALESCE($2, start_time),
           end_time = COALESCE($3, end_time),
           slot_duration_minutes = COALESCE($4, slot_duration_minutes),
           is_active = COALESCE($5, is_active)
       WHERE id = $6 AND doctor_id = $7
       RETURNING *`,
      [dayOfWeek, startTime, endTime, slotDurationMinutes, isActive, slotId, id]
    );

    if (result.rows.length === 0) {
      return sendError(res, 404, 'Availability slot not found.');
    }

    return sendSuccess(res, 200, 'Availability slot updated', result.rows[0]);
  } catch (err) {
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
      `SELECT a.*, u.name as mother_name, u.phone as mother_phone
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

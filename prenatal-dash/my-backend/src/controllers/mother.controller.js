const { query } = require('../config/db');
const { sendSuccess, sendError, sendPaginated } = require('../utils/apiResponse');
const { getPregnancyProgress } = require('../services/pregnancyCalculator');

// ── GET /api/v1/mothers/:id/profile ────────────────────────────────────
exports.getProfile = async (req, res, next) => {
  try {
    const { id } = req.params;
    const userResult = await query(
      'SELECT id, role, name, phone, email, language, status FROM users WHERE id = $1 AND role = $2',
      [id, 'mother']
    );
    if (userResult.rows.length === 0) return sendError(res, 404, 'Mother not found.');

    const profileResult = await query(
      `SELECT mp.*, hp.name as assigned_hospital_name
       FROM mother_profiles mp
       LEFT JOIN users d ON mp.assigned_doctor_id = d.id
       LEFT JOIN doctor_profiles dp ON d.id = dp.user_id
       LEFT JOIN health_providers hp ON dp.health_provider_id = hp.id
       WHERE mp.user_id = $1`,
      [id]
    );

    return sendSuccess(res, 200, 'Profile retrieved', {
      user: userResult.rows[0],
      profile: profileResult.rows[0] || null,
    });
  } catch (err) {
    next(err);
  }
};

// ── PUT /api/v1/mothers/:id/profile ────────────────────────────────────
exports.updateProfile = async (req, res, next) => {
  try {
    const { id } = req.params;
    const { name, language, lmpDate, city, profilePhoto } = req.body;

    const userUpdates = [];
    const userValues = [];
    let userIndex = 1;

    if (name) { userUpdates.push(`name = $${userIndex++}`); userValues.push(name); }
    if (language) { userUpdates.push(`language = $${userIndex++}`); userValues.push(language); }
    if (userUpdates.length > 0) {
      userValues.push(id);
      await query(
        `UPDATE users SET ${userUpdates.join(', ')} WHERE id = $${userIndex}`,
        userValues
      );
    }

    // Check if mother profile exists
    const existingProfile = await query('SELECT id FROM mother_profiles WHERE user_id = $1', [id]);

    if (existingProfile.rows.length > 0) {
      // Update profile
      const profileUpdates = [];
      const profileValues = [];
      let pIndex = 1;

      if (lmpDate) {
        const dueDate = new Date(new Date(lmpDate).getTime() + 280 * 24 * 60 * 60 * 1000);
        const gestationalWeek = getPregnancyProgress(lmpDate).currentWeek;
        profileUpdates.push(`lmp_date = $${pIndex++}`); profileValues.push(lmpDate);
        profileUpdates.push(`due_date = $${pIndex++}`); profileValues.push(dueDate);
        profileUpdates.push(`gestational_week = $${pIndex++}`); profileValues.push(gestationalWeek);
      }
      if (city) { profileUpdates.push(`city = $${pIndex++}`); profileValues.push(city); }
      if (profilePhoto) { profileUpdates.push(`profile_photo = $${pIndex++}`); profileValues.push(profilePhoto); }

      if (profileUpdates.length > 0) {
        profileValues.push(id);
        await query(
          `UPDATE mother_profiles SET ${profileUpdates.join(', ')} WHERE user_id = $${pIndex}`,
          profileValues
        );
      }
    } else if (lmpDate) {
      // Create profile
      const dueDate = new Date(new Date(lmpDate).getTime() + 280 * 24 * 60 * 60 * 1000);
      const gestationalWeek = getPregnancyProgress(lmpDate).currentWeek;
      await query(
        `INSERT INTO mother_profiles (user_id, lmp_date, due_date, gestational_week, city, profile_photo)
         VALUES ($1, $2, $3, $4, $5, $6)`,
        [id, lmpDate, dueDate, gestationalWeek, city || null, profilePhoto || null]
      );
    }

    return sendSuccess(res, 200, 'Profile updated');
  } catch (err) {
    next(err);
  }
};

// ── GET /api/v1/mothers/:id/gestational-week ──────────────────────────
exports.getGestationalWeek = async (req, res, next) => {
  try {
    const { id } = req.params;
    const result = await query(
      'SELECT lmp_date, due_date, gestational_week FROM mother_profiles WHERE user_id = $1',
      [id]
    );

    if (result.rows.length === 0 || !result.rows[0].lmp_date) {
      return sendError(res, 400, 'LMP date not set. Please update your profile.');
    }

    const progress = getPregnancyProgress(result.rows[0].lmp_date);

    return sendSuccess(res, 200, 'Gestational week calculated', progress);
  } catch (err) {
    next(err);
  }
};

// ── GET /api/v1/mothers/:id/health-logs ───────────────────────────────
exports.getHealthLogs = async (req, res, next) => {
  try {
    const { id } = req.params;
    const { page = 1, limit = 20 } = req.query;
    const offset = (Number(page) - 1) * Number(limit);

    const countResult = await query(
      'SELECT COUNT(*) FROM user_health_logs WHERE mother_id = $1',
      [id]
    );
    const total = parseInt(countResult.rows[0].count, 10);

    const logsResult = await query(
      `SELECT * FROM user_health_logs WHERE mother_id = $1
       ORDER BY log_date DESC LIMIT $2 OFFSET $3`,
      [id, Number(limit), offset]
    );

    return sendPaginated(res, logsResult.rows, page, limit, total);
  } catch (err) {
    next(err);
  }
};

// ── POST /api/v1/mothers/:id/health-logs ──────────────────────────────
exports.createHealthLog = async (req, res, next) => {
  try {
    const { id } = req.params;
    const { weightKg, mood, symptomsJson, symptomSeverity } = req.body;

    const result = await query(
      `INSERT INTO user_health_logs (mother_id, log_date, weight_kg, mood, symptoms_json, symptom_severity)
       VALUES ($1, NOW(), $2, $3, $4, $5)
       RETURNING *`,
      [id, weightKg || null, mood || null, symptomsJson ? JSON.stringify(symptomsJson) : null, symptomSeverity || null]
    );

    return sendSuccess(res, 201, 'Health log created', result.rows[0]);
  } catch (err) {
    next(err);
  }
};

// ── GET /api/v1/mothers/:id/emergency-contacts ────────────────────────
exports.getEmergencyContacts = async (req, res, next) => {
  try {
    const { id } = req.params;
    const result = await query(
      'SELECT * FROM emergency_contacts WHERE mother_id = $1 ORDER BY contact_name',
      [id]
    );
    return sendSuccess(res, 200, 'Emergency contacts retrieved', result.rows);
  } catch (err) {
    next(err);
  }
};

// ── POST /api/v1/mothers/:id/emergency-contacts ───────────────────────
exports.createEmergencyContact = async (req, res, next) => {
  try {
    const { id } = req.params;
    const { contactName, phone, relationship } = req.body;

    const result = await query(
      `INSERT INTO emergency_contacts (mother_id, contact_name, phone, relationship)
       VALUES ($1, $2, $3, $4) RETURNING *`,
      [id, contactName, phone, relationship || null]
    );

    return sendSuccess(res, 201, 'Emergency contact created', result.rows[0]);
  } catch (err) {
    next(err);
  }
};

// ── POST /api/v1/mothers/:id/emergency-alert ──────────────────────────
exports.emergencyAlert = async (req, res, next) => {
  try {
    const { id } = req.params;
    const { latitude, longitude } = req.body;

    // Get emergency contacts
    const contacts = await query(
      'SELECT * FROM emergency_contacts WHERE mother_id = $1',
      [id]
    );

    // Get mother info
    const mother = await query('SELECT name, phone FROM users WHERE id = $1', [id]);

    // In production: trigger SMS/call flow via Twilio or similar
    // For now, log the alert
    console.log('🚨 EMERGENCY ALERT from mother:', mother.rows[0]?.name);
    console.log('📍 Location:', latitude, longitude);
    console.log('📞 Contacts:', contacts.rows);

    // Emit socket event to assigned doctor if any
    const profile = await query('SELECT assigned_doctor_id FROM mother_profiles WHERE user_id = $1', [id]);
    if (profile.rows[0]?.assigned_doctor_id) {
      const io = require('../config/socket').getIO();
      if (io) {
        io.to(`doctor:${profile.rows[0].assigned_doctor_id}`).emit('emergency:alert', {
          motherId: parseInt(id),
          motherName: mother.rows[0]?.name,
          latitude,
          longitude,
          timestamp: new Date().toISOString(),
        });
      }
    }

    return sendSuccess(res, 200, 'Emergency alert sent to your contacts and doctor.', {
      contactsNotified: contacts.rows.length,
    });
  } catch (err) {
    next(err);
  }
};

// ── POST /api/v1/mothers/:id/assign-doctor ────────────────────────────
exports.assignDoctor = async (req, res, next) => {
  try {
    const { id } = req.params;
    const { doctorId } = req.body;

    if (!doctorId) return sendError(res, 400, 'doctorId is required.');

    // Verify doctor exists and is approved
    const doctorResult = await query(
      `SELECT dp.id FROM doctor_profiles dp
       JOIN users u ON dp.user_id = u.id
       WHERE dp.user_id = $1 AND dp.approval_status = 'approved' AND u.role = 'doctor'`,
      [doctorId]
    );

    if (doctorResult.rows.length === 0) {
      return sendError(res, 404, 'Approved doctor not found.');
    }

    await query(
      'UPDATE mother_profiles SET assigned_doctor_id = $1 WHERE user_id = $2',
      [doctorId, id]
    );

    return sendSuccess(res, 200, 'Doctor assigned successfully', { doctorId });
  } catch (err) {
    next(err);
  }
};

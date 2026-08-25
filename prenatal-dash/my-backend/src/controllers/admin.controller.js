const { query } = require('../config/db');
const { sendSuccess, sendError, sendPaginated } = require('../utils/apiResponse');
const { logAdminAction } = require('../services/auditLogger');
const { sendEmail } = require('../config/mailer');

exports.getDashboard = async (req, res, next) => {
  try {
    const [totalUsers, activeMothers, activeDoctors, pendingDoctors,
      totalAppointments, confirmedAppointments, completedAppointments,
      recentUsers, recentAppointments] = await Promise.all([
      query('SELECT COUNT(*) FROM users'),
      query("SELECT COUNT(*) FROM users WHERE role = 'mother' AND status = 'active'"),
      query("SELECT COUNT(*) FROM doctor_profiles WHERE approval_status = 'approved'"),
      query("SELECT COUNT(*) FROM doctor_profiles WHERE approval_status = 'pending'"),
      query('SELECT COUNT(*) FROM appointments'),
      query("SELECT COUNT(*) FROM appointments WHERE status = 'confirmed'"),
      query("SELECT COUNT(*) FROM appointments WHERE status = 'completed'"),
      query("SELECT id, name, role, created_at FROM users ORDER BY created_at DESC LIMIT 10"),
      query("SELECT a.*, u.name as mother_name FROM appointments a JOIN users u ON a.mother_id = u.id ORDER BY a.created_at DESC LIMIT 10"),
    ]);

    const langDist = await query("SELECT language, COUNT(*) as count FROM users WHERE language IS NOT NULL GROUP BY language");
    const trimesterDist = await query(`SELECT CASE WHEN gestational_week <= 13 THEN 1 WHEN gestational_week <= 26 THEN 2 ELSE 3 END as trimester, COUNT(*) as count FROM mother_profiles WHERE gestational_week IS NOT NULL GROUP BY trimester ORDER BY trimester`);
    const monthlyRegistrations = await query(`SELECT TO_CHAR(created_at, 'YYYY-MM') as month, COUNT(*) as count FROM users WHERE created_at >= NOW() - INTERVAL '6 months' GROUP BY month ORDER BY month`);
    const approvalStats = await query(`SELECT approval_status, COUNT(*) as count FROM doctor_profiles GROUP BY approval_status`);

    return sendSuccess(res, 200, 'Dashboard statistics', {
      users: { total: parseInt(totalUsers.rows[0].count), activeMothers: parseInt(activeMothers.rows[0].count), activeDoctors: parseInt(activeDoctors.rows[0].count), pendingDoctors: parseInt(pendingDoctors.rows[0].count) },
      appointments: { total: parseInt(totalAppointments.rows[0].count), confirmed: parseInt(confirmedAppointments.rows[0].count), completed: parseInt(completedAppointments.rows[0].count) },
      distributions: { language: langDist.rows, trimester: trimesterDist.rows },
      monthlyRegistrations: monthlyRegistrations.rows, approvalStats: approvalStats.rows,
      recentUsers: recentUsers.rows, recentAppointments: recentAppointments.rows,
    });
  } catch (err) { next(err); }
};

exports.getUsers = async (req, res, next) => {
  try {
    const { page = 1, limit = 20, search, role, status, language } = req.query;
    let whereClause = 'WHERE 1=1';
    const params = []; let idx = 1;
    if (search) { whereClause += ` AND (u.name ILIKE $${idx} OR u.phone ILIKE $${idx} OR u.email ILIKE $${idx})`; params.push(`%${search}%`); idx++; }
    if (role) { whereClause += ` AND u.role = $${idx++}`; params.push(role); }
    if (status) { whereClause += ` AND u.status = $${idx++}`; params.push(status); }
    if (language) { whereClause += ` AND u.language = $${idx++}`; params.push(language); }
    const countResult = await query(`SELECT COUNT(*) FROM users u ${whereClause}`, params);
    const total = parseInt(countResult.rows[0].count, 10);
    const offset = (Number(page) - 1) * Number(limit);
    params.push(Number(limit), offset);
    const result = await query(`SELECT u.id, u.role, u.name, u.phone, u.email, u.language, u.status, u.created_at FROM users u ${whereClause} ORDER BY u.created_at DESC LIMIT $${idx++} OFFSET $${idx}`, params);
    return sendPaginated(res, result.rows, page, limit, total);
  } catch (err) { next(err); }
};

exports.suspendUser = async (req, res, next) => {
  try {
    const { id } = req.params;
    const result = await query("UPDATE users SET status = 'suspended' WHERE id = $1 AND role != 'admin' RETURNING id, name, role, status", [id]);
    if (result.rows.length === 0) return sendError(res, 404, 'User not found or cannot be suspended.');
    await logAdminAction(req.user.id, 'SUSPEND', 'users', id, { status: 'suspended' });
    return sendSuccess(res, 200, 'User suspended', result.rows[0]);
  } catch (err) { next(err); }
};

exports.reactivateUser = async (req, res, next) => {
  try {
    const { id } = req.params;
    const result = await query("UPDATE users SET status = 'active' WHERE id = $1 RETURNING id, name, role, status", [id]);
    if (result.rows.length === 0) return sendError(res, 404, 'User not found.');
    await logAdminAction(req.user.id, 'REACTIVATE', 'users', id, { status: 'active' });
    return sendSuccess(res, 200, 'User reactivated', result.rows[0]);
  } catch (err) { next(err); }
};

exports.getPendingDoctors = async (req, res, next) => {
  try {
    const result = await query(`SELECT u.id, u.name, u.phone, u.email, u.created_at, dp.specialization, dp.license_number, dp.credential_docs_json, dp.location, dp.bio, hp.name as health_provider_name FROM doctor_profiles dp JOIN users u ON dp.user_id = u.id LEFT JOIN health_providers hp ON dp.health_provider_id = hp.id WHERE dp.approval_status = 'pending' ORDER BY u.created_at DESC`);
    return sendSuccess(res, 200, 'Pending doctors retrieved', result.rows);
  } catch (err) { next(err); }
};

exports.approveDoctor = async (req, res, next) => {
  try {
    const { id } = req.params;
    const result = await query(`UPDATE doctor_profiles SET approval_status = 'approved', approved_by = $1, approved_at = NOW() WHERE user_id = $2 RETURNING *`, [req.user.id, id]);
    if (result.rows.length === 0) return sendError(res, 404, 'Doctor profile not found.');
    await logAdminAction(req.user.id, 'APPROVE', 'doctor_profiles', id, { approval_status: 'approved' });
    const doctorUser = await query('SELECT name, email FROM users WHERE id = $1', [id]);
    if (doctorUser.rows.length > 0 && doctorUser.rows[0].email) {
      try {
        await sendEmail({ to: doctorUser.rows[0].email, subject: 'MaternaLink - Doctor Registration Approved',
          html: `<h2>Congratulations ${doctorUser.rows[0].name}!</h2><p>Your doctor registration has been approved. You can now start accepting patients on MaternaLink.</p><p>Log in to your account to set your availability and start connecting with mothers.</p>` });
      } catch (e) { console.warn('⚠️ Approval email could not be sent:', e.message); }
    }
    return sendSuccess(res, 200, 'Doctor approved', result.rows[0]);
  } catch (err) { next(err); }
};

exports.rejectDoctor = async (req, res, next) => {
  try {
    const { id } = req.params;
    const { reason } = req.body;
    const result = await query(`UPDATE doctor_profiles SET approval_status = 'rejected', approved_by = $1, approved_at = NOW() WHERE user_id = $2 RETURNING *`, [req.user.id, id]);
    if (result.rows.length === 0) return sendError(res, 404, 'Doctor profile not found.');
    await logAdminAction(req.user.id, 'REJECT', 'doctor_profiles', id, { reason: reason || 'No reason provided' });
    const doctorUser = await query('SELECT name, email FROM users WHERE id = $1', [id]);
    if (doctorUser.rows.length > 0 && doctorUser.rows[0].email) {
      try {
        await sendEmail({ to: doctorUser.rows[0].email, subject: 'MaternaLink - Doctor Registration Status',
          html: `<h2>Dear ${doctorUser.rows[0].name}</h2><p>Your doctor registration could not be approved at this time.</p><p>Reason: ${reason || 'Please contact support for more information.'}</p><p>You may update your credentials and re-submit for approval.</p>` });
      } catch (e) { console.warn('⚠️ Rejection email could not be sent:', e.message); }
    }
    return sendSuccess(res, 200, 'Doctor rejected', result.rows[0]);
  } catch (err) { next(err); }
};

exports.getHealthProviders = async (req, res, next) => {
  try {
    const result = await query('SELECT * FROM health_providers ORDER BY name');
    return sendSuccess(res, 200, 'Health providers retrieved', result.rows);
  } catch (err) { next(err); }
};

exports.createHealthProvider = async (req, res, next) => {
  try {
    const { name, location, contact, serviceDescription } = req.body;
    const result = await query(`INSERT INTO health_providers (name, location, contact, service_description) VALUES ($1, $2, $3, $4) RETURNING *`, [name, location, contact, serviceDescription || null]);
    await logAdminAction(req.user.id, 'CREATE', 'health_providers', result.rows[0].id, { name });
    return sendSuccess(res, 201, 'Health provider created', result.rows[0]);
  } catch (err) { next(err); }
};

exports.updateHealthProvider = async (req, res, next) => {
  try {
    const { id } = req.params;
    const { name, location, contact, serviceDescription } = req.body;
    const result = await query(`UPDATE health_providers SET name = COALESCE($1, name), location = COALESCE($2, location), contact = COALESCE($3, contact), service_description = COALESCE($4, service_description) WHERE id = $5 RETURNING *`, [name, location, contact, serviceDescription, id]);
    if (result.rows.length === 0) return sendError(res, 404, 'Health provider not found.');
    await logAdminAction(req.user.id, 'UPDATE', 'health_providers', id, { updates: req.body });
    return sendSuccess(res, 200, 'Health provider updated', result.rows[0]);
  } catch (err) { next(err); }
};

exports.toggleHealthProviderStatus = async (req, res, next) => {
  try {
    const { id } = req.params;
    const { status } = req.body;
    if (!['active', 'inactive'].includes(status)) return sendError(res, 400, 'Status must be active or inactive.');
    const result = await query('UPDATE health_providers SET status = $1 WHERE id = $2 RETURNING *', [status, id]);
    if (result.rows.length === 0) return sendError(res, 404, 'Health provider not found.');
    await logAdminAction(req.user.id, 'UPDATE_STATUS', 'health_providers', id, { status });
    return sendSuccess(res, 200, 'Health provider status updated', result.rows[0]);
  } catch (err) { next(err); }
};

exports.getAuditLogs = async (req, res, next) => {
  try {
    const { page = 1, limit = 50, date, actionType } = req.query;
    let whereClause = 'WHERE 1=1'; const params = []; let idx = 1;
    if (date) { whereClause += ` AND DATE(al.created_at) = $${idx++}`; params.push(date); }
    if (actionType) { whereClause += ` AND al.action_type = $${idx++}`; params.push(actionType.toUpperCase()); }
    const countResult = await query(`SELECT COUNT(*) FROM audit_logs al ${whereClause}`, params);
    const total = parseInt(countResult.rows[0].count, 10);
    const offset = (Number(page) - 1) * Number(limit);
    params.push(Number(limit), offset);
    const result = await query(`SELECT al.*, u.name as admin_name FROM audit_logs al LEFT JOIN users u ON al.admin_id = u.id ${whereClause} ORDER BY al.created_at DESC LIMIT $${idx++} OFFSET $${idx}`, params);
    return sendPaginated(res, result.rows, page, limit, total);
  } catch (err) { next(err); }
};

exports.moderatePost = async (req, res, next) => {
  try {
    const { id } = req.params;
    const result = await query(`UPDATE community_posts SET is_deleted = true, deleted_by_admin_id = $1 WHERE id = $2 RETURNING id`, [req.user.id, id]);
    if (result.rows.length === 0) return sendError(res, 404, 'Post not found.');
    await logAdminAction(req.user.id, 'DELETE', 'community_posts', id, { reason: 'Admin moderation' });
    return sendSuccess(res, 200, 'Post removed');
  } catch (err) { next(err); }
};

exports.updateCommunityRules = async (req, res, next) => {
  try {
    const { rules } = req.body;
    return sendSuccess(res, 200, 'Community rules updated', { rules });
  } catch (err) { next(err); }
};

exports.getStats = async (req, res, next) => {
  try {
    const [users, content, appointments] = await Promise.all([
      query(`SELECT COUNT(*) as total, COUNT(*) FILTER (WHERE status = 'active') as active, COUNT(*) FILTER (WHERE role = 'mother') as mothers, COUNT(*) FILTER (WHERE role = 'doctor') as doctors FROM users`),
      query(`SELECT (SELECT COUNT(*) FROM nutrition_content WHERE is_published = true) as nutrition, (SELECT COUNT(*) FROM fetal_tracker_content) as fetal, (SELECT COUNT(*) FROM exercise_content WHERE is_published = true) as exercises, (SELECT COUNT(*) FROM sleep_tips) as sleep_tips, (SELECT COUNT(*) FROM music_tracks WHERE is_active = true) as music, (SELECT COUNT(*) FROM health_tips) as health_tips`),
      query(`SELECT COUNT(*) as total, COUNT(*) FILTER (WHERE status = 'pending') as pending, COUNT(*) FILTER (WHERE status = 'confirmed') as confirmed, COUNT(*) FILTER (WHERE status = 'completed') as completed FROM appointments`),
    ]);
    return sendSuccess(res, 200, 'Stats retrieved', { users: users.rows[0], content: content.rows[0], appointments: appointments.rows[0] });
  } catch (err) { next(err); }
};

const { query } = require('../config/db');
const { sendSuccess, sendError, sendPaginated } = require('../utils/apiResponse');

// ── GET /api/v1/emergency/contacts ───────────────────────────────────
exports.getContacts = async (req, res, next) => {
  try {
    const { city, page = 1, limit = 20 } = req.query;
    let whereClause = 'WHERE ec.status = $1';
    const params = ['active'];
    let idx = 2;

    if (city) {
      whereClause += ` AND ec.location ILIKE $${idx++}`;
      params.push(`%${city}%`);
    }

    const countResult = await query(`SELECT COUNT(*) FROM emergency_contacts ec ${whereClause}`, params);
    const total = parseInt(countResult.rows[0].count, 10);

    const offset = (Number(page) - 1) * Number(limit);
    params.push(Number(limit), offset);

    const result = await query(
      `SELECT ec.* FROM emergency_contacts ec ${whereClause}
       ORDER BY ec.contact_name LIMIT $${idx++} OFFSET $${idx}`,
      params
    );

    return sendPaginated(res, result.rows, page, limit, total);
  } catch (err) {
    next(err);
  }
};

// ── POST /api/v1/emergency/contacts (admin) ──────────────────────────
exports.createContact = async (req, res, next) => {
  try {
    const { contactName, phone, relationship } = req.body;
    const result = await query(
      `INSERT INTO emergency_contacts (contact_name, phone, relationship) VALUES ($1, $2, $3) RETURNING *`,
      [contactName, phone, relationship || null]
    );
    return sendSuccess(res, 201, 'Emergency contact created', result.rows[0]);
  } catch (err) {
    next(err);
  }
};

// ── PUT /api/v1/emergency/contacts/:id (admin) ───────────────────────
exports.updateContact = async (req, res, next) => {
  try {
    const { id } = req.params;
    const { contactName, phone, relationship } = req.body;
    const result = await query(
      `UPDATE emergency_contacts SET contact_name = COALESCE($1, contact_name), phone = COALESCE($2, phone), relationship = COALESCE($3, relationship) WHERE id = $4 RETURNING *`,
      [contactName, phone, relationship, id]
    );
    if (result.rows.length === 0) return sendError(res, 404, 'Emergency contact not found.');
    return sendSuccess(res, 200, 'Emergency contact updated', result.rows[0]);
  } catch (err) {
    next(err);
  }
};

// ── DELETE /api/v1/emergency/contacts/:id (admin) ────────────────────
exports.deleteContact = async (req, res, next) => {
  try {
    const result = await query('DELETE FROM emergency_contacts WHERE id = $1 RETURNING id', [req.params.id]);
    if (result.rows.length === 0) return sendError(res, 404, 'Emergency contact not found.');
    return sendSuccess(res, 200, 'Emergency contact deleted');
  } catch (err) {
    next(err);
  }
};

// ── GET /api/v1/emergency/health-tips ────────────────────────────────
exports.getHealthTips = async (req, res, next) => {
  try {
    const { lang = 'am', page = 1, limit = 20 } = req.query;
    const offset = (Number(page) - 1) * Number(limit);

    const countResult = await query('SELECT COUNT(*) FROM health_tips');
    const total = parseInt(countResult.rows[0].count, 10);

    const result = await query(
      `SELECT id, title_am, title_or, title_en, warning_signs_am, warning_signs_or, warning_signs_en,
              first_aid_am, first_aid_or, first_aid_en
       FROM health_tips ORDER BY id LIMIT $1 OFFSET $2`,
      [Number(limit), offset]
    );

    const l = lang === 'or' ? 'or' : lang === 'en' ? 'en' : 'am';
    const localized = result.rows.map(r => ({
      ...r,
      title: r[`title_${l}`] || r.title_am || '',
      warningSigns: r[`warning_signs_${l}`] || r.warning_signs_am || '',
      firstAid: r[`first_aid_${l}`] || r.first_aid_am || '',
    }));

    return sendPaginated(res, localized, page, limit, total);
  } catch (err) {
    next(err);
  }
};

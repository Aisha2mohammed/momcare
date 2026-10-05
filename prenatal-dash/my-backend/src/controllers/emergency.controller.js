const { query } = require('../config/db');
const { normalizeLang } = require('../utils/normalizeLang');
const { sendSuccess, sendPaginated } = require('../utils/apiResponse');

// Note: this controller used to expose a "public facility directory" over the
// emergency_contacts table (getContacts/createContact/updateContact/deleteContact).
// That was wrong twice over: emergency_contacts is a per-mother table keyed by
// NOT NULL mother_id, and it has no status/location columns — every one of those
// four endpoints returned HTTP 500. Per-mother contacts are served by
// mother.controller.js at /mothers/:id/emergency-contacts. Removed.

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

    const l = normalizeLang(lang);
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

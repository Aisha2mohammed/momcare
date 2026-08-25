const { query } = require('../config/db');
const { sendSuccess, sendError, sendPaginated } = require('../utils/apiResponse');

// ── GET /api/v1/fetal ─────────────────────────────────────────────────
exports.getAll = async (req, res, next) => {
  try {
    const { lang = 'am', page = 1, limit = 42 } = req.query;
    const offset = (Number(page) - 1) * Number(limit);

    const countResult = await query('SELECT COUNT(*) FROM fetal_tracker_content');
    const total = parseInt(countResult.rows[0].count, 10);

    const result = await query(
      `SELECT * FROM fetal_tracker_content ORDER BY week_number ASC LIMIT $1 OFFSET $2`,
      [Number(limit), offset]
    );

    const localized = result.rows.map(r => localize(r, lang));
    return sendPaginated(res, localized, page, limit, total);
  } catch (err) {
    next(err);
  }
};

// ── GET /api/v1/fetal/:week ───────────────────────────────────────────
exports.getByWeek = async (req, res, next) => {
  try {
    const { week } = req.params;
    const { lang = 'am' } = req.query;

    const weekNum = Number(week);
    if (isNaN(weekNum) || weekNum < 1 || weekNum > 42) {
      return sendError(res, 400, 'Week must be between 1 and 42.');
    }

    const result = await query('SELECT * FROM fetal_tracker_content WHERE week_number = $1', [weekNum]);
    if (result.rows.length === 0) return sendError(res, 404, `No data found for week ${weekNum}.`);

    return sendSuccess(res, 200, `Week ${weekNum} fetal data`, localize(result.rows[0], lang));
  } catch (err) {
    next(err);
  }
};

// ── POST /api/v1/fetal (admin) ────────────────────────────────────────
exports.create = async (req, res, next) => {
  try {
    const { weekNumber, sizeComparison, milestoneAm, milestoneOr, milestoneEn, tipsAm, tipsOr, tipsEn, imageUrl } = req.body;
    const result = await query(
      `INSERT INTO fetal_tracker_content (week_number, size_comparison, milestone_am, milestone_or, milestone_en, tips_am, tips_or, tips_en, image_url)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9) RETURNING *`,
      [weekNumber, sizeComparison || null, milestoneAm, milestoneOr, milestoneEn, tipsAm, tipsOr, tipsEn, imageUrl || null]
    );
    return sendSuccess(res, 201, 'Fetal data created', result.rows[0]);
  } catch (err) {
    next(err);
  }
};

// ── PUT /api/v1/fetal/:id (admin) ─────────────────────────────────────
exports.update = async (req, res, next) => {
  try {
    const fieldMap = {
      weekNumber: 'week_number', sizeComparison: 'size_comparison',
      milestoneAm: 'milestone_am', milestoneOr: 'milestone_or', milestoneEn: 'milestone_en',
      tipsAm: 'tips_am', tipsOr: 'tips_or', tipsEn: 'tips_en', imageUrl: 'image_url'
    };
    const updates = [];
    const values = [];
    let idx = 1;

    for (const [bodyKey, dbField] of Object.entries(fieldMap)) {
      if (req.body[bodyKey] !== undefined) {
        updates.push(`${dbField} = $${idx++}`);
        values.push(req.body[bodyKey]);
      }
    }

    if (updates.length === 0) return sendError(res, 400, 'No fields to update.');

    values.push(req.params.id);
    const result = await query(
      `UPDATE fetal_tracker_content SET ${updates.join(', ')} WHERE id = $${idx} RETURNING *`,
      values
    );
    if (result.rows.length === 0) return sendError(res, 404, 'Fetal data not found.');

    return sendSuccess(res, 200, 'Fetal data updated', result.rows[0]);
  } catch (err) {
    next(err);
  }
};

// ── DELETE /api/v1/fetal/:id (admin) ──────────────────────────────────
exports.remove = async (req, res, next) => {
  try {
    const result = await query('DELETE FROM fetal_tracker_content WHERE id = $1 RETURNING id', [req.params.id]);
    if (result.rows.length === 0) return sendError(res, 404, 'Fetal data not found.');
    return sendSuccess(res, 200, 'Fetal data deleted');
  } catch (err) {
    next(err);
  }
};

function localize(item, lang) {
  const l = lang === 'or' ? 'or' : lang === 'en' ? 'en' : 'am';
  return {
    ...item,
    milestone: item[`milestone_${l}`] || item.milestone_am || '',
    tips: item[`tips_${l}`] || item.tips_am || '',
  };
}

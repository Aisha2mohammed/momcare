const { query } = require('../config/db');
const { sendSuccess, sendError, sendPaginated } = require('../utils/apiResponse');

// ── GET /api/v1/nutrition ─────────────────────────────────────────────
exports.getAll = async (req, res, next) => {
  try {
    const { trimester, lang = 'am', page = 1, limit = 20 } = req.query;
    let whereClause = 'WHERE nc.is_published = true';
    const params = [];
    let paramIndex = 1;

    if (trimester) {
      whereClause += ` AND nc.trimester = $${paramIndex++}`;
      params.push(trimester);
    }

    const countResult = await query(`SELECT COUNT(*) FROM nutrition_content nc ${whereClause}`, params);
    const total = parseInt(countResult.rows[0].count, 10);

    const offset = (Number(page) - 1) * Number(limit);
    params.push(Number(limit), offset);

    const result = await query(
      `SELECT id, trimester,
              title_am, title_or, title_en,
              body_am, body_or, body_en,
              image_url, is_published, created_at
       FROM nutrition_content nc ${whereClause}
       ORDER BY nc.trimester, nc.created_at DESC
       LIMIT $${paramIndex++} OFFSET $${paramIndex}`,
      params
    );

    const localized = result.rows.map(r => localize(r, lang));

    return sendPaginated(res, localized, page, limit, total);
  } catch (err) {
    next(err);
  }
};

// ── GET /api/v1/nutrition/:id ─────────────────────────────────────────
exports.getOne = async (req, res, next) => {
  try {
    const { lang = 'am' } = req.query;
    const result = await query('SELECT * FROM nutrition_content WHERE id = $1', [req.params.id]);
    if (result.rows.length === 0) return sendError(res, 404, 'Nutrition content not found.');

    return sendSuccess(res, 200, 'Nutrition content retrieved', localize(result.rows[0], lang));
  } catch (err) {
    next(err);
  }
};

// ── POST /api/v1/nutrition ────────────────────────────────────────────
exports.create = async (req, res, next) => {
  try {
    const { trimester, titleAm, titleOr, titleEn, bodyAm, bodyOr, bodyEn, imageUrl, isPublished } = req.body;
    const result = await query(
      `INSERT INTO nutrition_content (trimester, title_am, title_or, title_en, body_am, body_or, body_en, image_url, is_published)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9) RETURNING *`,
      [trimester, titleAm, titleOr, titleEn, bodyAm, bodyOr, bodyEn, imageUrl || null, isPublished || false]
    );
    return sendSuccess(res, 201, 'Nutrition content created', result.rows[0]);
  } catch (err) {
    next(err);
  }
};

// ── PUT /api/v1/nutrition/:id ─────────────────────────────────────────
exports.update = async (req, res, next) => {
  try {
    const { id } = req.params;
    const fields = ['trimester', 'title_am', 'title_or', 'title_en', 'body_am', 'body_or', 'body_en', 'image_url', 'is_published'];
    const updates = [];
    const values = [];
    let idx = 1;

    const fieldMap = {
      trimester: 'trimester', titleAm: 'title_am', titleOr: 'title_or', titleEn: 'title_en',
      bodyAm: 'body_am', bodyOr: 'body_or', bodyEn: 'body_en',
      imageUrl: 'image_url', isPublished: 'is_published'
    };

    for (const [bodyKey, dbField] of Object.entries(fieldMap)) {
      if (req.body[bodyKey] !== undefined) {
        updates.push(`${dbField} = $${idx++}`);
        values.push(req.body[bodyKey]);
      }
    }

    if (updates.length === 0) return sendError(res, 400, 'No fields to update.');

    values.push(id);
    const result = await query(
      `UPDATE nutrition_content SET ${updates.join(', ')} WHERE id = $${idx} RETURNING *`,
      values
    );
    if (result.rows.length === 0) return sendError(res, 404, 'Nutrition content not found.');

    return sendSuccess(res, 200, 'Nutrition content updated', result.rows[0]);
  } catch (err) {
    next(err);
  }
};

// ── DELETE /api/v1/nutrition/:id ──────────────────────────────────────
exports.remove = async (req, res, next) => {
  try {
    const result = await query('DELETE FROM nutrition_content WHERE id = $1 RETURNING id', [req.params.id]);
    if (result.rows.length === 0) return sendError(res, 404, 'Nutrition content not found.');
    return sendSuccess(res, 200, 'Nutrition content deleted');
  } catch (err) {
    next(err);
  }
};

function localize(item, lang) {
  const l = lang === 'or' ? 'or' : lang === 'en' ? 'en' : 'am';
  return {
    ...item,
    title: item[`title_${l}`] || item.title_am || '',
    body: item[`body_${l}`] || item.body_am || '',
  };
}

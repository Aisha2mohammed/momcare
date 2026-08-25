const { query } = require('../config/db');
const { sendSuccess, sendError, sendPaginated } = require('../utils/apiResponse');

exports.getAll = async (req, res, next) => {
  try {
    const { trimester, lang = 'am', page = 1, limit = 20 } = req.query;
    let whereClause = 'WHERE 1=1';
    const params = [];
    let idx = 1;

    if (trimester) {
      whereClause += ` AND (st.trimester = $${idx} OR st.trimester = 0)`;
      params.push(Number(trimester));
      idx++;
    }

    const countResult = await query(`SELECT COUNT(*) FROM sleep_tips st ${whereClause}`, params);
    const total = parseInt(countResult.rows[0].count, 10);

    const offset = (Number(page) - 1) * Number(limit);
    params.push(Number(limit), offset);

    const result = await query(
      `SELECT id, trimester, title_am, title_or, title_en, description_am, description_or, description_en, illustration_url
       FROM sleep_tips st ${whereClause}
       ORDER BY st.trimester, st.id
       LIMIT $${idx++} OFFSET $${idx}`,
      params
    );

    const localized = result.rows.map(r => localize(r, lang));
    return sendPaginated(res, localized, page, limit, total);
  } catch (err) {
    next(err);
  }
};

exports.getOne = async (req, res, next) => {
  try {
    const { lang = 'am' } = req.query;
    const result = await query('SELECT * FROM sleep_tips WHERE id = $1', [req.params.id]);
    if (result.rows.length === 0) return sendError(res, 404, 'Sleep tip not found.');
    return sendSuccess(res, 200, 'Sleep tip retrieved', localize(result.rows[0], lang));
  } catch (err) {
    next(err);
  }
};

exports.create = async (req, res, next) => {
  try {
    const { trimester, titleAm, titleOr, titleEn, descriptionAm, descriptionOr, descriptionEn, illustrationUrl } = req.body;
    const result = await query(
      `INSERT INTO sleep_tips (trimester, title_am, title_or, title_en, description_am, description_or, description_en, illustration_url)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8) RETURNING *`,
      [trimester || 0, titleAm, titleOr, titleEn, descriptionAm, descriptionOr, descriptionEn, illustrationUrl || null]
    );
    return sendSuccess(res, 201, 'Sleep tip created', result.rows[0]);
  } catch (err) {
    next(err);
  }
};

exports.update = async (req, res, next) => {
  try {
    const fieldMap = {
      trimester: 'trimester', titleAm: 'title_am', titleOr: 'title_or', titleEn: 'title_en',
      descriptionAm: 'description_am', descriptionOr: 'description_or', descriptionEn: 'description_en',
      illustrationUrl: 'illustration_url'
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
    const result = await query(`UPDATE sleep_tips SET ${updates.join(', ')} WHERE id = $${idx} RETURNING *`, values);
    if (result.rows.length === 0) return sendError(res, 404, 'Sleep tip not found.');
    return sendSuccess(res, 200, 'Sleep tip updated', result.rows[0]);
  } catch (err) {
    next(err);
  }
};

exports.remove = async (req, res, next) => {
  try {
    const result = await query('DELETE FROM sleep_tips WHERE id = $1 RETURNING id', [req.params.id]);
    if (result.rows.length === 0) return sendError(res, 404, 'Sleep tip not found.');
    return sendSuccess(res, 200, 'Sleep tip deleted');
  } catch (err) {
    next(err);
  }
};

function localize(item, lang) {
  const l = lang === 'or' ? 'or' : lang === 'en' ? 'en' : 'am';
  return {
    ...item,
    title: item[`title_${l}`] || item.title_am || '',
    description: item[`description_${l}`] || item.description_am || '',
  };
}

const { query } = require('../config/db');
const { sendSuccess, sendError, sendPaginated } = require('../utils/apiResponse');

exports.getAll = async (req, res, next) => {
  try {
    const { category, lang = 'am', page = 1, limit = 20 } = req.query;
    let whereClause = 'WHERE 1=1';
    const params = [];
    let idx = 1;

    if (category) {
      whereClause += ` AND $${idx} = ANY(ht.warning_signs_am)`;
      params.push(category);
      idx++;
    }

    const countResult = await query(`SELECT COUNT(*) FROM health_tips ht ${whereClause}`, params);
    const total = parseInt(countResult.rows[0].count, 10);

    const offset = (Number(page) - 1) * Number(limit);
    params.push(Number(limit), offset);

    const result = await query(
      `SELECT id, title_am, title_or, title_en, warning_signs_am, warning_signs_or, warning_signs_en,
              first_aid_am, first_aid_or, first_aid_en
       FROM health_tips ht ${whereClause}
       ORDER BY ht.id
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
    const result = await query('SELECT * FROM health_tips WHERE id = $1', [req.params.id]);
    if (result.rows.length === 0) return sendError(res, 404, 'Health tip not found.');
    return sendSuccess(res, 200, 'Health tip retrieved', localize(result.rows[0], lang));
  } catch (err) {
    next(err);
  }
};

exports.create = async (req, res, next) => {
  try {
    const { titleAm, titleOr, titleEn, warningSignsAm, warningSignsOr, warningSignsEn, firstAidAm, firstAidOr, firstAidEn } = req.body;
    const result = await query(
      `INSERT INTO health_tips (title_am, title_or, title_en, warning_signs_am, warning_signs_or, warning_signs_en, first_aid_am, first_aid_or, first_aid_en)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9) RETURNING *`,
      [titleAm, titleOr, titleEn, warningSignsAm || '', warningSignsOr || '', warningSignsEn || '', firstAidAm || '', firstAidOr || '', firstAidEn || '']
    );
    return sendSuccess(res, 201, 'Health tip created', result.rows[0]);
  } catch (err) {
    next(err);
  }
};

exports.update = async (req, res, next) => {
  try {
    const fieldMap = {
      titleAm: 'title_am', titleOr: 'title_or', titleEn: 'title_en',
      warningSignsAm: 'warning_signs_am', warningSignsOr: 'warning_signs_or', warningSignsEn: 'warning_signs_en',
      firstAidAm: 'first_aid_am', firstAidOr: 'first_aid_or', firstAidEn: 'first_aid_en'
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
    const result = await query(`UPDATE health_tips SET ${updates.join(', ')} WHERE id = $${idx} RETURNING *`, values);
    if (result.rows.length === 0) return sendError(res, 404, 'Health tip not found.');
    return sendSuccess(res, 200, 'Health tip updated', result.rows[0]);
  } catch (err) {
    next(err);
  }
};

exports.remove = async (req, res, next) => {
  try {
    const result = await query('DELETE FROM health_tips WHERE id = $1 RETURNING id', [req.params.id]);
    if (result.rows.length === 0) return sendError(res, 404, 'Health tip not found.');
    return sendSuccess(res, 200, 'Health tip deleted');
  } catch (err) {
    next(err);
  }
};

function localize(item, lang) {
  const l = lang === 'or' ? 'or' : lang === 'en' ? 'en' : 'am';
  return {
    ...item,
    title: item[`title_${l}`] || item.title_am || '',
    warningSigns: item[`warning_signs_${l}`] || item.warning_signs_am || '',
    firstAid: item[`first_aid_${l}`] || item.first_aid_am || '',
  };
}

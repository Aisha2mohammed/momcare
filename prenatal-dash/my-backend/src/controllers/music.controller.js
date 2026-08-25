const { query } = require('../config/db');
const { sendSuccess, sendError, sendPaginated } = require('../utils/apiResponse');

exports.getAll = async (req, res, next) => {
  try {
    const { category, lang = 'am', page = 1, limit = 20 } = req.query;
    let whereClause = 'WHERE mt.is_active = true';
    const params = [];
    let idx = 1;

    if (category) {
      whereClause += ` AND mt.category = $${idx++}`;
      params.push(category);
    }

    const countResult = await query(`SELECT COUNT(*) FROM music_tracks mt ${whereClause}`, params);
    const total = parseInt(countResult.rows[0].count, 10);

    const offset = (Number(page) - 1) * Number(limit);
    params.push(Number(limit), offset);

    const result = await query(
      `SELECT id, title_am, title_or, title_en, category, duration, thumbnail_url, media_url, is_active
       FROM music_tracks mt ${whereClause}
       ORDER BY mt.id DESC
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
    const result = await query('SELECT * FROM music_tracks WHERE id = $1', [req.params.id]);
    if (result.rows.length === 0) return sendError(res, 404, 'Music track not found.');
    return sendSuccess(res, 200, 'Music track retrieved', localize(result.rows[0], lang));
  } catch (err) {
    next(err);
  }
};

exports.create = async (req, res, next) => {
  try {
    const { titleAm, titleOr, titleEn, category, duration, thumbnailUrl, mediaUrl, isActive } = req.body;
    const result = await query(
      `INSERT INTO music_tracks (title_am, title_or, title_en, category, duration, thumbnail_url, media_url, is_active)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8) RETURNING *`,
      [titleAm, titleOr, titleEn, category, duration || null, thumbnailUrl || null, mediaUrl, isActive !== false]
    );
    return sendSuccess(res, 201, 'Music track created', result.rows[0]);
  } catch (err) {
    next(err);
  }
};

exports.update = async (req, res, next) => {
  try {
    const fieldMap = {
      titleAm: 'title_am', titleOr: 'title_or', titleEn: 'title_en',
      category: 'category', duration: 'duration',
      thumbnailUrl: 'thumbnail_url', mediaUrl: 'media_url', isActive: 'is_active'
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
    const result = await query(`UPDATE music_tracks SET ${updates.join(', ')} WHERE id = $${idx} RETURNING *`, values);
    if (result.rows.length === 0) return sendError(res, 404, 'Music track not found.');
    return sendSuccess(res, 200, 'Music track updated', result.rows[0]);
  } catch (err) {
    next(err);
  }
};

exports.remove = async (req, res, next) => {
  try {
    const result = await query('DELETE FROM music_tracks WHERE id = $1 RETURNING id', [req.params.id]);
    if (result.rows.length === 0) return sendError(res, 404, 'Music track not found.');
    return sendSuccess(res, 200, 'Music track deleted');
  } catch (err) {
    next(err);
  }
};

function localize(item, lang) {
  const l = lang === 'or' ? 'or' : lang === 'en' ? 'en' : 'am';
  return {
    ...item,
    title: item[`title_${l}`] || item.title_am || '',
  };
}

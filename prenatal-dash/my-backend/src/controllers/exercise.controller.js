const { query } = require('../config/db');
const { sendSuccess, sendError, sendPaginated } = require('../utils/apiResponse');

exports.getAll = async (req, res, next) => {
  try {
    const { trimester, lang = 'am', category, page = 1, limit = 20 } = req.query;
    let whereClause = 'WHERE ec.is_published = true';
    const params = [];
    let idx = 1;

    if (trimester) {
      whereClause += ` AND ec.trimester_flags @> ARRAY[$${idx++}]`;
      params.push(trimester);
    }
    if (category) {
      whereClause += ` AND $${idx++} = ANY(ec.trimester_flags)`;
      params.push(category);
    }

    const countResult = await query(`SELECT COUNT(*) FROM exercise_content ec ${whereClause}`, params);
    const total = parseInt(countResult.rows[0].count, 10);

    const offset = (Number(page) - 1) * Number(limit);
    params.push(Number(limit), offset);

    const result = await query(
      `SELECT id, name_am, name_or, name_en, trimester_flags, duration_min,
              safety_notes_am, safety_notes_or, safety_notes_en, media_url, is_published
       FROM exercise_content ec ${whereClause}
       ORDER BY ec.id LIMIT $${idx++} OFFSET $${idx}`,
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
    const result = await query('SELECT * FROM exercise_content WHERE id = $1', [req.params.id]);
    if (result.rows.length === 0) return sendError(res, 404, 'Exercise not found.');
    return sendSuccess(res, 200, 'Exercise retrieved', localize(result.rows[0], lang));
  } catch (err) {
    next(err);
  }
};

exports.create = async (req, res, next) => {
  try {
    const { nameAm, nameOr, nameEn, trimesterFlags, durationMin, safetyNotesAm, safetyNotesOr, safetyNotesEn, mediaUrl, isPublished } = req.body;
    const result = await query(
      `INSERT INTO exercise_content (name_am, name_or, name_en, trimester_flags, duration_min, safety_notes_am, safety_notes_or, safety_notes_en, media_url, is_published)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10) RETURNING *`,
      [nameAm, nameOr, nameEn, trimesterFlags || [1], durationMin || null, safetyNotesAm, safetyNotesOr, safetyNotesEn, mediaUrl || null, isPublished || false]
    );
    return sendSuccess(res, 201, 'Exercise created', result.rows[0]);
  } catch (err) {
    next(err);
  }
};

exports.update = async (req, res, next) => {
  try {
    const fieldMap = {
      nameAm: 'name_am', nameOr: 'name_or', nameEn: 'name_en',
      trimesterFlags: 'trimester_flags', durationMin: 'duration_min',
      safetyNotesAm: 'safety_notes_am', safetyNotesOr: 'safety_notes_or', safetyNotesEn: 'safety_notes_en',
      mediaUrl: 'media_url', isPublished: 'is_published'
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
    const result = await query(`UPDATE exercise_content SET ${updates.join(', ')} WHERE id = $${idx} RETURNING *`, values);
    if (result.rows.length === 0) return sendError(res, 404, 'Exercise not found.');
    return sendSuccess(res, 200, 'Exercise updated', result.rows[0]);
  } catch (err) {
    next(err);
  }
};

exports.remove = async (req, res, next) => {
  try {
    const result = await query('DELETE FROM exercise_content WHERE id = $1 RETURNING id', [req.params.id]);
    if (result.rows.length === 0) return sendError(res, 404, 'Exercise not found.');
    return sendSuccess(res, 200, 'Exercise deleted');
  } catch (err) {
    next(err);
  }
};

function localize(item, lang) {
  const l = lang === 'or' ? 'or' : lang === 'en' ? 'en' : 'am';
  return {
    ...item,
    name: item[`name_${l}`] || item.name_am || '',
    safetyNotes: item[`safety_notes_${l}`] || item.safety_notes_am || '',
  };
}

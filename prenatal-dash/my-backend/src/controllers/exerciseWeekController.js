const { query } = require('../config/db');
const { sendSuccess, sendError, sendPaginated } = require('../utils/apiResponse');

exports.getAll = async (req, res, next) => {
  try {
    const { trimester, month, week, lang = 'en', page = 1, limit = 20 } = req.query;
    let whereClause = 'WHERE 1=1';
    const params = [];
    let idx = 1;

    if (trimester) { whereClause += ` AND trimester = $${idx++}`; params.push(Number(trimester)); }
    if (month) { whereClause += ` AND month = $${idx++}`; params.push(Number(month)); }
    if (week) { whereClause += ` AND week = $${idx++}`; params.push(Number(week)); }

    const countResult = await query(`SELECT COUNT(*) FROM exercise_weeks ${whereClause}`, params);
    const total = parseInt(countResult.rows[0].count, 10);

    const offset = (Number(page) - 1) * Number(limit);
    params.push(Number(limit), offset);

    const result = await query(
      `SELECT * FROM exercise_weeks ${whereClause} ORDER BY trimester, week LIMIT $${idx++} OFFSET $${idx}`,
      params
    );

    // Return all raw fields (for admin panel) plus a localized convenience field
    const localized = result.rows.map(row => localize(row, lang));
    return sendPaginated(res, localized, page, limit, total);
  } catch (err) {
    next(err);
  }
};

exports.create = async (req, res, next) => {
  try {
    const {
      trimester, month, week,
      whyImportantEn, whyImportantAm, whyImportantOr, whyImportantSo,
      exerciseTipsEn, exerciseTipsAm, exerciseTipsOr, exerciseTipsSo,
      tipsEn, tipsAm, tipsOr, tipsSo,
      titleEn, titleAm, titleOr, titleSo
    } = req.body;

    const trimesterMap = { '1st': 1, '2nd': 2, '3rd': 3 };
    const normalizedTrimester = trimesterMap[trimester] ?? Number(trimester);
    const normalizedMonth = Number(month);
    const normalizedWeek = Number(week);

    if ([normalizedTrimester, normalizedMonth, normalizedWeek].some(v => Number.isNaN(v))) {
      return sendError(res, 400, 'trimester, month, and week must be valid numbers');
    }

    const finalTipsEn = exerciseTipsEn || tipsEn;
    const finalTipsAm = exerciseTipsAm || tipsAm;
    const finalTipsOr = exerciseTipsOr || tipsOr;
    const finalTipsSo = exerciseTipsSo || tipsSo;

    const result = await query(
      `INSERT INTO exercise_weeks (
        trimester, month, week,
        why_important_en, why_important_am, why_important_or, why_important_so,
        exercise_tips_en, exercise_tips_am, exercise_tips_or, exercise_tips_so
      ) VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11) RETURNING *`,
      [
        normalizedTrimester, normalizedMonth, normalizedWeek,
        whyImportantEn, whyImportantAm, whyImportantOr, whyImportantSo,
        finalTipsEn, finalTipsAm, finalTipsOr, finalTipsSo
      ]
    );

    return sendSuccess(res, 201, 'Exercise week entry created', result.rows[0]);
  } catch (err) {
    next(err);
  }
};

exports.update = async (req, res, next) => {
  try {
    const fieldMap = {
      trimester: 'trimester', month: 'month', week: 'week',
      whyImportantEn: 'why_important_en', whyImportantAm: 'why_important_am',
      whyImportantOr: 'why_important_or', whyImportantSo: 'why_important_so',
      exerciseTipsEn: 'exercise_tips_en', exerciseTipsAm: 'exercise_tips_am',
      exerciseTipsOr: 'exercise_tips_or', exerciseTipsSo: 'exercise_tips_so',
      // Accept tipsEn/Am/Or/So as aliases
      tipsEn: 'exercise_tips_en', tipsAm: 'exercise_tips_am',
      tipsOr: 'exercise_tips_or', tipsSo: 'exercise_tips_so',
      isPublished: 'is_published',
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
    const result = await query(`UPDATE exercise_weeks SET ${updates.join(', ')} WHERE id = $${idx} RETURNING *`, values);
    if (result.rows.length === 0) return sendError(res, 404, 'Exercise week entry not found.');
    return sendSuccess(res, 200, 'Exercise week updated', result.rows[0]);
  } catch (err) {
    next(err);
  }
};

exports.remove = async (req, res, next) => {
  try {
    const result = await query('DELETE FROM exercise_weeks WHERE id = $1 RETURNING id', [req.params.id]);
    if (result.rows.length === 0) return sendError(res, 404, 'Exercise week entry not found.');
    return sendSuccess(res, 200, 'Exercise week deleted');
  } catch (err) {
    next(err);
  }
};

function localize(item, lang) {
  const l = ['en', 'am', 'or', 'so'].includes(lang) ? lang : 'en';
  return {
    id: item.id,
    trimester: item.trimester,
    month: item.month,
    week: item.week,
    is_published: item.is_published,
    isPublished: item.is_published,
    // Raw multilingual fields (for admin panel use)
    why_important_en: item.why_important_en || '',
    why_important_am: item.why_important_am || '',
    why_important_or: item.why_important_or || '',
    why_important_so: item.why_important_so || '',
    whyImportantEn: item.why_important_en || '',
    whyImportantAm: item.why_important_am || '',
    whyImportantOr: item.why_important_or || '',
    whyImportantSo: item.why_important_so || '',
    exercise_tips_en: item.exercise_tips_en || '',
    exercise_tips_am: item.exercise_tips_am || '',
    exercise_tips_or: item.exercise_tips_or || '',
    exercise_tips_so: item.exercise_tips_so || '',
    tipsEn: item.exercise_tips_en || '',
    tipsAm: item.exercise_tips_am || '',
    tipsOr: item.exercise_tips_or || '',
    tipsSo: item.exercise_tips_so || '',
    // Localized convenience fields
    why_important: item[`why_important_${l}`] || item.why_important_en || '',
    exercise_tips: item[`exercise_tips_${l}`] || item.exercise_tips_en || ''
  };
}

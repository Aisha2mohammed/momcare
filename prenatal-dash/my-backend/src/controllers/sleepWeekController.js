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

    const countResult = await query(`SELECT COUNT(*) FROM sleep_weeks ${whereClause}`, params);
    const total = parseInt(countResult.rows[0].count, 10);

    const offset = (Number(page) - 1) * Number(limit);
    params.push(Number(limit), offset);

    const result = await query(
      `SELECT * FROM sleep_weeks ${whereClause} ORDER BY trimester, week LIMIT $${idx++} OFFSET $${idx}`,
      params
    );

    // Return all raw fields (for admin panel) plus localized convenience fields
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
      sleepingTipsEn, sleepingTipsAm, sleepingTipsOr, sleepingTipsSo,
      // Accept tipsEn/Am/Or/So as aliases for sleepingTipsEn/Am/Or/So
      tipsEn, tipsAm, tipsOr, tipsSo,
      // titleEn/Am/Or/So accepted for compatibility (not stored, ignored)
      titleEn, titleAm, titleOr, titleSo
    } = req.body;

    // Prefer explicit sleepingTips* fields, fall back to tips* aliases
    const finalTipsEn = sleepingTipsEn || tipsEn;
    const finalTipsAm = sleepingTipsAm || tipsAm;
    const finalTipsOr = sleepingTipsOr || tipsOr;
    const finalTipsSo = sleepingTipsSo || tipsSo;

    const result = await query(
      `INSERT INTO sleep_weeks (
        trimester, month, week,
        why_important_en, why_important_am, why_important_or, why_important_so,
        sleeping_tips_en, sleeping_tips_am, sleeping_tips_or, sleeping_tips_so
      ) VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11) RETURNING *`,
      [
        trimester, month, week,
        whyImportantEn, whyImportantAm, whyImportantOr, whyImportantSo,
        finalTipsEn, finalTipsAm, finalTipsOr, finalTipsSo
      ]
    );

    return sendSuccess(res, 201, 'Sleep week entry created', result.rows[0]);
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
      sleepingTipsEn: 'sleeping_tips_en', sleepingTipsAm: 'sleeping_tips_am',
      sleepingTipsOr: 'sleeping_tips_or', sleepingTipsSo: 'sleeping_tips_so',
      // Accept tipsEn/Am/Or/So as aliases
      tipsEn: 'sleeping_tips_en', tipsAm: 'sleeping_tips_am',
      tipsOr: 'sleeping_tips_or', tipsSo: 'sleeping_tips_so',
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
    const result = await query(`UPDATE sleep_weeks SET ${updates.join(', ')} WHERE id = $${idx} RETURNING *`, values);
    if (result.rows.length === 0) return sendError(res, 404, 'Sleep week entry not found.');
    return sendSuccess(res, 200, 'Sleep week updated', result.rows[0]);
  } catch (err) {
    next(err);
  }
};

exports.remove = async (req, res, next) => {
  try {
    const result = await query('DELETE FROM sleep_weeks WHERE id = $1 RETURNING id', [req.params.id]);
    if (result.rows.length === 0) return sendError(res, 404, 'Sleep week entry not found.');
    return sendSuccess(res, 200, 'Sleep week deleted');
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
    // Raw multilingual fields (for admin panel)
    why_important_en: item.why_important_en || '',
    why_important_am: item.why_important_am || '',
    why_important_or: item.why_important_or || '',
    why_important_so: item.why_important_so || '',
    whyImportantEn: item.why_important_en || '',
    whyImportantAm: item.why_important_am || '',
    whyImportantOr: item.why_important_or || '',
    whyImportantSo: item.why_important_so || '',
    sleeping_tips_en: item.sleeping_tips_en || '',
    sleeping_tips_am: item.sleeping_tips_am || '',
    sleeping_tips_or: item.sleeping_tips_or || '',
    sleeping_tips_so: item.sleeping_tips_so || '',
    tipsEn: item.sleeping_tips_en || '',
    tipsAm: item.sleeping_tips_am || '',
    tipsOr: item.sleeping_tips_or || '',
    tipsSo: item.sleeping_tips_so || '',
    // Localized convenience fields
    why_important: item[`why_important_${l}`] || item.why_important_en || '',
    sleeping_tips: item[`sleeping_tips_${l}`] || item.sleeping_tips_en || ''
  };
}
const { query } = require('../config/db');
const { sendSuccess, sendError, sendPaginated } = require('../utils/apiResponse');
const { normalizeLang } = require('../utils/normalizeLang');

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
      whyImportantEn, whyImportantAm, whyImportantOr, whyImportantOm, whyImportantSo,
      sleepingTipsEn, sleepingTipsAm, sleepingTipsOr, sleepingTipsOm, sleepingTipsSo,
      // Accept tipsEn/Am/Or/So as aliases for sleepingTipsEn/Am/Or/So
      tipsEn, tipsAm, tipsOr, tipsOm, tipsSo,
      // titleEn/Am/Or/So accepted for compatibility (not stored, ignored)
      titleEn, titleAm, titleOr, titleSo
    } = req.body;

    // Prefer explicit sleepingTips* fields, fall back to tips* aliases
    const finalTipsEn = sleepingTipsEn || tipsEn;
    const finalTipsAm = sleepingTipsAm || tipsAm;
    const finalTipsOm = sleepingTipsOm || tipsOm || sleepingTipsOr || tipsOr;
    const finalTipsSo = sleepingTipsSo || tipsSo;

    const finalWhyOm = whyImportantOm ?? whyImportantOr;

    const result = await query(
      `INSERT INTO sleep_weeks (
        trimester, month, week,
        why_important_en, why_important_am, why_important_om, why_important_so,
        sleeping_tips_en, sleeping_tips_am, sleeping_tips_om, sleeping_tips_so
      ) VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11) RETURNING *`,
      [
        trimester, month, week,
        whyImportantEn, whyImportantAm, finalWhyOm, whyImportantSo,
        finalTipsEn, finalTipsAm, finalTipsOm, finalTipsSo
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
      whyImportantSo: 'why_important_so',
      whyImportantOr: 'why_important_om', whyImportantOm: 'why_important_om',
      sleepingTipsEn: 'sleeping_tips_en', sleepingTipsAm: 'sleeping_tips_am',
      sleepingTipsSo: 'sleeping_tips_so',
      sleepingTipsOr: 'sleeping_tips_om', sleepingTipsOm: 'sleeping_tips_om',
      // Accept tipsEn/Am/Or/So as aliases
      tipsEn: 'sleeping_tips_en', tipsAm: 'sleeping_tips_am',
      tipsSo: 'sleeping_tips_so',
      tipsOr: 'sleeping_tips_om', tipsOm: 'sleeping_tips_om',
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
  const L = ['en', 'am', 'om', 'so'];
  const l = L.includes(normalizeLang(lang)) ? normalizeLang(lang) : 'en';
  return {
    id: item.id,
    trimester: item.trimester,
    month: item.month,
    week: item.week,
    is_published: item.is_published,
    isPublished: item.is_published,
    // Raw multilingual fields (for admin panel) — _om canonical, _or legacy alias
    why_important_en: item.why_important_en || '',
    why_important_am: item.why_important_am || '',
    why_important_om: item.why_important_om || '',
    why_important_so: item.why_important_so || '',
    why_important_or: item.why_important_om || '',
    whyImportantEn: item.why_important_en || '',
    whyImportantAm: item.why_important_am || '',
    whyImportantOm: item.why_important_om || '',
    whyImportantSo: item.why_important_so || '',
    whyImportantOr: item.why_important_om || '',
    sleeping_tips_en: item.sleeping_tips_en || '',
    sleeping_tips_am: item.sleeping_tips_am || '',
    sleeping_tips_om: item.sleeping_tips_om || '',
    sleeping_tips_so: item.sleeping_tips_so || '',
    sleeping_tips_or: item.sleeping_tips_om || '',
    tipsEn: item.sleeping_tips_en || '',
    tipsAm: item.sleeping_tips_am || '',
    tipsOm: item.sleeping_tips_om || '',
    tipsSo: item.sleeping_tips_so || '',
    tipsOr: item.sleeping_tips_om || '',
    // Localized convenience fields
    why_important: item[`why_important_${l}`] || item.why_important_en || '',
    sleeping_tips: item[`sleeping_tips_${l}`] || item.sleeping_tips_en || ''
  };
}
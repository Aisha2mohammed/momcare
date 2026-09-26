const { query } = require('../config/db');
const { sendSuccess, sendError, sendPaginated } = require('../utils/apiResponse');
const { normalizeLang } = require('../utils/normalizeLang');

const LANGS = ['en', 'am', 'om', 'so'];
const TRIMESTER_MAP = { '1st': 1, '2nd': 2, '3rd': 3 };

const toTrimester = (value) => {
  if (value === undefined || value === null || value === '') return 0;
  if (typeof value === 'number') return value;
  return TRIMESTER_MAP[String(value).toLowerCase()] !== undefined
    ? TRIMESTER_MAP[String(value).toLowerCase()]
    : Number(value);
};

const pickOm = (omVal, orVal) => (omVal !== undefined ? omVal : orVal);

exports.getAll = async (req, res, next) => {
  try {
    const { trimester, lang = 'en', page = 1, limit = 20 } = req.query;
    let whereClause = 'WHERE 1=1';
    const params = [];
    let idx = 1;

    if (trimester !== undefined) {
      whereClause += ` AND (st.trimester = $${idx} OR st.trimester = 0)`;
      params.push(Number(trimester));
      idx++;
    }

    const countResult = await query(`SELECT COUNT(*) FROM sleep_tips st ${whereClause}`, params);
    const total = parseInt(countResult.rows[0].count, 10);

    const offset = (Number(page) - 1) * Number(limit);
    params.push(Number(limit), offset);

    const result = await query(
      `SELECT * FROM sleep_tips st ${whereClause} ORDER BY st.trimester, st.id LIMIT $${idx++} OFFSET $${idx}`,
      params
    );

    const localized = result.rows.map(row => localize(row, lang));
    return sendPaginated(res, localized, page, limit, total);
  } catch (err) {
    next(err);
  }
};

exports.getOne = async (req, res, next) => {
  try {
    const { lang = 'en' } = req.query;
    const result = await query('SELECT * FROM sleep_tips WHERE id = $1', [req.params.id]);
    if (result.rows.length === 0) return sendError(res, 404, 'Sleep tip not found.');
    return sendSuccess(res, 200, 'Sleep tip retrieved', localize(result.rows[0], lang));
  } catch (err) {
    next(err);
  }
};

exports.create = async (req, res, next) => {
  try {
    const body = req.body || {};
    const trimester = toTrimester(body.trimester);
    const week = body.week !== undefined ? body.week : null;
    const month = body.month !== undefined ? body.month : null;
    const type = body.type || 'generic';
    const illustrationUrl = body.illustrationUrl || null;

    const titleEn = body.titleEn || '';
    const titleAm = body.titleAm || '';
    const titleSo = body.titleSo || '';
    const titleOm = pickOm(body.titleOm, body.titleOr);

    const descriptionEn = pickOm(body.descriptionEn, body.bodyEn) || '';
    const descriptionAm = pickOm(body.descriptionAm, body.bodyAm) || '';
    const descriptionSo = pickOm(body.descriptionSo, body.bodySo) || '';
    const descriptionOm = pickOm(
      body.descriptionOm,
      pickOm(body.bodyOm, pickOm(body.descriptionOr, body.bodyOr))
    );

    const whyImportantEn = body.whyImportantEn || '';
    const whyImportantAm = body.whyImportantAm || '';
    const whyImportantSo = body.whyImportantSo || '';
    const whyImportantOm = pickOm(body.whyImportantOm, body.whyImportantOr);

    const tipsEn = body.tipsEn || '';
    const tipsAm = body.tipsAm || '';
    const tipsSo = body.tipsSo || '';
    const tipsOm = pickOm(body.tipsOm, body.tipsOr);

    let sectionsJson = null;
    if (body.sectionsJson) {
      sectionsJson = typeof body.sectionsJson === 'string' ? body.sectionsJson : JSON.stringify(body.sectionsJson);
    }

    const result = await query(
      `INSERT INTO sleep_tips (
        trimester, week, month, type, illustration_url,
        title_en, title_am, title_om, title_so,
        description_en, description_am, description_om, description_so,
        why_important_en, why_important_am, why_important_om, why_important_so,
        tips_en, tips_am, tips_om, tips_so,
        sections_json
      ) VALUES (
        $1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15,$16,$17,$18,$19,$20,$21,$22
      ) RETURNING *`,
      [
        trimester, week, month, type, illustrationUrl,
        titleEn, titleAm, titleOm, titleSo,
        descriptionEn, descriptionAm, descriptionOm, descriptionSo,
        whyImportantEn, whyImportantAm, whyImportantOm, whyImportantSo,
        tipsEn, tipsAm, tipsOm, tipsSo,
        sectionsJson
      ]
    );

    return sendSuccess(res, 201, 'Sleep tip created', result.rows[0]);
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
  const L = normalizeLang(lang);
  const l = LANGS.includes(L) ? L : 'en';
  const omValue = (base) => {
    const v = item[`${base}_${l}`] || item[`${base}_en`] || '';
    return v;
  };

  let sections = item.sections_json || [];
  if (typeof sections === 'string') {
    try { sections = JSON.parse(sections); } catch { sections = []; }
  }

  return {
    id: item.id,
    trimester: item.trimester,
    week: item.week,
    month: item.month,
    type: item.type,
    illustration_url: item.illustration_url || '',
    title: omValue('title'),
    description: omValue('description'),
    why_important: omValue('why_important'),
    tips: omValue('tips'),
    sections_json: sections,
    title_en: item.title_en || '',
    title_am: item.title_am || '',
    title_om: item.title_om || '',
    title_so: item.title_so || '',
    title_or: item.title_om || '',
    description_en: item.description_en || '',
    description_am: item.description_am || '',
    description_om: item.description_om || '',
    description_so: item.description_so || '',
    description_or: item.description_om || '',
    body_en: item.description_en || '',
    body_am: item.description_am || '',
    body_om: item.description_om || '',
    body_so: item.description_so || '',
    body_or: item.description_om || '',
    why_important_en: item.why_important_en || '',
    why_important_am: item.why_important_am || '',
    why_important_om: item.why_important_om || '',
    why_important_so: item.why_important_so || '',
    why_important_or: item.why_important_om || '',
    tips_en: item.tips_en || '',
    tips_am: item.tips_am || '',
    tips_om: item.tips_om || '',
    tips_so: item.tips_so || '',
    tips_or: item.tips_om || ''
  };
}

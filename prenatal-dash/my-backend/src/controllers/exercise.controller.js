const { query } = require('../config/db');
const { sendSuccess, sendError, sendPaginated } = require('../utils/apiResponse');
const { normalizeLang } = require('../utils/normalizeLang');

const LANGS = ['en', 'am', 'om', 'so'];

exports.getAll = async (req, res, next) => {
  try {
    const { trimester, lang = 'en', page = 1, limit = 20 } = req.query;
    let whereClause = 'WHERE 1=1';
    const params = [];
    let idx = 1;

    if (trimester !== undefined) {
      whereClause += ` AND trimester = $${idx++}`;
      params.push(Number(trimester));
    }

    const countResult = await query(`SELECT COUNT(*) FROM exercises ${whereClause}`, params);
    const total = parseInt(countResult.rows[0].count, 10);

    const offset = (Number(page) - 1) * Number(limit);
    params.push(Number(limit), offset);

    const result = await query(
      `SELECT * FROM exercises ${whereClause} ORDER BY trimester, id LIMIT $${idx++} OFFSET $${idx}`,
      params
    );

    const localized = result.rows.map(row => localize(row, lang));
    return sendPaginated(res, localized, page, limit, total);
  } catch (err) {
    next(err);
  }
};

exports.create = async (req, res, next) => {
  try {
    const {
      trimester, category = 'other', durationMinutes, imageUrl, videoUrl, isPublished = true,
      titleEn, titleAm, titleOr, titleOm, titleSo,
      descriptionEn, descriptionAm, descriptionOr, descriptionOm, descriptionSo,
      descriptionLabelEn, descriptionLabelAm, descriptionLabelOr, descriptionLabelOm, descriptionLabelSo,
      descriptionValueEn, descriptionValueAm, descriptionValueOr, descriptionValueOm, descriptionValueSo,
      whyImportantEn, whyImportantAm, whyImportantOr, whyImportantOm, whyImportantSo,
      healthTips = [], listOfExercise = []
    } = req.body;

    const pickOm = (omVal, orVal) => (omVal !== undefined ? omVal : orVal);
    const finalTitleOm = pickOm(titleOm, titleOr);
    const finalDescriptionOm = pickOm(descriptionOm, descriptionOr);
    const finalDescriptionLabelOm = pickOm(descriptionLabelOm, descriptionLabelOr);
    const finalDescriptionValueOm = pickOm(descriptionValueOm, descriptionValueOr);
    const finalWhyImportantOm = pickOm(whyImportantOm, whyImportantOr);

    const result = await query(
      `INSERT INTO exercises (
        trimester, category, duration_minutes, image_url, video_url, is_published,
        title_en, title_am, title_om, title_so,
        description_en, description_am, description_om, description_so,
        description_label_en, description_label_am, description_label_om, description_label_so,
        description_value_en, description_value_am, description_value_om, description_value_so,
        why_important_en, why_important_am, why_important_om, why_important_so,
        health_tips, list_of_exercise
      ) VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15,$16,$17,$18,$19,$20,$21,$22,$23,$24,$25,$26,$27,$28) RETURNING *`,
      [
        trimester, category, durationMinutes, imageUrl, videoUrl, isPublished,
        titleEn, titleAm, finalTitleOm, titleSo,
        descriptionEn, descriptionAm, finalDescriptionOm, descriptionSo,
        descriptionLabelEn, descriptionLabelAm, finalDescriptionLabelOm, descriptionLabelSo,
        descriptionValueEn, descriptionValueAm, finalDescriptionValueOm, descriptionValueSo,
        whyImportantEn, whyImportantAm, finalWhyImportantOm, whyImportantSo,
        JSON.stringify(healthTips), JSON.stringify(listOfExercise)
      ]
    );

    return sendSuccess(res, 201, 'Exercise created', result.rows[0]);
  } catch (err) {
    next(err);
  }
};

exports.update = async (req, res, next) => {
  try {
    const {
      trimester, category = 'other', durationMinutes, imageUrl, videoUrl, isPublished = true,
      titleEn, titleAm, titleOr, titleOm, titleSo,
      descriptionEn, descriptionAm, descriptionOr, descriptionOm, descriptionSo,
      descriptionLabelEn, descriptionLabelAm, descriptionLabelOr, descriptionLabelOm, descriptionLabelSo,
      descriptionValueEn, descriptionValueAm, descriptionValueOr, descriptionValueOm, descriptionValueSo,
      whyImportantEn, whyImportantAm, whyImportantOr, whyImportantOm, whyImportantSo,
      healthTips = [], listOfExercise = []
    } = req.body;

    // Canonical _om columns accept both *Or (legacy) and *Om (canonical) body keys
    const pickOm = (omVal, orVal) => (omVal !== undefined ? omVal : orVal);
    const finalTitleOm = pickOm(titleOm, titleOr);
    const finalDescriptionOm = pickOm(descriptionOm, descriptionOr);
    const finalDescriptionLabelOm = pickOm(descriptionLabelOm, descriptionLabelOr);
    const finalDescriptionValueOm = pickOm(descriptionValueOm, descriptionValueOr);
    const finalWhyImportantOm = pickOm(whyImportantOm, whyImportantOr);

    const result = await query(
      `UPDATE exercises SET
        trimester = $1, category = $2, duration_minutes = $3, image_url = $4, video_url = $5, is_published = $6,
        title_en = $7, title_am = $8, title_om = $9, title_so = $10,
        description_en = $11, description_am = $12, description_om = $13, description_so = $14,
        description_label_en = $15, description_label_am = $16, description_label_om = $17, description_label_so = $18,
        description_value_en = $19, description_value_am = $20, description_value_om = $21, description_value_so = $22,
        why_important_en = $23, why_important_am = $24, why_important_om = $25, why_important_so = $26,
        health_tips = $27, list_of_exercise = $28
      WHERE id = $29 RETURNING *`,
      [
        trimester, category, durationMinutes, imageUrl, videoUrl, isPublished,
        titleEn, titleAm, finalTitleOm, titleSo,
        descriptionEn, descriptionAm, finalDescriptionOm, descriptionSo,
        descriptionLabelEn, descriptionLabelAm, finalDescriptionLabelOm, descriptionLabelSo,
        descriptionValueEn, descriptionValueAm, finalDescriptionValueOm, descriptionValueSo,
        whyImportantEn, whyImportantAm, finalWhyImportantOm, whyImportantSo,
        JSON.stringify(healthTips), JSON.stringify(listOfExercise),
        req.params.id
      ]
    );

    if (result.rows.length === 0) return sendError(res, 404, 'Exercise not found');
    return sendSuccess(res, 200, 'Exercise updated', result.rows[0]);
  } catch (err) {
    next(err);
  }
};

exports.remove = async (req, res, next) => {
  try {
    const result = await query('DELETE FROM exercises WHERE id = $1 RETURNING id', [req.params.id]);
    if (result.rows.length === 0) return sendError(res, 404, 'Exercise not found');
    return sendSuccess(res, 200, 'Exercise deleted', { id: req.params.id });
  } catch (err) {
    next(err);
  }
};

function localize(item, lang) {
  const L = normalizeLang(lang);
  const l = LANGS.includes(L) ? L : 'en';
  return {
    id: item.id,
    trimester: item.trimester,
    category: item.category,
    duration_minutes: item.duration_minutes,
    is_published: item.is_published,
    isPublished: item.is_published,
    image_url: item.image_url,
    imageUrl: item.image_url,
    video_url: item.video_url,
    videoUrl: item.video_url,
    // Localized convenience fields
    title: item[`title_${l}`] || item.title_en || '',
    description: item[`description_${l}`] || item.description_en || '',
    description_label: item[`description_label_${l}`] || item.description_label_en || '',
    description_value: item[`description_value_${l}`] || item.description_value_en || '',
    why_important: item[`why_important_${l}`] || item.why_important_en || '',

    // Raw multilingual fields (REQUIRED for admin panel edit forms)
    title_en: item.title_en || '',
    title_am: item.title_am || '',
    title_or: item.title_om || '',
    title_so: item.title_so || '',

    description_en: item.description_en || '',
    description_am: item.description_am || '',
    description_or: item.description_om || '',
    description_so: item.description_so || '',

    description_label_en: item.description_label_en || '',
    description_label_am: item.description_label_am || '',
    description_label_or: item.description_label_om || '',
    description_label_so: item.description_label_so || '',

    description_value_en: item.description_value_en || '',
    description_value_am: item.description_value_am || '',
    description_value_or: item.description_value_om || '',
    description_value_so: item.description_value_so || '',

    why_important_en: item.why_important_en || '',
    why_important_am: item.why_important_am || '',
    why_important_or: item.why_important_om || '',
    why_important_so: item.why_important_so || '',

    // Raw JSON arrays for admin editing
    health_tips: item.health_tips || [],
    list_of_exercise: item.list_of_exercise || [],
  };
}
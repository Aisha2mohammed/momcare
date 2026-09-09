const { query } = require('../config/db');
const { sendSuccess, sendError, sendPaginated } = require('../utils/apiResponse');

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
      titleEn, titleAm, titleOr, titleSo,
      descriptionEn, descriptionAm, descriptionOr, descriptionSo,
      descriptionLabelEn, descriptionLabelAm, descriptionLabelOr, descriptionLabelSo,
      descriptionValueEn, descriptionValueAm, descriptionValueOr, descriptionValueSo,
      whyImportantEn, whyImportantAm, whyImportantOr, whyImportantSo,
      healthTips = [], listOfExercise = []
    } = req.body;

    const result = await query(
      `INSERT INTO exercises (
        trimester, category, duration_minutes, image_url, video_url, is_published,
        title_en, title_am, title_or, title_so,
        description_en, description_am, description_or, description_so,
        description_label_en, description_label_am, description_label_or, description_label_so,
        description_value_en, description_value_am, description_value_or, description_value_so,
        why_important_en, why_important_am, why_important_or, why_important_so,
        health_tips, list_of_exercise
      ) VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15,$16,$17,$18,$19,$20,$21,$22,$23,$24,$25,$26,$27) RETURNING *`,
      [
        trimester, category, durationMinutes, imageUrl, videoUrl, isPublished,
        titleEn, titleAm, titleOr, titleSo,
        descriptionEn, descriptionAm, descriptionOr, descriptionSo,
        descriptionLabelEn, descriptionLabelAm, descriptionLabelOr, descriptionLabelSo,
        descriptionValueEn, descriptionValueAm, descriptionValueOr, descriptionValueSo,
        whyImportantEn, whyImportantAm, whyImportantOr, whyImportantSo,
        JSON.stringify(healthTips), JSON.stringify(listOfExercise)
      ]
    );

    return sendSuccess(res, 201, 'Exercise created', result.rows[0]);
  } catch (err) {
    next(err);
  }
};

function localize(item, lang) {
  const l = ['en', 'am', 'or', 'so'].includes(lang) ? lang : 'en';
  return {
    id: item.id,
    trimester: item.trimester,
    category: item.category,
    duration_minutes: item.duration_minutes,
    image_url: item.image_url,
    video_url: item.video_url,
    title: item[`title_${l}`] || item.title_en || '',
    description: item[`description_${l}`] || item.description_en || '',
    why_important: item[`why_important_${l}`] || item.why_important_en || '',
    health_tips: item.health_tips || [],
    list_of_exercise: item.list_of_exercise || []
  };
}
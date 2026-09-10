const { query } = require('../config/db');
const { sendSuccess, sendError, sendPaginated } = require('../utils/apiResponse');

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
    const {
      trimester = 0, position = 'other', illustrationUrl, isPublished = true,
      titleEn, titleAm, titleOr, titleSo,
      descriptionEn, descriptionAm, descriptionOr, descriptionSo,
      descriptionLabelEn, descriptionLabelAm, descriptionLabelOr, descriptionLabelSo,
      descriptionValueEn, descriptionValueAm, descriptionValueOr, descriptionValueSo,
      whyImportantEn, whyImportantAm, whyImportantOr, whyImportantSo,
      healthTips = [], listSleep = []
    } = req.body;

    const result = await query(
      `INSERT INTO sleep_tips (
        trimester, position, illustration_url, is_published,
        title_en, title_am, title_or, title_so,
        description_en, description_am, description_or, description_so,
        description_label_en, description_label_am, description_label_or, description_label_so,
        description_value_en, description_value_am, description_value_or, description_value_so,
        why_important_en, why_important_am, why_important_or, why_important_so,
        health_tips, list_sleep
      ) VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15,$16,$17,$18,$19,$20,$21,$22,$23,$24,$25,$26) RETURNING *`,
      [
        trimester, position, illustrationUrl, isPublished,
        titleEn, titleAm, titleOr, titleSo,
        descriptionEn, descriptionAm, descriptionOr, descriptionSo,
        descriptionLabelEn, descriptionLabelAm, descriptionLabelOr, descriptionLabelSo,
        descriptionValueEn, descriptionValueAm, descriptionValueOr, descriptionValueSo,
        whyImportantEn, whyImportantAm, whyImportantOr, whyImportantSo,
        JSON.stringify(healthTips), JSON.stringify(listSleep)
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
  const supportedLangs = ['en', 'am', 'or', 'so'];
  const l = supportedLangs.includes(lang) ? lang : 'en';

  return {
    id: item.id,
    trimester: item.trimester,
    position: item.position,
    illustration_url: item.illustration_url,
    is_published: item.is_published,
    title: item[`title_${l}`] || item.title_en || '',
    description: item[`description_${l}`] || item.description_en || '',
    description_label: item[`description_label_${l}`] || item.description_label_en || '',
    description_value: item[`description_value_${l}`] || item.description_value_en || '',
    why_important: item[`why_important_${l}`] || item.why_important_en || '',
    health_tips: item.health_tips || [],
    list_sleep: item.list_sleep || []
  };
}
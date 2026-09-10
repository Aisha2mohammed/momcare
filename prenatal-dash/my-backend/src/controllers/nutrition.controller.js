const { query } = require('../config/db');
const { sendSuccess, sendError, sendPaginated } = require('../utils/apiResponse');

exports.getAll = async (req, res, next) => {
  try {
    const { lang = 'en', page = 1, limit = 20 } = req.query;
    const countResult = await query(`SELECT COUNT(*) FROM nutrition_tips`);
    const total = parseInt(countResult.rows[0].count, 10);

    const offset = (Number(page) - 1) * Number(limit);
    const result = await query(
      `SELECT * FROM nutrition_tips ORDER BY id DESC LIMIT $1 OFFSET $2`,
      [Number(limit), offset]
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
      imageUrl, titleEn, titleAm, titleOr, titleSo,
      descriptionEn, descriptionAm, descriptionOr, descriptionSo,
      descriptionLabelEn, descriptionLabelAm, descriptionLabelOr, descriptionLabelSo,
      descriptionValueEn, descriptionValueAm, descriptionValueOr, descriptionValueSo,
      whyImportantEn, whyImportantAm, whyImportantOr, whyImportantSo,
      healthTips = [], listFood = []
    } = req.body;

    const result = await query(
      `INSERT INTO nutrition_tips (
        image_url, title_en, title_am, title_or, title_so,
        description_en, description_am, description_or, description_so,
        description_label_en, description_label_am, description_label_or, description_label_so,
        description_value_en, description_value_am, description_value_or, description_value_so,
        why_important_en, why_important_am, why_important_or, why_important_so,
        health_tips, list_food
      ) VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15,$16,$17,$18,$19,$20,$21,$22,$23) RETURNING *`,
      [
        imageUrl, titleEn, titleAm, titleOr, titleSo,
        descriptionEn, descriptionAm, descriptionOr, descriptionSo,
        descriptionLabelEn, descriptionLabelAm, descriptionLabelOr, descriptionLabelSo,
        descriptionValueEn, descriptionValueAm, descriptionValueOr, descriptionValueSo,
        whyImportantEn, whyImportantAm, whyImportantOr, whyImportantSo,
        JSON.stringify(healthTips), JSON.stringify(listFood)
      ]
    );

    return sendSuccess(res, 201, 'Nutrition tip created', result.rows[0]);
  } catch (err) {
    next(err);
  }
};

function localize(item, lang) {
  const l = ['en', 'am', 'or', 'so'].includes(lang) ? lang : 'en';
  return {
    id: item.id,
    image_url: item.image_url,
    title: item[`title_${l}`] || item.title_en || '',
    description: item[`description_${l}`] || item.description_en || '',
    description_label: item[`description_label_${l}`] || item.description_label_en || '',
    description_value: item[`description_value_${l}`] || item.description_value_en || '',
    why_important: item[`why_important_${l}`] || item.why_important_en || '',
    health_tips: item.health_tips || [],
    list_food: item.list_food || []
  };
}
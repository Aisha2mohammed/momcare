const { query } = require('../config/db');
const { sendSuccess, sendError, sendPaginated } = require('../utils/apiResponse');
const { normalizeLang } = require('../utils/normalizeLang');

const LANGS = ['en', 'am', 'om', 'so'];
const VALID_TYPES = ['eat', 'avoid'];
const VALID_MEDIA_TYPES = ['upload', 'url'];

exports.getAll = async (req, res, next) => {
  try {
    const { lang = 'en', page = 1, limit = 20, type, trimester, week, month, nutritionWeekId } = req.query;

    const conditions = [];
    const params = [];

    if (type && VALID_TYPES.includes(type)) {
      params.push(type);
      conditions.push(`nt.type = $${params.length}`);
    }
    if (nutritionWeekId) {
      params.push(Number(nutritionWeekId));
      conditions.push(`nt.nutrition_week_id = $${params.length}`);
    }
    if (trimester) {
      params.push(Number(trimester));
      conditions.push(`nw.trimester = $${params.length}`);
    }
    if (week) {
      params.push(Number(week));
      conditions.push(`nw.week = $${params.length}`);
    }
    if (month) {
      params.push(Number(month));
      conditions.push(`nw.month = $${params.length}`);
    }

    const where = conditions.length ? `WHERE ${conditions.join(' AND ')}` : '';

    const countResult = await query(
      `SELECT COUNT(*) FROM nutrition_tips nt
       LEFT JOIN nutrition_weeks nw ON nw.id = nt.nutrition_week_id
       ${where}`,
      params
    );
    const total = parseInt(countResult.rows[0].count, 10);

    const offset = (Number(page) - 1) * Number(limit);
    const listParams = [...params, Number(limit), offset];
    const result = await query(
      `SELECT nt.*, nw.trimester, nw.month, nw.week,
              nw.hydration_en, nw.hydration_am, nw.hydration_om, nw.hydration_so
       FROM nutrition_tips nt
       LEFT JOIN nutrition_weeks nw ON nw.id = nt.nutrition_week_id
       ${where}
       ORDER BY nt.id DESC LIMIT $${params.length + 1} OFFSET $${params.length + 2}`,
      listParams
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
    const { id } = req.params;

    const result = await query(
      `SELECT nt.*, nw.trimester, nw.month, nw.week,
              nw.hydration_en, nw.hydration_am, nw.hydration_om, nw.hydration_so
       FROM nutrition_tips nt
       LEFT JOIN nutrition_weeks nw ON nw.id = nt.nutrition_week_id
       WHERE nt.id = $1`,
      [id]
    );
    if (result.rows.length === 0) {
      return sendError(res, 404, 'Nutrition tip not found');
    }

    return sendSuccess(res, 200, 'Nutrition tip fetched', localize(result.rows[0], lang));
  } catch (err) {
    next(err);
  }
};

exports.create = async (req, res, next) => {
  try {
    const {
      type, nutritionWeekId,
      imageUrl, titleEn, titleAm, titleOr, titleOm, titleSo,
      descriptionEn, descriptionAm, descriptionOr, descriptionOm, descriptionSo,
      descriptionLabelEn, descriptionLabelAm, descriptionLabelOr, descriptionLabelOm, descriptionLabelSo,
      descriptionValueEn, descriptionValueAm, descriptionValueOr, descriptionValueOm, descriptionValueSo,
      whyImportantEn, whyImportantAm, whyImportantOr, whyImportantOm, whyImportantSo,
      healthTips = [], listFood = []
    } = req.body;

    // Canonical _om columns accept both *Or (legacy) and *Om (canonical) body keys
    const pickOm = (omVal, orVal) => (omVal !== undefined ? omVal : orVal);
    const finalTitleOm = pickOm(titleOm, titleOr);
    const finalDescriptionOm = pickOm(descriptionOm, descriptionOr);
    const finalDescriptionLabelOm = pickOm(descriptionLabelOm, descriptionLabelOr);
    const finalDescriptionValueOm = pickOm(descriptionValueOm, descriptionValueOr);
    const finalWhyImportantOm = pickOm(whyImportantOm, whyImportantOr);

    if (nutritionWeekId) {
      const weekCheck = await query(`SELECT id FROM nutrition_weeks WHERE id = $1`, [nutritionWeekId]);
      if (weekCheck.rows.length === 0) {
        return sendError(res, 400, 'Invalid nutritionWeekId — no matching week/month/trimester found');
      }
    }

    const normalizedType = VALID_TYPES.includes(type) ? type : 'eat';
    const normalizedHealthTips = normalizeHealthTips(parseIfString(healthTips));
    const normalizedListFood = normalizeListFood(parseIfString(listFood));

    const result = await query(
      `INSERT INTO nutrition_tips (
        type, nutrition_week_id, image_url,
        title_en, title_am, title_om, title_so,
        description_en, description_am, description_om, description_so,
        description_label_en, description_label_am, description_label_om, description_label_so,
        description_value_en, description_value_am, description_value_om, description_value_so,
        why_important_en, why_important_am, why_important_om, why_important_so,
        health_tips, list_food
      ) VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15,$16,$17,$18,$19,$20,$21,$22,$23,$24,$25)
      RETURNING *`,
      [
        normalizedType, nutritionWeekId || null, imageUrl,
        titleEn, titleAm, finalTitleOm, titleSo,
        descriptionEn, descriptionAm, finalDescriptionOm, descriptionSo,
        descriptionLabelEn, descriptionLabelAm, finalDescriptionLabelOm, descriptionLabelSo,
        descriptionValueEn, descriptionValueAm, finalDescriptionValueOm, descriptionValueSo,
        whyImportantEn, whyImportantAm, finalWhyImportantOm, whyImportantSo,
        JSON.stringify(normalizedHealthTips), JSON.stringify(normalizedListFood)
      ]
    );

    return sendSuccess(res, 201, 'Nutrition tip created', result.rows[0]);
  } catch (err) {
    next(err);
  }
};

exports.update = async (req, res, next) => {
  try {
    const { id } = req.params;
    const {
      type, nutritionWeekId,
      imageUrl, titleEn, titleAm, titleOr, titleOm, titleSo,
      descriptionEn, descriptionAm, descriptionOr, descriptionOm, descriptionSo,
      descriptionLabelEn, descriptionLabelAm, descriptionLabelOr, descriptionLabelOm, descriptionLabelSo,
      descriptionValueEn, descriptionValueAm, descriptionValueOr, descriptionValueOm, descriptionValueSo,
      whyImportantEn, whyImportantAm, whyImportantOr, whyImportantOm, whyImportantSo,
      healthTips = [], listFood = []
    } = req.body;

    const pickOm = (omVal, orVal) => (omVal !== undefined ? omVal : orVal);
    const finalTitleOm = pickOm(titleOm, titleOr);
    const finalDescriptionOm = pickOm(descriptionOm, descriptionOr);
    const finalDescriptionLabelOm = pickOm(descriptionLabelOm, descriptionLabelOr);
    const finalDescriptionValueOm = pickOm(descriptionValueOm, descriptionValueOr);
    const finalWhyImportantOm = pickOm(whyImportantOm, whyImportantOr);

    if (nutritionWeekId) {
      const weekCheck = await query(`SELECT id FROM nutrition_weeks WHERE id = $1`, [nutritionWeekId]);
      if (weekCheck.rows.length === 0) {
        return sendError(res, 400, 'Invalid nutritionWeekId — no matching week/month/trimester found');
      }
    }

    const normalizedType = VALID_TYPES.includes(type) ? type : 'eat';
    const normalizedHealthTips = normalizeHealthTips(parseIfString(healthTips));
    const normalizedListFood = normalizeListFood(parseIfString(listFood));

    const result = await query(
      `UPDATE nutrition_tips SET
        type = $1, nutrition_week_id = $2, image_url = $3,
        title_en = $4, title_am = $5, title_om = $6, title_so = $7,
        description_en = $8, description_am = $9, description_om = $10, description_so = $11,
        description_label_en = $12, description_label_am = $13, description_label_om = $14, description_label_so = $15,
        description_value_en = $16, description_value_am = $17, description_value_om = $18, description_value_so = $19,
        why_important_en = $20, why_important_am = $21, why_important_om = $22, why_important_so = $23,
        health_tips = $24, list_food = $25
      WHERE id = $26 RETURNING *`,
      [
        normalizedType, nutritionWeekId || null, imageUrl,
        titleEn, titleAm, finalTitleOm, titleSo,
        descriptionEn, descriptionAm, finalDescriptionOm, descriptionSo,
        descriptionLabelEn, descriptionLabelAm, finalDescriptionLabelOm, descriptionLabelSo,
        descriptionValueEn, descriptionValueAm, finalDescriptionValueOm, descriptionValueSo,
        whyImportantEn, whyImportantAm, finalWhyImportantOm, whyImportantSo,
        JSON.stringify(normalizedHealthTips), JSON.stringify(normalizedListFood),
        id
      ]
    );

    if (result.rows.length === 0) {
      return sendError(res, 404, 'Nutrition tip not found');
    }

    return sendSuccess(res, 200, 'Nutrition tip updated', result.rows[0]);
  } catch (err) {
    next(err);
  }
};

exports.remove = async (req, res, next) => {
  try {
    const { id } = req.params;
    const result = await query(`DELETE FROM nutrition_tips WHERE id = $1 RETURNING id`, [id]);

    if (result.rows.length === 0) {
      return sendError(res, 404, 'Nutrition tip not found');
    }

    return sendSuccess(res, 200, 'Nutrition tip deleted', { id });
  } catch (err) {
    next(err);
  }
};

/* ---------------------------------------------------
 * Helpers
 * ------------------------------------------------- */

// healthTips/listFood arrive as JSON strings when sent via multipart/form-data (file upload),
// but as real arrays/objects when sent via raw JSON (Postman "raw" body). Handle both.
function parseIfString(val) {
  if (typeof val === 'string') {
    try { return JSON.parse(val); } catch { return []; }
  }
  return val;
}

function pickLang(obj, lang) {
  if (!obj || typeof obj !== 'object') return '';
  return obj[lang] || obj.en || '';
}

function normalizeMultiLang(obj = {}) {
  const out = {};
  LANGS.forEach(l => { out[l] = obj?.[l] || ''; });
  return out;
}

function normalizeMedia(media) {
  if (!media || typeof media !== 'object' || !media.url) return null;
  return {
    type: VALID_MEDIA_TYPES.includes(media.type) ? media.type : 'url',
    url: media.url
  };
}

function normalizeHealthTips(healthTips) {
  if (!Array.isArray(healthTips)) return [];
  return healthTips.map(tip => ({
    label: normalizeMultiLang(tip.label)
  }));
}

function normalizeListFood(listFood) {
  if (!Array.isArray(listFood)) return [];
  return listFood.map(food => ({
    type: VALID_TYPES.includes(food.type) ? food.type : 'eat',
    name: normalizeMultiLang(food.name),
    description: normalizeMultiLang(food.description),
    label: normalizeMultiLang(food.label),
    image: normalizeMedia(food.image),
    video: normalizeMedia(food.video)
  }));
}

function localizeHealthTips(healthTips, lang) {
  if (!Array.isArray(healthTips)) return [];
  return healthTips.map(tip => ({
    label: pickLang(tip.label, lang)
  }));
}

function localizeListFood(listFood, lang) {
  if (!Array.isArray(listFood)) return [];
  return listFood.map((food, index) => ({
    index,
    type: food.type || 'eat',
    name: pickLang(food.name, lang),
    description: pickLang(food.description, lang),
    label: pickLang(food.label, lang),
    image: food.image || null,
    video: food.video || null
  }));
}

function localize(item, lang) {
  const L = normalizeLang(lang);
  const l = LANGS.includes(L) ? L : 'en';
  return {
    id: item.id,
    type: item.type || 'eat',
    nutrition_week_id: item.nutrition_week_id,
    trimester: item.trimester,
    month: item.month,
    week: item.week,
    image_url: item.image_url,
    imageUrl: item.image_url,
    // Localized convenience fields
    title: item[`title_${l}`] || item.title_en || '',
    description: item[`description_${l}`] || item.description_en || '',
    description_label: item[`description_label_${l}`] || item.description_label_en || '',
    description_value: item[`description_value_${l}`] || item.description_value_en || '',
    why_important: item[`why_important_${l}`] || item.why_important_en || '',
    hydration: item[`hydration_${l}`] || item.hydration_en || '',
    hydrationAm: item.hydration_am || '',
    hydrationOr: item.hydration_om || '',
    hydrationOm: item.hydration_om || '',
    hydrationSo: item.hydration_so || '',
    hydrationEn: item.hydration_en || '',
    hydration_am: item.hydration_am || '',
    hydration_or: item.hydration_om || '',
    hydration_om: item.hydration_om || '',
    hydration_so: item.hydration_so || '',
    hydration_en: item.hydration_en || '',
    health_tips: localizeHealthTips(item.health_tips, l),
    list_food: localizeListFood(item.list_food, l),
    // Convenience "sections" for mobile (renders food rows like nutrient sections)
    sections: localizeListFood(item.list_food, l).map(food => ({
      id: `sec-${food.index}`,
      nutrientType: item[`title_${l}`] || item.title_en || 'Nutrient',
      emoji: item.type === 'avoid' ? '🚫' : '🥗',
      titleEn: item.title_en || '',
      titleAm: item.title_am || '',
      titleOr: item.title_om || '',
      titleSo: item.title_so || '',
      bodyEn: item.description_en || '',
      bodyAm: item.description_am || '',
      bodyOr: item.description_om || '',
      bodySo: item.description_so || '',
      description: item[`description_${l}`] || item.description_en || '',
      foods: item.list_food || [],
      video_url: item.image_url || null,
    })),
    // Raw multilingual fields (for admin panel edit forms) — _om canonical, _or legacy alias
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
    description_label_en: item.description_label_en || '',
    description_label_am: item.description_label_am || '',
    description_label_om: item.description_label_om || '',
    description_label_so: item.description_label_so || '',
    description_label_or: item.description_label_om || '',
    description_value_en: item.description_value_en || '',
    description_value_am: item.description_value_am || '',
    description_value_om: item.description_value_om || '',
    description_value_so: item.description_value_so || '',
    description_value_or: item.description_value_om || '',
    why_important_en: item.why_important_en || '',
    why_important_am: item.why_important_am || '',
    why_important_om: item.why_important_om || '',
    why_important_so: item.why_important_so || '',
    why_important_or: item.why_important_om || '',
    // Raw JSON for admin (full multi-lang structure)
    health_tips_raw: item.health_tips,
    list_food_raw: item.list_food,
    is_published: item.is_published,
    isPublished: item.is_published,
  };
}
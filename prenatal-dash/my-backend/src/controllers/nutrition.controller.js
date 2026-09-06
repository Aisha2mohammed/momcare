const { query } = require('../config/db');
const { sendSuccess, sendError, sendPaginated } = require('../utils/apiResponse');

// Helper — safely parse a JSONB column
function parseJson(v) {
  if (!v) return null;
  if (typeof v === 'string') { try { return JSON.parse(v); } catch { return null; } }
  return v;
}

// ── GET /api/v1/nutrition ─────────────────────────────────────────────
exports.getAll = async (req, res, next) => {
  try {
    const { trimester, type, lang = 'am', page = 1, limit = 20 } = req.query;

    let whereClause = 'WHERE nc.is_published = true';
    const params = [];
    let paramIndex = 1;

    if (trimester) {
      whereClause += ` AND nc.trimester = $${paramIndex++}`;
      params.push(Number(trimester));
    }

    // Filter by type: 'eat' | 'avoid'
    if (type && (type === 'eat' || type === 'avoid')) {
      whereClause += ` AND nc.type = $${paramIndex++}`;
      params.push(type);
    }

    const countResult = await query(
      `SELECT COUNT(*) FROM nutrition_content nc ${whereClause}`,
      params
    );
    const total = parseInt(countResult.rows[0].count, 10);

    const offset = (Number(page) - 1) * Number(limit);
    params.push(Number(limit), offset);

    const result = await query(
      `SELECT id, trimester, week, type, emoji, nutrient_type,
              title_am, title_or, title_en,
              body_am, body_or, body_en,
              image_url, video_url, video_title,
              reason_am, reason_or, reason_en,
              foods_json, nutrient_sections_json,
              is_published, created_at
       FROM nutrition_content nc ${whereClause}
       ORDER BY nc.trimester, nc.created_at DESC
       LIMIT $${paramIndex++} OFFSET $${paramIndex}`,
      params
    );

    const localized = result.rows.map(r => localize(r, lang));
    return sendPaginated(res, localized, page, limit, total);
  } catch (err) {
    next(err);
  }
};

// ── GET /api/v1/nutrition/:id ─────────────────────────────────────────
exports.getOne = async (req, res, next) => {
  try {
    const { lang = 'am' } = req.query;
    const result = await query('SELECT * FROM nutrition_content WHERE id = $1', [req.params.id]);
    if (result.rows.length === 0) return sendError(res, 404, 'Nutrition content not found.');
    return sendSuccess(res, 200, 'Nutrition content retrieved', localize(result.rows[0], lang));
  } catch (err) {
    next(err);
  }
};

// ── POST /api/v1/nutrition ────────────────────────────────────────────
exports.create = async (req, res, next) => {
  try {
    const {
      trimester, week, type = 'eat', emoji = '🥗', nutrientType,
      titleAm, titleOr, titleEn,
      bodyAm, bodyOr, bodyEn,
      imageUrl, videoUrl, videoTitle,
      reasonAm, reasonOr, reasonEn,
      foods, foodsJson, nutrientSections, nutrientSectionsJson,
      isPublished,
    } = req.body;

    const result = await query(
      `INSERT INTO nutrition_content (
         trimester, week, type, emoji, nutrient_type,
         title_am, title_or, title_en,
         body_am, body_or, body_en,
         image_url, video_url, video_title,
         reason_am, reason_or, reason_en,
         foods_json, nutrient_sections_json,
         is_published
       )
       VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15,$16,$17,$18,$19,$20)
       RETURNING *`,
      [
        trimester || 1,
        week || null,
        type,
        emoji,
        nutrientType || '',
        titleAm || '',
        titleOr || '',
        titleEn || '',
        bodyAm || '',
        bodyOr || '',
        bodyEn || '',
        imageUrl || null,
        videoUrl || null,
        videoTitle || null,
        reasonAm || null,
        reasonOr || null,
        reasonEn || null,
        JSON.stringify(foodsJson ?? foods ?? null),
        JSON.stringify(nutrientSectionsJson ?? nutrientSections ?? null),
        isPublished || false,
      ]
    );
    return sendSuccess(res, 201, 'Nutrition content created', result.rows[0]);
  } catch (err) {
    next(err);
  }
};

// ── PUT /api/v1/nutrition/:id ─────────────────────────────────────────
exports.update = async (req, res, next) => {
  try {
    const { id } = req.params;

    const fieldMap = {
      trimester: 'trimester',
      week: 'week',
      type: 'type',
      emoji: 'emoji',
      nutrientType: 'nutrient_type',
      titleAm: 'title_am',
      titleOr: 'title_or',
      titleEn: 'title_en',
      bodyAm: 'body_am',
      bodyOr: 'body_or',
      bodyEn: 'body_en',
      imageUrl: 'image_url',
      videoUrl: 'video_url',
      videoTitle: 'video_title',
      reasonAm: 'reason_am',
      reasonOr: 'reason_or',
      reasonEn: 'reason_en',
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

    // Handle JSON fields
    const foods = req.body.foodsJson ?? req.body.foods;
    if (foods !== undefined) {
      updates.push(`foods_json = $${idx++}`);
      values.push(JSON.stringify(foods));
    }

    const sections = req.body.nutrientSectionsJson ?? req.body.nutrientSections;
    if (sections !== undefined) {
      updates.push(`nutrient_sections_json = $${idx++}`);
      values.push(JSON.stringify(sections));
    }

    if (updates.length === 0) return sendError(res, 400, 'No fields to update.');

    values.push(id);
    const result = await query(
      `UPDATE nutrition_content SET ${updates.join(', ')}, updated_at = NOW()
       WHERE id = $${idx} RETURNING *`,
      values
    );
    if (result.rows.length === 0) return sendError(res, 404, 'Nutrition content not found.');
    return sendSuccess(res, 200, 'Nutrition content updated', result.rows[0]);
  } catch (err) {
    next(err);
  }
};

// ── DELETE /api/v1/nutrition/:id ──────────────────────────────────────
exports.remove = async (req, res, next) => {
  try {
    const result = await query(
      'DELETE FROM nutrition_content WHERE id = $1 RETURNING id',
      [req.params.id]
    );
    if (result.rows.length === 0) return sendError(res, 404, 'Nutrition content not found.');
    return sendSuccess(res, 200, 'Nutrition content deleted');
  } catch (err) {
    next(err);
  }
};

// ── Localize helper ────────────────────────────────────────────────────
function localize(item, lang) {
  const l = lang === 'or' ? 'or' : lang === 'en' ? 'en' : 'am';
  return {
    ...item,
    title: item[`title_${l}`] || item.title_am || '',
    body: item[`body_${l}`] || item.body_am || '',
    reason: item[`reason_${l}`] || item.reason_am || '',
    // Expand JSON fields for the mobile app
    image_url: item.image_url || '',
    video_url: item.video_url || '',
    nutrient_type: item.nutrient_type || '',
    emoji: item.emoji || '🥗',
    type: item.type || 'eat',
    week: item.week || null,
    foods: parseJson(item.foods_json) || [],
    nutrient_sections: parseJson(item.nutrient_sections_json) || [],
  };
}

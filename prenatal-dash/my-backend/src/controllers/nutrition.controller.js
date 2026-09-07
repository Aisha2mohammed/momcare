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
      `SELECT * FROM nutrition_content nc ${whereClause}
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
    const body = req.body;
    let trimester = body.trimester;
    if (typeof trimester === 'string') {
      const match = trimester.match(/\d+/);
      trimester = match ? parseInt(match[0], 10) : 1;
    }

    const sections = parseJson(body.nutrientSectionsJson ?? body.nutrient_sections_json ?? body.nutrientSections ?? body.sections) ?? [];
    const firstSec = Array.isArray(sections) && sections.length > 0 ? sections[0] : null;

    const foods = parseJson(body.foodsJson ?? body.foods_json ?? body.foods) ?? [];

    const titleAm = body.titleAm ?? body.title_am ?? firstSec?.titleAm ?? firstSec?.title_am ?? '';
    const titleOr = body.titleOr ?? body.title_or ?? firstSec?.titleOr ?? firstSec?.title_or ?? '';
    const titleEn = body.titleEn ?? body.title_en ?? firstSec?.titleEn ?? firstSec?.title_en ?? '';
    const titleSo = body.titleSo ?? body.title_so ?? firstSec?.titleSo ?? firstSec?.title_so ?? '';

    const bodyAm = body.bodyAm ?? body.body_am ?? firstSec?.bodyAm ?? firstSec?.body_am ?? '';
    const bodyOr = body.bodyOr ?? body.body_or ?? firstSec?.bodyOr ?? firstSec?.body_or ?? '';
    const bodyEn = body.bodyEn ?? body.body_en ?? firstSec?.bodyEn ?? firstSec?.body_en ?? '';
    const bodySo = body.bodySo ?? body.body_so ?? firstSec?.bodySo ?? firstSec?.body_so ?? '';

    const emoji = body.emoji ?? firstSec?.emoji ?? '🥗';
    const nutrientType = body.nutrientType ?? body.nutrient_type ?? firstSec?.nutrientType ?? firstSec?.nutrient_type ?? '';
    const imageUrl = body.imageUrl ?? body.image_url ?? firstSec?.imageUrl ?? firstSec?.image_url ?? null;

    const whyImportantAm = body.whyImportantAm ?? body.why_important_am ?? null;
    const whyImportantOr = body.whyImportantOr ?? body.why_important_or ?? null;
    const whyImportantEn = body.whyImportantEn ?? body.why_important_en ?? null;
    const whyImportantSo = body.whyImportantSo ?? body.why_important_so ?? null;

    const hydrationAm = body.hydrationAm ?? body.hydration_am ?? null;
    const hydrationOr = body.hydrationOr ?? body.hydration_or ?? null;
    const hydrationEn = body.hydrationEn ?? body.hydration_en ?? null;
    const hydrationSo = body.hydrationSo ?? body.hydration_so ?? null;

    const pdfUrl = body.pdfUrl ?? body.pdf_url ?? null;
    const videoUrl = body.videoUrl ?? body.video_url ?? firstSec?.videoUrl ?? firstSec?.video_url ?? null;
    const videoTitle = body.videoTitle ?? body.video_title ?? firstSec?.videoTitle ?? firstSec?.video_title ?? null;

    const reasonAm = body.reasonAm ?? body.reason_am ?? null;
    const reasonOr = body.reasonOr ?? body.reason_or ?? null;
    const reasonEn = body.reasonEn ?? body.reason_en ?? null;
    const reasonSo = body.reasonSo ?? body.reason_so ?? null;

    const week = body.week !== undefined && body.week !== '' && body.week !== null ? Number(body.week) : null;
    const type = body.type ?? 'eat';
    const isPublished = body.isPublished !== undefined ? Boolean(body.isPublished) : (body.is_published !== undefined ? Boolean(body.is_published) : true);

    const result = await query(
      `INSERT INTO nutrition_content (
         trimester, week, type, emoji, nutrient_type,
         title_am, title_or, title_en, title_so,
         body_am, body_or, body_en, body_so,
         why_important_am, why_important_or, why_important_en, why_important_so,
         hydration_am, hydration_or, hydration_en, hydration_so,
         pdf_url,
         image_url, video_url, video_title,
         reason_am, reason_or, reason_en, reason_so,
         foods_json, nutrient_sections_json,
         is_published
       )
       VALUES (
         $1, $2, $3, $4, $5,
         $6, $7, $8, $9,
         $10, $11, $12, $13,
         $14, $15, $16, $17,
         $18, $19, $20, $21,
         $22,
         $23, $24, $25,
         $26, $27, $28, $29,
         $30, $31,
         $32
       )
       RETURNING *`,
      [
        trimester ? Number(trimester) : 1,
        week,
        type,
        emoji,
        nutrientType,
        titleAm,
        titleOr,
        titleEn,
        titleSo,
        bodyAm,
        bodyOr,
        bodyEn,
        bodySo,
        whyImportantAm,
        whyImportantOr,
        whyImportantEn,
        whyImportantSo,
        hydrationAm,
        hydrationOr,
        hydrationEn,
        hydrationSo,
        pdfUrl,
        imageUrl,
        videoUrl,
        videoTitle,
        reasonAm,
        reasonOr,
        reasonEn,
        reasonSo,
        JSON.stringify(foods),
        JSON.stringify(sections),
        isPublished,
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
    const body = req.body;

    const fieldMap = {
      trimester: 'trimester',
      week: 'week',
      type: 'type',
      emoji: 'emoji',
      nutrientType: 'nutrient_type',
      nutrient_type: 'nutrient_type',
      titleAm: 'title_am',
      title_am: 'title_am',
      titleOr: 'title_or',
      title_or: 'title_or',
      titleEn: 'title_en',
      title_en: 'title_en',
      titleSo: 'title_so',
      title_so: 'title_so',
      bodyAm: 'body_am',
      body_am: 'body_am',
      bodyOr: 'body_or',
      body_or: 'body_or',
      bodyEn: 'body_en',
      body_en: 'body_en',
      bodySo: 'body_so',
      body_so: 'body_so',
      whyImportantAm: 'why_important_am',
      why_important_am: 'why_important_am',
      whyImportantOr: 'why_important_or',
      why_important_or: 'why_important_or',
      whyImportantEn: 'why_important_en',
      why_important_en: 'why_important_en',
      whyImportantSo: 'why_important_so',
      why_important_so: 'why_important_so',
      hydrationAm: 'hydration_am',
      hydration_am: 'hydration_am',
      hydrationOr: 'hydration_or',
      hydration_or: 'hydration_or',
      hydrationEn: 'hydration_en',
      hydration_en: 'hydration_en',
      hydrationSo: 'hydration_so',
      hydration_so: 'hydration_so',
      pdfUrl: 'pdf_url',
      pdf_url: 'pdf_url',
      imageUrl: 'image_url',
      image_url: 'image_url',
      videoUrl: 'video_url',
      video_url: 'video_url',
      videoTitle: 'video_title',
      video_title: 'video_title',
      reasonAm: 'reason_am',
      reason_am: 'reason_am',
      reasonOr: 'reason_or',
      reason_or: 'reason_or',
      reasonEn: 'reason_en',
      reason_en: 'reason_en',
      reasonSo: 'reason_so',
      reason_so: 'reason_so',
      isPublished: 'is_published',
      is_published: 'is_published',
    };

    const updates = [];
    const values = [];
    let idx = 1;
    const handledDbFields = new Set();

    for (const [bodyKey, dbField] of Object.entries(fieldMap)) {
      if (body[bodyKey] !== undefined && !handledDbFields.has(dbField)) {
        handledDbFields.add(dbField);
        updates.push(`${dbField} = $${idx++}`);
        values.push(body[bodyKey]);
      }
    }

    // Handle JSON fields
    const foods = body.foodsJson ?? body.foods_json ?? body.foods;
    if (foods !== undefined) {
      updates.push(`foods_json = $${idx++}`);
      values.push(JSON.stringify(foods));
    }

    const sections = body.nutrientSectionsJson ?? body.nutrient_sections_json ?? body.nutrientSections;
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
  const l = lang === 'or' ? 'or' : lang === 'en' ? 'en' : (lang === 'so' || lang === 'somali') ? 'so' : 'am';
  return {
    ...item,
    title: item[`title_${l}`] || item.title_en || item.title_am || '',
    body: item[`body_${l}`] || item.body_en || item.body_am || '',
    reason: item[`reason_${l}`] || item.reason_en || item.reason_am || '',
    why_important: item[`why_important_${l}`] || item.why_important_en || item.why_important_am || '',
    hydration: item[`hydration_${l}`] || item.hydration_en || item.hydration_am || '',
    pdf_url: item.pdf_url || '',
    // Expand JSON fields for the mobile app
    image_url: item.image_url || '',
    video_url: item.video_url || '',
    video_title: item.video_title || '',
    nutrient_type: item.nutrient_type || '',
    emoji: item.emoji || '🥗',
    type: item.type || 'eat',
    week: item.week || null,
    foods: parseJson(item.foods_json) || [],
    nutrient_sections: parseJson(item.nutrient_sections_json) || [],
  };
}

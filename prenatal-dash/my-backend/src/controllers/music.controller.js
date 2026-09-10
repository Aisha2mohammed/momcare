const { query } = require('../config/db');
const { sendSuccess, sendError, sendPaginated } = require('../utils/apiResponse');

const LANGS = ['en', 'am', 'om', 'so'];

// Build a public URL for an uploaded file
function fileUrl(req, file) {
  if (!file) return null;
  return `${req.protocol}://${req.get('host')}/uploads/${file.filename}`;
}

// Resolve one media field: prefer an uploaded file, fall back to a submitted URL string.
function resolveMedia(req, files, fieldName, bodyUrlKey) {
  const file = files && files[fieldName] && files[fieldName][0];
  if (file) return fileUrl(req, file);
  if (req.body[bodyUrlKey] !== undefined) return req.body[bodyUrlKey] || null;
  return undefined;
}

// Helper to resolve localized text fields with fallback
function getFieldValue(item, field, targetLang) {
  // 1. Try requested language
  const localizedVal = item[`${field}_${targetLang}`];
  if (localizedVal && localizedVal.trim() !== '') {
    return localizedVal;
  }

  // 2. Fallback to English
  const englishVal = item[`${field}_en`];
  if (englishVal && englishVal.trim() !== '') {
    return englishVal;
  }

  // 3. Fallback to Amharic if English is missing
  const amharicVal = item[`${field}_am`];
  if (amharicVal && amharicVal.trim() !== '') {
    return amharicVal;
  }

  // 4. Final fallback
  return '';
}

// Helper to resolve localized audio URLs with fallback
function getAudioUrl(item, targetLang) {
  return (
    item[`audio_${targetLang}_url`] ||
    item.audio_en_url ||
    item.audio_am_url ||
    item.audio_om_url ||
    item.audio_so_url ||
    null
  );
}

function localize(item, lang) {
  const targetLang = LANGS.includes(lang) ? lang : 'en';

  return {
    id: item.id,
    category: item.category,
    title: getFieldValue(item, 'title', targetLang),
    description: getFieldValue(item, 'description', targetLang),
    audioUrl: getAudioUrl(item, targetLang),
    imageUrl: item.image_url,
    durationSeconds: item.duration_seconds,
    benefits: getFieldValue(item, 'benefits', targetLang),
    isActive: item.is_active,
    isFeatured: item.is_featured,
    displayOrder: item.display_order,
    createdAt: item.created_at,
    updatedAt: item.updated_at,
  };
}

exports.getAll = async (req, res, next) => {
  try {
    const { category, featured, lang, page = 1, limit = 20 } = req.query;
    let whereClause = 'WHERE mt.is_active = true';
    const params = [];
    let idx = 1;

    if (category) {
      whereClause += ` AND mt.category = $${idx++}`;
      params.push(category);
    }
    if (featured !== undefined) {
      whereClause += ` AND mt.is_featured = $${idx++}`;
      params.push(featured === 'true');
    }

    const countResult = await query(`SELECT COUNT(*) FROM music_tracks mt ${whereClause}`, params);
    const total = parseInt(countResult.rows[0].count, 10);

    const offset = (Number(page) - 1) * Number(limit);
    const limitIdx = idx++;
    const offsetIdx = idx++;
    params.push(Number(limit), offset);

    const result = await query(
      `SELECT * FROM music_tracks mt ${whereClause}
       ORDER BY mt.display_order ASC, mt.id DESC
       LIMIT $${limitIdx} OFFSET $${offsetIdx}`,
      params
    );

    // If lang parameter is explicitly passed, localize; otherwise return ALL language fields
    const data = result.rows.map((row) => {
      if (lang) {
        return localize(row, lang);
      }

      // Return full multilingual payload
      return {
        id: row.id,
        category: row.category,
        titleEn: row.title_en,
        titleAm: row.title_am,
        titleOm: row.title_om,
        titleSo: row.title_so,
        descriptionEn: row.description_en,
        descriptionAm: row.description_am,
        descriptionOm: row.description_om,
        descriptionSo: row.description_so,
        audioEnUrl: row.audio_en_url,
        audioAmUrl: row.audio_am_url,
        audioOmUrl: row.audio_om_url,
        audioSoUrl: row.audio_so_url,
        imageUrl: row.image_url,
        durationSeconds: row.duration_seconds,
        benefitsEn: row.benefits_en,
        benefitsAm: row.benefits_am,
        benefitsOm: row.benefits_om,
        benefitsSo: row.benefits_so,
        isActive: row.is_active,
        isFeatured: row.is_featured,
        displayOrder: row.display_order,
        createdAt: row.created_at,
        updatedAt: row.updated_at,
      };
    });

    return sendPaginated(res, data, page, limit, total);
  } catch (err) {
    next(err);
  }
};

exports.getOne = async (req, res, next) => {
  try {
    const { lang } = req.query;
    const result = await query('SELECT * FROM music_tracks WHERE id = $1', [req.params.id]);
    if (result.rows.length === 0) return sendError(res, 404, 'Music track not found.');

    const data = lang ? localize(result.rows[0], lang) : result.rows[0];
    return sendSuccess(res, 200, 'Music track retrieved', data);
  } catch (err) {
    next(err);
  }
};

exports.create = async (req, res, next) => {
  try {
    const b = req.body;
    const files = req.files || {};

    if (!b.category) return sendError(res, 400, 'category is required.');
    if (!b.titleEn && !b.titleAm) return sendError(res, 400, 'At least titleEn or titleAm is required.');

    const imageUrl = resolveMedia(req, files, 'image', 'imageUrl');
    const audioEnUrl = resolveMedia(req, files, 'audio_en', 'audioEnUrl');
    const audioAmUrl = resolveMedia(req, files, 'audio_am', 'audioAmUrl');
    const audioOmUrl = resolveMedia(req, files, 'audio_om', 'audioOmUrl');
    const audioSoUrl = resolveMedia(req, files, 'audio_so', 'audioSoUrl');

    const result = await query(
      `INSERT INTO music_tracks (
        category,
        title_en, title_am, title_om, title_so,
        description_en, description_am, description_om, description_so,
        audio_en_url, audio_am_url, audio_om_url, audio_so_url,
        image_url, duration_seconds,
        benefits_en, benefits_am, benefits_om, benefits_so,
        is_active, is_featured, display_order
      ) VALUES (
        $1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13,
        $14, $15, $16, $17, $18, $19, $20, $21, $22
      ) RETURNING *`,
      [
        b.category,
        b.titleEn || null, b.titleAm || null, b.titleOm || null, b.titleSo || null,
        b.descriptionEn || null, b.descriptionAm || null, b.descriptionOm || null, b.descriptionSo || null,
        audioEnUrl || null, audioAmUrl || null, audioOmUrl || null, audioSoUrl || null,
        imageUrl || null,
        b.durationSeconds ? Number(b.durationSeconds) : null,
        b.benefitsEn || null, b.benefitsAm || null, b.benefitsOm || null, b.benefitsSo || null,
        b.isActive !== undefined ? (b.isActive === 'true' || b.isActive === true) : true,
        b.isFeatured !== undefined ? (b.isFeatured === 'true' || b.isFeatured === true) : false,
        b.displayOrder ? Number(b.displayOrder) : 0,
      ]
    );
    return sendSuccess(res, 201, 'Music track created', result.rows[0]);
  } catch (err) {
    next(err);
  }
};

exports.update = async (req, res, next) => {
  try {
    const b = req.body;
    const files = req.files || {};
    const updates = [];
    const values = [];
    let idx = 1;

    const textFieldMap = {
      category: 'category',
      titleEn: 'title_en', titleAm: 'title_am', titleOm: 'title_om', titleSo: 'title_so',
      descriptionEn: 'description_en', descriptionAm: 'description_am',
      descriptionOm: 'description_om', descriptionSo: 'description_so',
      benefitsEn: 'benefits_en', benefitsAm: 'benefits_am',
      benefitsOm: 'benefits_om', benefitsSo: 'benefits_so',
      durationSeconds: 'duration_seconds',
      isActive: 'is_active',
      isFeatured: 'is_featured',
      displayOrder: 'display_order',
    };

    for (const [bodyKey, dbField] of Object.entries(textFieldMap)) {
      if (b[bodyKey] !== undefined) {
        let val = b[bodyKey];
        if (dbField === 'is_active' || dbField === 'is_featured') val = val === 'true' || val === true;
        if (dbField === 'duration_seconds' || dbField === 'display_order') val = val === '' ? null : Number(val);
        updates.push(`${dbField} = $${idx++}`);
        values.push(val);
      }
    }

    const mediaFields = [
      { file: 'image', urlKey: 'imageUrl', db: 'image_url' },
      { file: 'audio_en', urlKey: 'audioEnUrl', db: 'audio_en_url' },
      { file: 'audio_am', urlKey: 'audioAmUrl', db: 'audio_am_url' },
      { file: 'audio_om', urlKey: 'audioOmUrl', db: 'audio_om_url' },
      { file: 'audio_so', urlKey: 'audioSoUrl', db: 'audio_so_url' },
    ];

    for (const m of mediaFields) {
      const resolved = resolveMedia(req, files, m.file, m.urlKey);
      if (resolved !== undefined) {
        updates.push(`${m.db} = $${idx++}`);
        values.push(resolved || null);
      }
    }

    if (updates.length === 0) return sendError(res, 400, 'No fields to update.');
    values.push(req.params.id);

    const result = await query(
      `UPDATE music_tracks SET ${updates.join(', ')}, updated_at = NOW() WHERE id = $${idx} RETURNING *`,
      values
    );
    if (result.rows.length === 0) return sendError(res, 404, 'Music track not found.');
    return sendSuccess(res, 200, 'Music track updated', result.rows[0]);
  } catch (err) {
    next(err);
  }
};

exports.remove = async (req, res, next) => {
  try {
    const result = await query('DELETE FROM music_tracks WHERE id = $1 RETURNING id', [req.params.id]);
    if (result.rows.length === 0) return sendError(res, 404, 'Music track not found.');
    return sendSuccess(res, 200, 'Music track deleted');
  } catch (err) {
    next(err);
  }
};
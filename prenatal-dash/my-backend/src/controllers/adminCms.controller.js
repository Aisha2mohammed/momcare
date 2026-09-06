const { query } = require('../config/db');
const { sendSuccess, sendError, sendPaginated } = require('../utils/apiResponse');

// ── Module Configuration & Meta ───────────────────────────────────────
const MODULES = {
  nutrition: {
    table: 'nutrition_content',
    primaryKey: 'id',
    orderBy: 'trimester ASC, created_at DESC',
    searchFields: ['title_am', 'title_or', 'title_en', 'body_am', 'body_or', 'body_en', 'nutrient_type'],
    normalizeIn: (body) => {
      let trimester = body.trimester;
      if (typeof trimester === 'string') {
        const match = trimester.match(/\d+/);
        trimester = match ? parseInt(match[0], 10) : 1;
      }

      // Parse foods_json / nutrient_sections_json — accept both string and object
      const parseJson = (v) => {
        if (!v) return null;
        if (typeof v === 'string') { try { return JSON.parse(v); } catch { return null; } }
        return v;
      };

      return {
        trimester: trimester !== undefined ? Number(trimester) : 1,
        week: body.week !== undefined && body.week !== '' ? Number(body.week) : null,
        type: body.type ?? 'eat',
        emoji: body.emoji ?? '🥗',
        nutrient_type: body.nutrientType ?? body.nutrient_type ?? '',
        title_am: body.titleAm ?? body.title_am ?? '',
        title_or: body.titleOr ?? body.title_or ?? '',
        title_en: body.titleEn ?? body.title_en ?? '',
        body_am: body.bodyAm ?? body.body_am ?? '',
        body_or: body.bodyOr ?? body.body_or ?? '',
        body_en: body.bodyEn ?? body.body_en ?? '',
        image_url: body.imageUrl ?? body.image_url ?? null,
        video_url: body.videoUrl ?? body.video_url ?? null,
        video_title: body.videoTitle ?? body.video_title ?? null,
        reason_am: body.reasonAm ?? body.reason_am ?? null,
        reason_or: body.reasonOr ?? body.reason_or ?? null,
        reason_en: body.reasonEn ?? body.reason_en ?? null,
        foods_json: parseJson(body.foodsJson ?? body.foods_json ?? body.foods) ?? null,
        nutrient_sections_json: parseJson(body.nutrientSectionsJson ?? body.nutrient_sections_json ?? body.nutrientSections) ?? null,
        is_published: body.isPublished !== undefined ? Boolean(body.isPublished) : (body.published !== undefined ? Boolean(body.published) : false),
      };
    },
    normalizeOut: (row) => {
      const parseJson = (v) => {
        if (!v) return null;
        if (typeof v === 'string') { try { return JSON.parse(v); } catch { return null; } }
        return v;
      };
      const tri = row.trimester || 1;
      return {
        ...row,
        titleAm: row.title_am || '',
        titleOr: row.title_or || '',
        titleEn: row.title_en || '',
        bodyAm: row.body_am || '',
        bodyOr: row.body_or || '',
        bodyEn: row.body_en || '',
        imageUrl: row.image_url || '',
        videoUrl: row.video_url || '',
        videoTitle: row.video_title || '',
        reasonAm: row.reason_am || '',
        reasonOr: row.reason_or || '',
        reasonEn: row.reason_en || '',
        nutrientType: row.nutrient_type || '',
        emoji: row.emoji || '🥗',
        type: row.type || 'eat',
        week: row.week || null,
        foods: parseJson(row.foods_json) || [],
        foodsJson: parseJson(row.foods_json) || [],
        nutrientSections: parseJson(row.nutrient_sections_json) || [],
        nutrientSectionsJson: parseJson(row.nutrient_sections_json) || [],
        isPublished: Boolean(row.is_published),
        published: Boolean(row.is_published),
        trimester: `${tri}${tri === 1 ? 'st' : tri === 2 ? 'nd' : 'rd'}`,
        trimesterNumber: tri,
      };
    },
  },

  fetal: {
    table: 'fetal_tracker_content',
    primaryKey: 'id',
    orderBy: 'week_number ASC',
    searchFields: ['size_comparison', 'milestone_am', 'milestone_or', 'milestone_en', 'tips_am', 'tips_or', 'tips_en'],
    normalizeIn: (body) => ({
      week_number: Number(body.weekNumber ?? body.week_number ?? body.week ?? 1),
      size_comparison: body.sizeComparison ?? body.size_comparison ?? '',
      milestone_am: body.milestoneAm ?? body.milestone_am ?? '',
      milestone_or: body.milestoneOr ?? body.milestone_or ?? '',
      milestone_en: body.milestoneEn ?? body.milestone_en ?? '',
      tips_am: body.tipsAm ?? body.tips_am ?? '',
      tips_or: body.tipsOr ?? body.tips_or ?? '',
      tips_en: body.tipsEn ?? body.tips_en ?? '',
      image_url: body.imageUrl ?? body.image_url ?? null,
    }),
    normalizeOut: (row) => ({
      ...row,
      week: row.week_number,
      weekNumber: row.week_number,
      sizeComparison: row.size_comparison || '',
      milestoneAm: row.milestone_am || '',
      milestoneOr: row.milestone_or || '',
      milestoneEn: row.milestone_en || '',
      tipsAm: row.tips_am || '',
      tipsOr: row.tips_or || '',
      tipsEn: row.tips_en || '',
      imageUrl: row.image_url || '',
    }),
  },

  exercises: {
    table: 'exercise_content',
    primaryKey: 'id',
    orderBy: 'created_at DESC, id DESC',
    searchFields: ['name_am', 'name_or', 'name_en', 'safety_notes_am', 'safety_notes_or', 'safety_notes_en'],
    normalizeIn: (body) => {
      // Parse trimester flags to array of numbers [1, 2, 3]
      let flags = body.trimesterFlags ?? body.trimester_flags ?? body.trimesters;
      if (Array.isArray(flags)) {
        flags = flags.map(f => {
          if (typeof f === 'string') {
            const m = f.match(/\d+/);
            return m ? parseInt(m[0], 10) : 1;
          }
          return Number(f);
        });
      } else if (typeof flags === 'string') {
        flags = [parseInt(flags, 10) || 1];
      } else {
        flags = [1];
      }

      // Parse duration
      let durationMin = body.durationMin ?? body.duration_min ?? body.duration;
      if (typeof durationMin === 'string') {
        const m = durationMin.match(/\d+/);
        durationMin = m ? parseInt(m[0], 10) : null;
      }

      return {
        name_am: body.nameAm ?? body.name_am ?? '',
        name_or: body.nameOr ?? body.name_or ?? '',
        name_en: body.nameEn ?? body.name_en ?? '',
        trimester_flags: JSON.stringify(flags),
        duration_min: durationMin !== undefined ? Number(durationMin) : null,
        safety_notes_am: body.safetyNotesAm ?? body.safety_notes_am ?? body.safetyAm ?? '',
        safety_notes_or: body.safetyNotesOr ?? body.safety_notes_or ?? body.safetyOr ?? '',
        safety_notes_en: body.safetyNotesEn ?? body.safety_notes_en ?? '',
        media_url: body.mediaUrl ?? body.media_url ?? body.videoUrl ?? null,
        is_published: body.isPublished !== undefined ? Boolean(body.isPublished) : (body.published !== undefined ? Boolean(body.published) : false),
      };
    },
    normalizeOut: (row) => {
      let flags = row.trimester_flags;
      if (typeof flags === 'string') {
        try { flags = JSON.parse(flags); } catch { flags = []; }
      }
      if (!Array.isArray(flags)) flags = [1];

      const trimesters = flags.map(n => `${n}${n === 1 ? 'st' : n === 2 ? 'nd' : 'rd'}`);

      return {
        ...row,
        nameAm: row.name_am || '',
        nameOr: row.name_or || '',
        nameEn: row.name_en || '',
        trimesters,
        trimesterFlags: flags,
        duration: row.duration_min ? `${row.duration_min} min` : '',
        durationMin: row.duration_min,
        safetyAm: row.safety_notes_am || '',
        safetyOr: row.safety_notes_or || '',
        safetyNotesAm: row.safety_notes_am || '',
        safetyNotesOr: row.safety_notes_or || '',
        safetyNotesEn: row.safety_notes_en || '',
        mediaUrl: row.media_url || '',
        videoUrl: row.media_url || '',
        isPublished: Boolean(row.is_published),
        published: Boolean(row.is_published),
      };
    },
  },

  sleep: {
    table: 'sleep_tips',
    primaryKey: 'id',
    orderBy: 'trimester ASC, created_at DESC',
    searchFields: ['title_am', 'title_or', 'title_en', 'description_am', 'description_or', 'description_en'],
    normalizeIn: (body) => {
      let trimester = body.trimester;
      if (typeof trimester === 'string') {
        if (trimester.toLowerCase() === 'all') {
          trimester = 0;
        } else {
          const match = trimester.match(/\d+/);
          trimester = match ? parseInt(match[0], 10) : 0;
        }
      }

      return {
        trimester: trimester !== undefined ? Number(trimester) : 0,
        title_am: body.titleAm ?? body.title_am ?? '',
        title_or: body.titleOr ?? body.title_or ?? '',
        title_en: body.titleEn ?? body.title_en ?? '',
        description_am: body.descriptionAm ?? body.description_am ?? body.descAm ?? '',
        description_or: body.descriptionOr ?? body.description_or ?? body.descOr ?? '',
        description_en: body.descriptionEn ?? body.description_en ?? '',
        illustration_url: body.illustrationUrl ?? body.illustration_url ?? body.videoUrl ?? body.imageUrl ?? null,
      };
    },
    normalizeOut: (row) => ({
      ...row,
      titleAm: row.title_am || '',
      titleOr: row.title_or || '',
      titleEn: row.title_en || '',
      descAm: row.description_am || '',
      descOr: row.description_or || '',
      descriptionAm: row.description_am || '',
      descriptionOr: row.description_or || '',
      descriptionEn: row.description_en || '',
      trimester: row.trimester === 0 ? 'All' : `${row.trimester}${row.trimester === 1 ? 'st' : row.trimester === 2 ? 'nd' : 'rd'}`,
      trimesterNumber: row.trimester || 0,
      illustrationUrl: row.illustration_url || '',
      videoUrl: row.illustration_url || '',
    }),
  },

  music: {
    table: 'music_tracks',
    primaryKey: 'id',
    orderBy: 'created_at DESC, id DESC',
    searchFields: ['title_am', 'title_or', 'title_en', 'category'],
    normalizeIn: (body) => {
      // Parse duration
      let durationSec = body.duration;
      if (typeof durationSec === 'string') {
        if (durationSec.includes(':')) {
          const [m, s] = durationSec.split(':').map(x => parseInt(x, 10) || 0);
          durationSec = m * 60 + s;
        } else {
          const m = durationSec.match(/\d+/);
          durationSec = m ? parseInt(m[0], 10) : null;
        }
      }

      return {
        title_am: body.titleAm ?? body.title_am ?? '',
        title_or: body.titleOr ?? body.title_or ?? '',
        title_en: body.titleEn ?? body.title_en ?? '',
        category: body.category ?? 'Relaxation',
        duration: durationSec !== undefined ? Number(durationSec) : null,
        thumbnail_url: body.thumbnailUrl ?? body.thumbnail_url ?? null,
        media_url: body.mediaUrl ?? body.media_url ?? body.url ?? '',
        is_active: body.isActive !== undefined ? Boolean(body.isActive) : (body.active !== undefined ? Boolean(body.active) : true),
      };
    },
    normalizeOut: (row) => {
      let durationStr = '';
      if (row.duration) {
        const mins = Math.floor(row.duration / 60);
        const secs = row.duration % 60;
        durationStr = `${mins}:${secs < 10 ? '0' : ''}${secs}`;
      }

      return {
        ...row,
        titleAm: row.title_am || '',
        titleOr: row.title_or || '',
        titleEn: row.title_en || '',
        category: row.category || 'Relaxation',
        duration: durationStr,
        durationSeconds: row.duration,
        thumbnailUrl: row.thumbnail_url || '',
        mediaUrl: row.media_url || '',
        url: row.media_url || '',
        isActive: Boolean(row.is_active),
        active: Boolean(row.is_active),
      };
    },
  },
};

// Aliases for friendly routing
const ALIASES = {
  'nutrition-guide': 'nutrition',
  'nutrition-guides': 'nutrition',
  'fetal-development': 'fetal',
  'fetal-tracker': 'fetal',
  'fetal-trackers': 'fetal',
  'exercise': 'exercises',
  'sleep-tips': 'sleep',
  'sleep-position': 'sleep',
  'sleep-positions': 'sleep',
  'sleeping-positions': 'sleep',
  'music-relaxation': 'music',
  'music-tracks': 'music',
  'tracks': 'music',
};

function resolveModule(param) {
  if (!param) return null;
  const key = param.toLowerCase().trim();
  const canonical = ALIASES[key] || key;
  return MODULES[canonical] ? { key: canonical, meta: MODULES[canonical] } : null;
}

// ── GET /api/v1/admin/cms/:module ──────────────────────────────────────
exports.list = async (req, res, next) => {
  try {
    const resolved = resolveModule(req.params.module);
    if (!resolved) {
      return sendError(res, 404, `Unknown CMS module '${req.params.module}'. Valid modules: ${Object.keys(MODULES).join(', ')}`);
    }

    const { meta } = resolved;
    const {
      page = 1,
      limit = 20,
      search,
      q,
      trimester,
      category,
      isPublished,
      published,
      isActive,
      active,
    } = req.query;

    const searchTerm = search || q;
    const whereClauses = [];
    const params = [];
    let paramIndex = 1;

    // Search query
    if (searchTerm && searchTerm.trim()) {
      const term = `%${searchTerm.trim()}%`;
      const searchConditions = meta.searchFields.map(field => `${field} ILIKE $${paramIndex}`);
      params.push(term);
      paramIndex++;
      whereClauses.push(`(${searchConditions.join(' OR ')})`);
    }

    // Trimester filter (for nutrition, sleep, exercise)
    if (trimester !== undefined && trimester !== '') {
      let triVal = trimester;
      if (typeof triVal === 'string') {
        if (triVal.toLowerCase() === 'all') {
          triVal = 0;
        } else {
          const match = triVal.match(/\d+/);
          triVal = match ? parseInt(match[0], 10) : parseInt(triVal, 10);
        }
      }

      if (resolved.key === 'exercises') {
        whereClauses.push(`trimester_flags @> $${paramIndex++}::jsonb`);
        params.push(JSON.stringify([Number(triVal)]));
      } else if (resolved.key === 'nutrition' || resolved.key === 'sleep') {
        whereClauses.push(`(trimester = $${paramIndex++} OR trimester = 0)`);
        params.push(Number(triVal));
      }
    }

    // Category filter (for exercise, music)
    if (category && category !== '' && category !== 'All') {
      if (resolved.key === 'music') {
        whereClauses.push(`category ILIKE $${paramIndex++}`);
        params.push(category);
      }
    }

    // Status filter
    const pub = isPublished ?? published;
    if (pub !== undefined && pub !== '') {
      if (resolved.key === 'nutrition' || resolved.key === 'exercises') {
        whereClauses.push(`is_published = $${paramIndex++}`);
        params.push(pub === 'true' || pub === true);
      }
    }

    const act = isActive ?? active;
    if (act !== undefined && act !== '') {
      if (resolved.key === 'music') {
        whereClauses.push(`is_active = $${paramIndex++}`);
        params.push(act === 'true' || act === true);
      }
    }

    const whereString = whereClauses.length > 0 ? `WHERE ${whereClauses.join(' AND ')}` : '';

    // Total count
    const countSql = `SELECT COUNT(*) FROM ${meta.table} ${whereString}`;
    const countResult = await query(countSql, params);
    const total = parseInt(countResult.rows[0].count, 10);

    // Pagination
    const pageNum = Math.max(1, parseInt(page, 10) || 1);
    const limitNum = Math.max(1, Math.min(100, parseInt(limit, 10) || 20));
    const offset = (pageNum - 1) * limitNum;

    const dataParams = [...params, limitNum, offset];
    const dataSql = `
      SELECT * FROM ${meta.table}
      ${whereString}
      ORDER BY ${meta.orderBy}
      LIMIT $${paramIndex++} OFFSET $${paramIndex}
    `;

    const dataResult = await query(dataSql, dataParams);
    const items = dataResult.rows.map(meta.normalizeOut);

    return sendPaginated(res, items, pageNum, limitNum, total);
  } catch (err) {
    next(err);
  }
};

// ── GET /api/v1/admin/cms/:module/:id ──────────────────────────────────
exports.getOne = async (req, res, next) => {
  try {
    const resolved = resolveModule(req.params.module);
    if (!resolved) {
      return sendError(res, 404, `Unknown CMS module '${req.params.module}'.`);
    }

    const { meta } = resolved;
    const { id } = req.params;

    // Check if ID is UUID or integer (like week_number for fetal)
    let sql;
    if (resolved.key === 'fetal' && !isNaN(Number(id))) {
      sql = `SELECT * FROM ${meta.table} WHERE week_number = $1 OR id::text = $1`;
    } else {
      sql = `SELECT * FROM ${meta.table} WHERE id::text = $1`;
    }

    const result = await query(sql, [id]);
    if (result.rows.length === 0) {
      return sendError(res, 404, `Item with id '${id}' not found in ${resolved.key}.`);
    }

    return sendSuccess(res, 200, `${resolved.key} item retrieved`, meta.normalizeOut(result.rows[0]));
  } catch (err) {
    next(err);
  }
};

// ── POST /api/v1/admin/cms/:module ─────────────────────────────────────
exports.create = async (req, res, next) => {
  try {
    const resolved = resolveModule(req.params.module);
    if (!resolved) {
      return sendError(res, 404, `Unknown CMS module '${req.params.module}'.`);
    }

    const { meta } = resolved;
    const normalizedData = meta.normalizeIn(req.body);

    // Basic validation
    if (resolved.key === 'fetal') {
      if (!normalizedData.week_number || normalizedData.week_number < 1 || normalizedData.week_number > 42) {
        return sendError(res, 400, 'Week number must be between 1 and 42.');
      }
      // Check for duplicate week
      const existing = await query('SELECT id FROM fetal_tracker_content WHERE week_number = $1', [normalizedData.week_number]);
      if (existing.rows.length > 0) {
        return sendError(res, 409, `Week ${normalizedData.week_number} already exists.`);
      }
    } else if (resolved.key === 'exercises') {
      if (!normalizedData.name_am && !normalizedData.name_en && !normalizedData.name_or) {
        return sendError(res, 400, 'Exercise name is required in at least one language.');
      }
    } else if (resolved.key === 'music') {
      if (!normalizedData.title_am && !normalizedData.title_en && !normalizedData.title_or) {
        return sendError(res, 400, 'Track title is required in at least one language.');
      }
    } else {
      if (!normalizedData.title_am && !normalizedData.title_en && !normalizedData.title_or) {
        return sendError(res, 400, 'Title is required in at least one language.');
      }
    }

    const fields = Object.keys(normalizedData);
    const values = Object.values(normalizedData);
    const placeholders = fields.map((_, i) => `$${i + 1}`).join(', ');

    const insertSql = `
      INSERT INTO ${meta.table} (${fields.join(', ')})
      VALUES (${placeholders})
      RETURNING *
    `;

    const result = await query(insertSql, values);
    return sendSuccess(res, 201, `${resolved.key} item created successfully`, meta.normalizeOut(result.rows[0]));
  } catch (err) {
    next(err);
  }
};

// ── PUT /api/v1/admin/cms/:module/:id ──────────────────────────────────
exports.update = async (req, res, next) => {
  try {
    const resolved = resolveModule(req.params.module);
    if (!resolved) {
      return sendError(res, 404, `Unknown CMS module '${req.params.module}'.`);
    }

    const { meta } = resolved;
    const { id } = req.params;

    // Check item existence
    const checkSql = (resolved.key === 'fetal' && !isNaN(Number(id)))
      ? `SELECT id FROM ${meta.table} WHERE week_number = $1 OR id::text = $1`
      : `SELECT id FROM ${meta.table} WHERE id::text = $1`;

    const checkResult = await query(checkSql, [id]);
    if (checkResult.rows.length === 0) {
      return sendError(res, 404, `Item with id '${id}' not found in ${resolved.key}.`);
    }
    const realId = checkResult.rows[0].id;

    // Normalize only provided fields
    const rawNormalized = meta.normalizeIn(req.body);
    const updates = [];
    const values = [];
    let idx = 1;

    for (const [key, val] of Object.entries(rawNormalized)) {
      if (val !== undefined) {
        updates.push(`${key} = $${idx++}`);
        values.push(val);
      }
    }

    if (updates.length === 0) {
      return sendError(res, 400, 'No valid fields provided for update.');
    }

    // Always update updated_at if column exists
    updates.push(`updated_at = NOW()`);
    values.push(realId);

    const updateSql = `
      UPDATE ${meta.table}
      SET ${updates.join(', ')}
      WHERE id = $${idx}
      RETURNING *
    `;

    const result = await query(updateSql, values);
    return sendSuccess(res, 200, `${resolved.key} item updated successfully`, meta.normalizeOut(result.rows[0]));
  } catch (err) {
    next(err);
  }
};

// ── DELETE /api/v1/admin/cms/:module/:id ───────────────────────────────
exports.remove = async (req, res, next) => {
  try {
    const resolved = resolveModule(req.params.module);
    if (!resolved) {
      return sendError(res, 404, `Unknown CMS module '${req.params.module}'.`);
    }

    const { meta } = resolved;
    const { id } = req.params;

    const deleteSql = (resolved.key === 'fetal' && !isNaN(Number(id)))
      ? `DELETE FROM ${meta.table} WHERE week_number = $1 OR id::text = $1 RETURNING id`
      : `DELETE FROM ${meta.table} WHERE id::text = $1 RETURNING id`;

    const result = await query(deleteSql, [id]);
    if (result.rows.length === 0) {
      return sendError(res, 404, `Item with id '${id}' not found in ${resolved.key}.`);
    }

    return sendSuccess(res, 200, `${resolved.key} item deleted successfully`, { id: result.rows[0].id });
  } catch (err) {
    next(err);
  }
};

const { query } = require('../config/db');
const { sendSuccess, sendError, sendPaginated } = require('../utils/apiResponse');
const {
  localizeWeek,
  localizeDevelopmentItem,
  localizeChecklistItem,
} = require('../utils/fetalLocalize');

// ── FIXED HELPER ──────────────────────────────────────────────────────
const safeJsonParse = (value, fallback = []) => {
  if (!value) return fallback;
  let parsed = value;

  // 1. If string, parse it once
  if (typeof value === 'string') {
    try {
      parsed = JSON.parse(value);
    } catch (err) {
      return fallback;
    }
  }

  // 2. If it's an array, ensure all internal stringified items are fully parsed into objects
  if (Array.isArray(parsed)) {
    return parsed.map(item => {
      if (typeof item === 'string') {
        try {
          return JSON.parse(item);
        } catch (e) {
          return item;
        }
      }
      return item;
    });
  }

  return parsed;
};

// ── GET /api/v1/fetal ─────────────────────────────────────────────────
exports.getAll = async (req, res, next) => {
  try {
    const { lang = 'am', page = 1, limit = 42 } = req.query;
    const offset = (Number(page) - 1) * Number(limit);
    const includeInactive = req.user?.role === 'admin' && req.query.includeInactive === 'true';

    const whereClause = includeInactive ? '' : 'WHERE is_active = true';

    const countResult = await query(`SELECT COUNT(*) FROM fetal_weekly_content ${whereClause}`);
    const total = parseInt(countResult.rows[0].count, 10);

    const result = await query(
      `SELECT * FROM fetal_weekly_content ${whereClause} ORDER BY week_number ASC LIMIT $1 OFFSET $2`,
      [Number(limit), offset]
    );

    const localized = result.rows.map(r => localizeWeek(r, lang));
    return sendPaginated(res, localized, page, limit, total);
  } catch (err) {
    next(err);
  }
};

// ── GET /api/v1/fetal/:week ───────────────────────────────────────────
exports.getByWeek = async (req, res, next) => {
  try {
    const { week } = req.params;
    const { lang = 'am' } = req.query;

    const weekNum = Number(week);
    if (isNaN(weekNum) || weekNum < 1 || weekNum > 42) {
      return sendError(res, 400, 'Week must be between 1 and 42.');
    }

    const weekResult = await query(
      'SELECT * FROM fetal_weekly_content WHERE week_number = $1 AND is_active = true',
      [weekNum]
    );
    if (weekResult.rows.length === 0) {
      return sendError(res, 404, `No data found for week ${weekNum}.`);
    }
    const weekRow = weekResult.rows[0];

    const [devItemsResult, checklistResult] = await Promise.all([
      query(
        'SELECT * FROM fetal_development_items WHERE week_id = $1 ORDER BY display_order ASC',
        [weekRow.id]
      ),
      query(
        'SELECT * FROM fetal_checklist_items WHERE week_id = $1 ORDER BY display_order ASC',
        [weekRow.id]
      ),
    ]);

    const payload = {
      ...localizeWeek(weekRow, lang),
      developments: devItemsResult.rows.map(i => localizeDevelopmentItem(i, lang)),
      checklist: checklistResult.rows.map(i => localizeChecklistItem(i, lang)),
    };

    return sendSuccess(res, 200, `Week ${weekNum} fetal data`, payload);
  } catch (err) {
    next(err);
  }
};

// ── POST /api/v1/fetal (admin) ────────────────────────────────────────
exports.create = async (req, res, next) => {
  try {
    const b = req.body;

    let finalImageUrl = b.imageUrl || b.image_url || null;
    if (req.file) {
      finalImageUrl = `/uploads/fetal/${req.file.filename}`;
    }

    const columns = [
      'week_number', 'title_en', 'title_am', 'title_om', 'title_so',
      'image_url', 'image_alt_en', 'image_alt_am', 'image_alt_om', 'image_alt_so',
      'summary_en', 'summary_am', 'summary_om', 'summary_so',
      'baby_length_cm', 'baby_weight_g',
      'size_comparison_en', 'size_comparison_am', 'size_comparison_om', 'size_comparison_so',
      'milestone_en', 'milestone_am', 'milestone_om', 'milestone_so',
      'physical_development_en', 'physical_development_am', 'physical_development_om', 'physical_development_so',
      'brain_dev_en', 'brain_dev_am', 'brain_dev_om', 'brain_dev_so',
      'heart_dev_en', 'heart_dev_am', 'heart_dev_om', 'heart_dev_so',
      'organ_dev_en', 'organ_dev_am', 'organ_dev_om', 'organ_dev_so',
      'bone_muscle_dev_en', 'bone_muscle_dev_am', 'bone_muscle_dev_om', 'bone_muscle_dev_so',
      'movement_en', 'movement_am', 'movement_om', 'movement_so', 'senses',
      'maternal_changes_en', 'maternal_changes_am', 'maternal_changes_om', 'maternal_changes_so',
      'common_symptoms_en', 'common_symptoms_am', 'common_symptoms_om', 'common_symptoms_so',
      'health_tip_en', 'health_tip_am', 'health_tip_om', 'health_tip_so',
      'antenatal_care_en', 'antenatal_care_am', 'antenatal_care_om', 'antenatal_care_so',
      'screening_information_en', 'screening_information_am', 'screening_information_om', 'screening_information_so',
      'bonding_activity_title_en', 'bonding_activity_title_am', 'bonding_activity_title_om', 'bonding_activity_title_so',
      'bonding_activity_description_en', 'bonding_activity_description_am', 'bonding_activity_description_om', 'bonding_activity_description_so',
      'emotional_message_en', 'emotional_message_am', 'emotional_message_om', 'emotional_message_so',
      'diary_prompt_en', 'diary_prompt_am', 'diary_prompt_om', 'diary_prompt_so',
      'warning_signs_en', 'warning_signs_am', 'warning_signs_om', 'warning_signs_so',
      'when_to_contact_provider_en', 'when_to_contact_provider_am', 'when_to_contact_provider_om', 'when_to_contact_provider_so',
      'is_active', 'created_by',
    ];

    const values = columns.map(c => {
      if (c === 'image_url') return finalImageUrl;
      
      // FIXED: Strictly JSON.stringify 'senses' for PostgreSQL
      if (c === 'senses') {
        const parsedSenses = safeJsonParse(b.senses);
        return JSON.stringify(parsedSenses);
      }
      
      if (c === 'is_active') return b.isActive ?? b.is_active ?? true;
      if (c === 'created_by') return b.createdBy ?? b.created_by ?? req.user?.id ?? null;

      const camel = c.replace(/_([a-z0-9])/gi, (_, ch) => ch.toUpperCase());
      return b[camel] ?? b[c] ?? null;
    });

    const placeholders = columns.map((_, i) => `$${i + 1}`).join(', ');

    const result = await query(
      `INSERT INTO fetal_weekly_content (${columns.join(', ')})
       VALUES (${placeholders}) RETURNING *`,
      values
    );
    const weekRow = result.rows[0];

    const developments = safeJsonParse(b.developments);
    if (developments.length > 0) {
      await insertDevelopmentItems(weekRow.id, developments);
    }

    const checklist = safeJsonParse(b.checklist);
    if (checklist.length > 0) {
      await insertChecklistItems(weekRow.id, checklist);
    }

    return sendSuccess(res, 201, 'Fetal week data created', weekRow);
  } catch (err) {
    next(err);
  }
};

// ── PUT /api/v1/fetal/:id (admin) ─────────────────────────────────────
exports.update = async (req, res, next) => {
  try {
    const updatableFields = [
      'week_number', 'title_en', 'title_am', 'title_om', 'title_so',
      'image_url', 'image_alt_en', 'image_alt_am', 'image_alt_om', 'image_alt_so',
      'summary_en', 'summary_am', 'summary_om', 'summary_so',
      'baby_length_cm', 'baby_weight_g',
      'size_comparison_en', 'size_comparison_am', 'size_comparison_om', 'size_comparison_so',
      'milestone_en', 'milestone_am', 'milestone_om', 'milestone_so',
      'physical_development_en', 'physical_development_am', 'physical_development_om', 'physical_development_so',
      'brain_dev_en', 'brain_dev_am', 'brain_dev_om', 'brain_dev_so',
      'heart_dev_en', 'heart_dev_am', 'heart_dev_om', 'heart_dev_so',
      'organ_dev_en', 'organ_dev_am', 'organ_dev_om', 'organ_dev_so',
      'bone_muscle_dev_en', 'bone_muscle_dev_am', 'bone_muscle_dev_om', 'bone_muscle_dev_so',
      'movement_en', 'movement_am', 'movement_om', 'movement_so', 'senses',
      'maternal_changes_en', 'maternal_changes_am', 'maternal_changes_om', 'maternal_changes_so',
      'common_symptoms_en', 'common_symptoms_am', 'common_symptoms_om', 'common_symptoms_so',
      'health_tip_en', 'health_tip_am', 'health_tip_om', 'health_tip_so',
      'antenatal_care_en', 'antenatal_care_am', 'antenatal_care_om', 'antenatal_care_so',
      'screening_information_en', 'screening_information_am', 'screening_information_om', 'screening_information_so',
      'bonding_activity_title_en', 'bonding_activity_title_am', 'bonding_activity_title_om', 'bonding_activity_title_so',
      'bonding_activity_description_en', 'bonding_activity_description_am', 'bonding_activity_description_om', 'bonding_activity_description_so',
      'emotional_message_en', 'emotional_message_am', 'emotional_message_om', 'emotional_message_so',
      'diary_prompt_en', 'diary_prompt_am', 'diary_prompt_om', 'diary_prompt_so',
      'warning_signs_en', 'warning_signs_am', 'warning_signs_om', 'warning_signs_so',
      'when_to_contact_provider_en', 'when_to_contact_provider_am', 'when_to_contact_provider_om', 'when_to_contact_provider_so',
      'is_active', 'reviewed_by',
    ];

    if (req.file) {
      req.body.imageUrl = `/uploads/fetal/${req.file.filename}`;
    }

    const updates = [];
    const values = [];
    let idx = 1;

    for (const field of updatableFields) {
      const camel = field.replace(/_([a-z0-9])/gi, (_, ch) => ch.toUpperCase());
      let value = req.body[camel] !== undefined ? req.body[camel] : req.body[field];

      if (value !== undefined) {
        // FIXED: Convert JS Object/Array into valid JSON string for PostgreSQL
        if (field === 'senses') {
          const parsed = safeJsonParse(value);
          value = JSON.stringify(parsed);
        }
        updates.push(`${field} = $${idx++}`);
        values.push(value);
      }
    }

    if (updates.length === 0) return sendError(res, 400, 'No fields to update.');

    updates.push(`updated_at = now()`);
    values.push(req.params.id);

    const result = await query(
      `UPDATE fetal_weekly_content SET ${updates.join(', ')} WHERE id = $${idx} RETURNING *`,
      values
    );
    if (result.rows.length === 0) return sendError(res, 404, 'Fetal week data not found.');

    const developments = safeJsonParse(req.body.developments, null);
    if (developments) {
      await query('DELETE FROM fetal_development_items WHERE week_id = $1', [req.params.id]);
      await insertDevelopmentItems(req.params.id, developments);
    }

    const checklist = safeJsonParse(req.body.checklist, null);
    if (checklist) {
      await query('DELETE FROM fetal_checklist_items WHERE week_id = $1', [req.params.id]);
      await insertChecklistItems(req.params.id, checklist);
    }

    return sendSuccess(res, 200, 'Fetal week data updated', result.rows[0]);
  } catch (err) {
    next(err);
  }
};

// ── DELETE /api/v1/fetal/:id (admin) ──────────────────────────────────
exports.remove = async (req, res, next) => {
  try {
    const result = await query('DELETE FROM fetal_weekly_content WHERE id = $1 RETURNING id', [req.params.id]);
    if (result.rows.length === 0) return sendError(res, 404, 'Fetal week data not found.');
    return sendSuccess(res, 200, 'Fetal week data deleted');
  } catch (err) {
    next(err);
  }
};

// ── Helpers ─────────────────────────────────────────────────────────
async function insertDevelopmentItems(weekId, items) {
  for (let i = 0; i < items.length; i++) {
    const it = items[i];
    await query(
      `INSERT INTO fetal_development_items
        (week_id, category, title_en, title_am, title_om, title_so, display_order)
       VALUES ($1, $2, $3, $4, $5, $6, $7)`,
      [
        weekId,
        it.category || null,
        it.titleEn ?? it.title_en ?? null,
        it.titleAm ?? it.title_am ?? null,
        it.titleOm ?? it.title_om ?? null,
        it.titleSo ?? it.title_so ?? null,
        it.displayOrder ?? it.display_order ?? i,
      ]
    );
  }
}

async function insertChecklistItems(weekId, items) {
  for (let i = 0; i < items.length; i++) {
    const it = items[i];
    await query(
      `INSERT INTO fetal_checklist_items
        (week_id, title_en, title_am, title_om, title_so, display_order)
       VALUES ($1, $2, $3, $4, $5, $6)`,
      [
        weekId,
        it.titleEn ?? it.title_en ?? null,
        it.titleAm ?? it.title_am ?? null,
        it.titleOm ?? it.title_om ?? null,
        it.titleSo ?? it.title_so ?? null,
        it.displayOrder ?? it.display_order ?? i,
      ]
    );
  }
}
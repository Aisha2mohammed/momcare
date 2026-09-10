/**
 * Utility functions to localize PostgreSQL fetal weekly content records 
 * based on the requested language code ('en', 'am', 'om', 'so').
 */

// Supported language codes; defaults to 'en' if unsupported
const SUPPORTED_LANGUAGES = ['en', 'am', 'om', 'so'];

/**
 * Gets a localized field value from a database row object.
 * Falls back to English ('en') if the localized value is missing or empty.
 *
 * @param {Object} row - Database row object.
 * @param {string} field - Base column name (e.g., 'title', 'summary').
 * @param {string} lang - Language code ('en', 'am', 'om', 'so').
 * @returns {string|null}
 */
const getField = (row, field, lang = 'en') => {
  if (!row) return null;

  const targetLang = SUPPORTED_LANGUAGES.includes(lang) ? lang : 'en';
  const localizedKey = `${field}_${targetLang}`;
  const englishKey = `${field}_en`;

  const localizedVal = row[localizedKey];
  if (localizedVal !== undefined && localizedVal !== null && localizedVal !== '') {
    return localizedVal;
  }

  // Fallback to English value if primary language is empty
  return row[englishKey] ?? null;
};

/**
 * Safely parses stringified JSON into an Array/Object, returning a fallback if parsing fails.
 */
const safeJsonParse = (value, fallback = []) => {
  if (!value) return fallback;
  if (typeof value === 'string') {
    try {
      return JSON.parse(value);
    } catch (err) {
      return fallback;
    }
  }
  return value;
};

/**
 * Transforms a fetal_weekly_content database row into a single localized object.
 *
 * @param {Object} row - Database record from fetal_weekly_content.
 * @param {string} lang - Requested language code ('en', 'am', 'om', 'so').
 * @returns {Object|null} Localized fetal week object.
 */
exports.localizeWeek = (row, lang = 'en') => {
  if (!row) return null;

  const targetLang = SUPPORTED_LANGUAGES.includes(lang) ? lang : 'en';

  // Capitalize first letter for JSON keys inside 'senses' (e.g., 'labelAm', 'labelOm')
  const labelKeySuffix = targetLang.charAt(0).toUpperCase() + targetLang.slice(1);

  // Safely handle stringified or object array for 'senses'
  const rawSenses = safeJsonParse(row.senses, []);
  const localizedSenses = Array.isArray(rawSenses)
    ? rawSenses.map(sense => {
        if (typeof sense === 'string') {
          try {
            sense = JSON.parse(sense);
          } catch (e) {
            return { key: 'sense', label: sense };
          }
        }
        return {
          key: sense.key || null,
          label:
            sense[`label${labelKeySuffix}`] ||
            sense.labelEn ||
            sense.label ||
            null,
        };
      })
    : [];

  return {
    id: row.id,
    week_number: row.week_number,
    trimester: row.trimester,
    image_url: row.image_url,
    image_alt: getField(row, 'image_alt', lang),
    title: getField(row, 'title', lang),
    summary: getField(row, 'summary', lang),
    baby_length_cm: row.baby_length_cm,
    daysRemaining: row.days_remaining, // Add field
    heartRate: row.heart_rate,
    baby_weight_g: row.baby_weight_g,
    size_comparison: getField(row, 'size_comparison', lang),
    milestone: getField(row, 'milestone', lang),
    physical_development: getField(row, 'physical_development', lang),
    brain_dev: getField(row, 'brain_dev', lang),
    heart_dev: getField(row, 'heart_dev', lang),
    organ_dev: getField(row, 'organ_dev', lang),
    bone_muscle_dev: getField(row, 'bone_muscle_dev', lang),
    movement: getField(row, 'movement', lang),
    senses: localizedSenses,
    maternal_changes: getField(row, 'maternal_changes', lang),
    common_symptoms: getField(row, 'common_symptoms', lang),
    health_tip: getField(row, 'health_tip', lang),
    antenatal_care: getField(row, 'antenatal_care', lang),
    screening_information: getField(row, 'screening_information', lang),
    bonding_activity_title: getField(row, 'bonding_activity_title', lang),
    bonding_activity_description: getField(row, 'bonding_activity_description', lang),
    emotional_message: getField(row, 'emotional_message', lang),
    diary_prompt: getField(row, 'diary_prompt', lang),
    warning_signs: getField(row, 'warning_signs', lang),
    when_to_contact_provider: getField(row, 'when_to_contact_provider', lang),
    is_active: row.is_active,
    created_at: row.created_at,
    updated_at: row.updated_at,
  };
};

/**
 * Transforms a fetal_development_items database row into a localized object.
 *
 * @param {Object} item - Database record from fetal_development_items.
 * @param {string} lang - Requested language code ('en', 'am', 'om', 'so').
 * @returns {Object|null}
 */
exports.localizeDevelopmentItem = (item, lang = 'en') => {
  if (!item) return null;

  return {
    id: item.id,
    week_id: item.week_id,
    category: item.category,
    title: getField(item, 'title', lang),
    display_order: item.display_order,
  };
};

/**
 * Transforms a fetal_checklist_items database row into a localized object.
 *
 * @param {Object} item - Database record from fetal_checklist_items.
 * @param {string} lang - Requested language code ('en', 'am', 'om', 'so').
 * @returns {Object|null}
 */
exports.localizeChecklistItem = (item, lang = 'en') => {
  if (!item) return null;

  return {
    id: item.id,
    week_id: item.week_id,
    title: getField(item, 'title', lang),
    display_order: item.display_order,
  };
};
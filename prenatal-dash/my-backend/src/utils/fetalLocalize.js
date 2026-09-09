// utils/fetalLocalize.js
// Central list of supported languages + the fields that are localized.
// en = English, am = Amharic, om = Afan Oromo, so = Af-Soomaali

const SUPPORTED_LANGS = ['en', 'am', 'om', 'so'];
const DEFAULT_LANG = 'am';

// Base field names (without the _xx suffix) that exist on
// fetal_weekly_content and are localized per-language.
const LOCALIZED_BASE_FIELDS = [
  'title',
  'summary',
  'size_comparison',
  'movement',
  'maternal_changes',
  'common_symptoms',
  'health_tip',
  'antenatal_care',
  'screening_information',
  'bonding_activity_title',
  'bonding_activity_description',
  'warning_signs',
  'when_to_contact_provider',
  'image_alt',
  'milestone',
  'physical_development',
  'brain_dev',
  'heart_dev',
  'organ_dev',
  'bone_muscle_dev',
  'emotional_message',
  'diary_prompt',
];

// Same idea for the child-table rows.
const LOCALIZED_ITEM_FIELDS = ['title']; // checklist items
const LOCALIZED_DEV_ITEM_FIELDS = ['title']; // development items (extend with 'description' if you add it)

function resolveLang(lang) {
  return SUPPORTED_LANGS.includes(lang) ? lang : DEFAULT_LANG;
}

// Flattens week_row.<field>_<lang> -> week_row.<field>, falling back to
// the default language if a translation is missing, and strips the
// raw *_en/_am/_om/_so columns out of the response so the API stays clean.
function localizeWeek(row, lang) {
  const l = resolveLang(lang);
  const out = { ...row };

  for (const field of LOCALIZED_BASE_FIELDS) {
    out[field] = row[`${field}_${l}`] || row[`${field}_${DEFAULT_LANG}`] || '';
    for (const code of SUPPORTED_LANGS) delete out[`${field}_${code}`];
  }

  return out;
}

function localizeDevelopmentItem(item, lang) {
  const l = resolveLang(lang);
  const out = { ...item };
  for (const field of LOCALIZED_DEV_ITEM_FIELDS) {
    out[field] = item[`${field}_${l}`] || item[`${field}_${DEFAULT_LANG}`] || '';
    for (const code of SUPPORTED_LANGS) delete out[`${field}_${code}`];
  }
  return out;
}

function localizeChecklistItem(item, lang) {
  const l = resolveLang(lang);
  const out = { ...item };
  for (const field of LOCALIZED_ITEM_FIELDS) {
    out[field] = item[`${field}_${l}`] || item[`${field}_${DEFAULT_LANG}`] || '';
    for (const code of SUPPORTED_LANGS) delete out[`${field}_${code}`];
  }
  return out;
}

module.exports = {
  SUPPORTED_LANGS,
  DEFAULT_LANG,
  LOCALIZED_BASE_FIELDS,
  resolveLang,
  localizeWeek,
  localizeDevelopmentItem,
  localizeChecklistItem,
};
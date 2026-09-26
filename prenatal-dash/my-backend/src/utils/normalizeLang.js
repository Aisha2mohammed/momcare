/**
 * Canonical language code normalization.
 *
 * The project standardizes on ISO 639-1 codes: 'om' for Oromo.
 * Older code/clients (mobile app, admin panel) historically used 'or'.
 * This maps the legacy 'or' alias to the canonical 'om' so both work.
 */
exports.normalizeLang = (lang) => {
  if (lang === 'or') return 'om';
  return lang;
};
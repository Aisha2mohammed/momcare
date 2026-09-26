/**
 * Upgrade music_tracks from the original 2025 schema to the rich multilingual
 * schema the API controller (music.controller.js) and the admin
 * MusicLibraryManager expect.
 *
 * Original columns: title_am, title_or, title_en, category, duration,
 *                   thumbnail_url, media_url, is_active
 * Target columns:   title_am/en/om/so, description_am/en/om/so,
 *                   audio_en/am/om/so_url, image_url, duration_seconds,
 *                   benefits_am/en/om/so, is_active, is_featured, display_order
 *
 * Renames preserve existing data; the remaining columns are added empty.
 * `duration` was always stored in seconds (e.g. 600 = 10 min).
 */
exports.up = async function (knex) {
  await knex.schema.alterTable('music_tracks', (table) => {
    table.renameColumn('title_or', 'title_om');
    table.renameColumn('thumbnail_url', 'image_url');
    table.renameColumn('media_url', 'audio_en_url');
    table.renameColumn('duration', 'duration_seconds');
  });

  await knex.schema.alterTable('music_tracks', (table) => {
    table.string('title_so', 500);
    table.text('description_en');
    table.text('description_am');
    table.text('description_om');
    table.text('description_so');
    table.string('audio_am_url', 500);
    table.string('audio_om_url', 500);
    table.string('audio_so_url', 500);
    table.text('benefits_en');
    table.text('benefits_am');
    table.text('benefits_om');
    table.text('benefits_so');
    table.boolean('is_featured').defaultTo(false);
    table.integer('display_order').defaultTo(0);
  });
};

exports.down = async function (knex) {
  await knex.schema.alterTable('music_tracks', (table) => {
    table.dropColumn('title_so');
    table.dropColumn('description_en');
    table.dropColumn('description_am');
    table.dropColumn('description_om');
    table.dropColumn('description_so');
    table.dropColumn('audio_am_url');
    table.dropColumn('audio_om_url');
    table.dropColumn('audio_so_url');
    table.dropColumn('benefits_en');
    table.dropColumn('benefits_am');
    table.dropColumn('benefits_om');
    table.dropColumn('benefits_so');
    table.dropColumn('is_featured');
    table.dropColumn('display_order');
  });

  await knex.schema.alterTable('music_tracks', (table) => {
    table.renameColumn('title_om', 'title_or');
    table.renameColumn('image_url', 'thumbnail_url');
    table.renameColumn('audio_en_url', 'media_url');
    table.renameColumn('duration_seconds', 'duration');
  });
};

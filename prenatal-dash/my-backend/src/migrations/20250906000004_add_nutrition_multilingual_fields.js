// Migration: Add Somali fields, why_important in 4 languages, hydration in 4 languages, and pdf_url
// Run: npx knex migrate:latest

exports.up = async function (knex) {
  await knex.schema.alterTable('nutrition_content', (table) => {
    // Somali language fields for core content
    table.string('title_so', 500).nullable();
    table.text('body_so').nullable();
    table.text('reason_so').nullable();

    // 'Why it is important' in 4 languages
    table.text('why_important_am').nullable();
    table.text('why_important_or').nullable();
    table.text('why_important_en').nullable();
    table.text('why_important_so').nullable();

    // 'Hydration' advice in 4 languages
    table.text('hydration_am').nullable();
    table.text('hydration_or').nullable();
    table.text('hydration_en').nullable();
    table.text('hydration_so').nullable();

    // PDF attachment URL
    table.string('pdf_url', 500).nullable();
  });
};

exports.down = async function (knex) {
  await knex.schema.alterTable('nutrition_content', (table) => {
    table.dropColumn('title_so');
    table.dropColumn('body_so');
    table.dropColumn('reason_so');
    table.dropColumn('why_important_am');
    table.dropColumn('why_important_or');
    table.dropColumn('why_important_en');
    table.dropColumn('why_important_so');
    table.dropColumn('hydration_am');
    table.dropColumn('hydration_or');
    table.dropColumn('hydration_en');
    table.dropColumn('hydration_so');
    table.dropColumn('pdf_url');
  });
};

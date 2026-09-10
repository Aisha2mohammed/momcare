// Migration: Add rich nutrition fields
// Run: npx knex migrate:latest

exports.up = async function (knex) {
  await knex.schema.alterTable('nutrition_content', (table) => {
    // 'eat' | 'avoid' — used by mobile app tabs
    table.string('type', 20).defaultTo('eat');

    // Emoji displayed on nutrient card (e.g. 🥛)
    table.string('emoji', 10).defaultTo('🥗');

    // Short nutrient category label shown in caps (e.g. CALCIUM, IRON)
    table.string('nutrient_type', 255).defaultTo('');

    // Optional specific week (within trimester)
    table.integer('week').nullable();

    // Separate video URL (image_url stays for thumbnail)
    table.string('video_url', 500).nullable();

    // Title for the video tab card
    table.string('video_title', 500).nullable();

    // Why to avoid this (shown on avoid-tab detail page)
    table.text('reason_am').nullable();
    table.text('reason_or').nullable();
    table.text('reason_en').nullable();

    // Flat list of food names (JSON array of strings — quick fallback)
    // e.g. ["Milk", "Yogurt", "Cheese"]
    table.jsonb('foods_json').nullable();

    // Rich structured sections:
    // [{ type, emoji, description, foods: [{ name, name_am, name_latin,
    //    image_url, benefit, benefit_label, why_include, tip }],
    //    video_url, video_title }]
    table.jsonb('nutrient_sections_json').nullable();

    // Index for type filter
    table.index(['type', 'trimester', 'is_published']);
  });
};

exports.down = async function (knex) {
  await knex.schema.alterTable('nutrition_content', (table) => {
    table.dropColumn('type');
    table.dropColumn('emoji');
    table.dropColumn('nutrient_type');
    table.dropColumn('week');
    table.dropColumn('video_url');
    table.dropColumn('video_title');
    table.dropColumn('reason_am');
    table.dropColumn('reason_or');
    table.dropColumn('reason_en');
    table.dropColumn('foods_json');
    table.dropColumn('nutrient_sections_json');
  });
};

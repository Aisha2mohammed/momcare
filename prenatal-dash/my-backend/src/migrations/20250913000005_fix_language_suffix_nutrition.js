exports.up = async function (knex) {
  // Rename _or columns to _om in nutrition_weeks
  await knex.schema.alterTable('nutrition_weeks', (table) => {
    table.renameColumn('why_important_or', 'why_important_om');
    table.renameColumn('hydration_or', 'hydration_om');
  });

  // Rename _or columns to _om in nutrition_tips
  await knex.schema.alterTable('nutrition_tips', (table) => {
    table.renameColumn('title_or', 'title_om');
    table.renameColumn('description_or', 'description_om');
    table.renameColumn('description_label_or', 'description_label_om');
    table.renameColumn('description_value_or', 'description_value_om');
    table.renameColumn('why_important_or', 'why_important_om');
  });
};

exports.down = async function (knex) {
  // Rename back to _or
  await knex.schema.alterTable('nutrition_weeks', (table) => {
    table.renameColumn('why_important_om', 'why_important_or');
    table.renameColumn('hydration_om', 'hydration_or');
  });

  await knex.schema.alterTable('nutrition_tips', (table) => {
    table.renameColumn('title_om', 'title_or');
    table.renameColumn('description_om', 'description_or');
    table.renameColumn('description_label_om', 'description_label_or');
    table.renameColumn('description_value_om', 'description_value_or');
    table.renameColumn('why_important_om', 'why_important_or');
  });
};
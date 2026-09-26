exports.up = async function (knex) {
  // exercise_weeks: _or -> _om
  await knex.schema.alterTable('exercise_weeks', (table) => {
    table.renameColumn('why_important_or', 'why_important_om');
    table.renameColumn('exercise_tips_or', 'exercise_tips_om');
  });

  // exercises: _or -> _om
  await knex.schema.alterTable('exercises', (table) => {
    table.renameColumn('title_or', 'title_om');
    table.renameColumn('description_or', 'description_om');
    table.renameColumn('description_label_or', 'description_label_om');
    table.renameColumn('description_value_or', 'description_value_om');
    table.renameColumn('why_important_or', 'why_important_om');
  });

  // sleep_weeks: _or -> _om
  await knex.schema.alterTable('sleep_weeks', (table) => {
    table.renameColumn('why_important_or', 'why_important_om');
    table.renameColumn('sleeping_tips_or', 'sleeping_tips_om');
  });

  // sleep_tips: _or -> _om
  await knex.schema.alterTable('sleep_tips', (table) => {
    table.renameColumn('title_or', 'title_om');
    table.renameColumn('description_or', 'description_om');
    table.renameColumn('why_important_or', 'why_important_om');
    table.renameColumn('tips_or', 'tips_om');
  });
};

exports.down = async function (knex) {
  await knex.schema.alterTable('sleep_tips', (table) => {
    table.renameColumn('title_om', 'title_or');
    table.renameColumn('description_om', 'description_or');
    table.renameColumn('why_important_om', 'why_important_or');
    table.renameColumn('tips_om', 'tips_or');
  });

  await knex.schema.alterTable('sleep_weeks', (table) => {
    table.renameColumn('why_important_om', 'why_important_or');
    table.renameColumn('sleeping_tips_om', 'sleeping_tips_or');
  });

  await knex.schema.alterTable('exercises', (table) => {
    table.renameColumn('title_om', 'title_or');
    table.renameColumn('description_om', 'description_or');
    table.renameColumn('description_label_om', 'description_label_or');
    table.renameColumn('description_value_om', 'description_value_or');
    table.renameColumn('why_important_om', 'why_important_or');
  });

  await knex.schema.alterTable('exercise_weeks', (table) => {
    table.renameColumn('why_important_om', 'why_important_or');
    table.renameColumn('exercise_tips_om', 'exercise_tips_or');
  });
};
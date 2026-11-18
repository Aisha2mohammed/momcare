exports.up = async function up(knex) {
  await knex.schema.alterTable('appointments', (table) => {
    table.integer('duration_minutes').nullable();
  });

  await knex.raw(`
    ALTER TABLE appointments
    ADD CONSTRAINT appointments_duration_minutes_check
    CHECK (
      duration_minutes IS NULL
      OR (duration_minutes >= 5 AND duration_minutes <= 240)
    )
  `);
};

exports.down = async function down(knex) {
  await knex.raw(`
    ALTER TABLE appointments
    DROP CONSTRAINT IF EXISTS appointments_duration_minutes_check
  `);

  await knex.schema.alterTable('appointments', (table) => {
    table.dropColumn('duration_minutes');
  });
};

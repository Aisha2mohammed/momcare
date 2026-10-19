/**
 * Extend `user_health_logs` into a full pregnancy-tracker record.
 *
 * The table started as a lightweight daily log (weight_kg, mood,
 * symptoms_json, symptom_severity). The tracker also needs blood pressure,
 * kick counts and free-text notes, so this adds four nullable columns:
 *
 *   blood_pressure_systolic  / blood_pressure_diastolic  (mmHg)
 *   kick_count               (kicks recorded in the session/day)
 *   notes                    (free text, max 1000 chars enforced at the API)
 *
 * Every column is nullable so existing rows and the current create path keep
 * working unchanged; `weight_kg` already exists as numeric(5,2) and is reused
 * as-is. No data is modified.
 */
exports.up = async function (knex) {
  await knex.schema.alterTable('user_health_logs', (table) => {
    table.integer('blood_pressure_systolic');
    table.integer('blood_pressure_diastolic');
    table.integer('kick_count');
    table.text('notes');
  });
};

exports.down = async function (knex) {
  await knex.schema.alterTable('user_health_logs', (table) => {
    table.dropColumn('notes');
    table.dropColumn('kick_count');
    table.dropColumn('blood_pressure_diastolic');
    table.dropColumn('blood_pressure_systolic');
  });
};

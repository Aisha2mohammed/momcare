/**
 * Phase 1 appointment integrity: prevent two active appointments for the same
 * doctor at the same start time.
 *
 * Only `pending` and `confirmed` rows are covered. Rejected/cancelled rows do
 * not block a rebooking of the same time, and terminal/historical rows are
 * ignored. The application also serializes bookings per doctor inside a
 * transaction; this index is the database-level backstop for concurrent
 * requests and any future code paths.
 *
 * The `appointments` table stores only a start time (no end time/duration), so
 * overlapping *ranges* cannot be detected. That limitation is intentional for
 * Phase 1; availability/duration enforcement belongs to Phase 2.
 */
exports.up = async function (knex) {
  const duplicates = await knex.raw(`
    SELECT doctor_id, slot_datetime, COUNT(*) AS count
    FROM appointments
    WHERE status IN ('pending', 'confirmed')
    GROUP BY doctor_id, slot_datetime
    HAVING COUNT(*) > 1
    LIMIT 5
  `);

  if (duplicates.rows.length > 0) {
    throw new Error(
      'Cannot create appointments_doctor_slot_active_unique: duplicate active appointments exist. ' +
        'Resolve duplicate pending/confirmed rows for the same doctor and slot_datetime first.'
    );
  }

  await knex.raw(`
    CREATE UNIQUE INDEX IF NOT EXISTS appointments_doctor_slot_active_unique
    ON appointments (doctor_id, slot_datetime)
    WHERE status IN ('pending', 'confirmed')
  `);
};

exports.down = async function (knex) {
  await knex.raw('DROP INDEX IF EXISTS appointments_doctor_slot_active_unique');
};

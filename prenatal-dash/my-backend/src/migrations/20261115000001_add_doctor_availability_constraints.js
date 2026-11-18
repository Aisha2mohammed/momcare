exports.up = async function (knex) {
  await knex.raw(`
    ALTER TABLE doctor_availability_slots
      ADD CONSTRAINT doctor_availability_slots_day_of_week_check
        CHECK (day_of_week BETWEEN 0 AND 6) NOT VALID,
      ADD CONSTRAINT doctor_availability_slots_time_order_check
        CHECK (start_time < end_time) NOT VALID,
      ADD CONSTRAINT doctor_availability_slots_duration_range_check
        CHECK (
          slot_duration_minutes IS NULL
          OR slot_duration_minutes BETWEEN 5 AND 240
        ) NOT VALID
  `);

  await knex.raw(`
    CREATE INDEX IF NOT EXISTS doctor_availability_slots_lookup_idx
    ON doctor_availability_slots (doctor_id, day_of_week, is_active, start_time, end_time)
  `);

  await knex.raw(`
    CREATE OR REPLACE FUNCTION enforce_doctor_availability_duration()
    RETURNS trigger AS $$
    BEGIN
      IF NEW.slot_duration_minutes IS NULL THEN
        IF TG_OP = 'UPDATE' AND OLD.slot_duration_minutes IS NULL THEN
          RETURN NEW;
        END IF;
        RAISE EXCEPTION 'slot_duration_minutes is required'
          USING ERRCODE = '23514';
      END IF;

      IF NEW.slot_duration_minutes < 5 OR NEW.slot_duration_minutes > 240 THEN
        RAISE EXCEPTION 'slot_duration_minutes must be between 5 and 240'
          USING ERRCODE = '23514';
      END IF;

      RETURN NEW;
    END;
    $$ LANGUAGE plpgsql
  `);

  await knex.raw(`
    DROP TRIGGER IF EXISTS doctor_availability_slots_duration_guard
    ON doctor_availability_slots
  `);

  await knex.raw(`
    CREATE TRIGGER doctor_availability_slots_duration_guard
    BEFORE INSERT OR UPDATE ON doctor_availability_slots
    FOR EACH ROW
    EXECUTE FUNCTION enforce_doctor_availability_duration()
  `);
};

exports.down = async function (knex) {
  await knex.raw(`
    DROP TRIGGER IF EXISTS doctor_availability_slots_duration_guard
    ON doctor_availability_slots
  `);
  await knex.raw('DROP FUNCTION IF EXISTS enforce_doctor_availability_duration()');
  await knex.raw('DROP INDEX IF EXISTS doctor_availability_slots_lookup_idx');
  await knex.raw(`
    ALTER TABLE doctor_availability_slots
      DROP CONSTRAINT IF EXISTS doctor_availability_slots_day_of_week_check,
      DROP CONSTRAINT IF EXISTS doctor_availability_slots_time_order_check,
      DROP CONSTRAINT IF EXISTS doctor_availability_slots_duration_range_check
  `);
};

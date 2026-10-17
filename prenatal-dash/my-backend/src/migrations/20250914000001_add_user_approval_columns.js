/**
 * Add mother approval workflow columns to `users`.
 *
 * Until now only doctors were gated: a new doctor's `users` row was created
 * `status='active'` and the approval state lived on
 * `doctor_profiles.approval_status` (+ `approved_by`/`approved_at`).
 * Mothers had no approval step at all — they signed up straight to
 * `status='active'`.
 *
 * From here on new mothers start at `status='pending'` and an admin moves them
 * to `'active'` (approve) or `'rejected'` (reject). These three nullable
 * columns record who approved a mother and when, and when a rejection
 * happened. `approved_by` mirrors `doctor_profiles.approved_by`: a FK to
 * `users(id)` that is nulled out if the admin account is later deleted.
 *
 * All columns are nullable, so the existing rows keep working untouched and
 * the mobile/admin clients only need to care about `users.status`.
 */
exports.up = async function (knex) {
  await knex.schema.alterTable('users', (table) => {
    table.uuid('approved_by').references('id').inTable('users').onDelete('SET NULL');
    table.timestamp('approved_at');
    table.timestamp('rejected_at');
  });
};

exports.down = async function (knex) {
  await knex.schema.alterTable('users', (table) => {
    table.dropColumn('rejected_at');
    table.dropColumn('approved_at');
    table.dropColumn('approved_by');
  });
};

exports.up = async function (knex) {
  await knex.schema.createTable('users', (table) => {
    table.uuid('id').primary().defaultTo(knex.raw('gen_random_uuid()'));
    table.string('role', 20).notNullable().defaultTo('mother');
    table.string('name', 255);
    table.string('phone', 50).unique();
    table.string('email', 255).unique();
    table.string('password_hash', 255);
    table.string('language', 5).defaultTo('am');
    table.string('status', 20).defaultTo('active');
    table.string('firebase_uid', 255).unique();
    table.string('fcm_token', 500);
    table.timestamp('created_at').defaultTo(knex.fn.now());
    table.timestamp('updated_at').defaultTo(knex.fn.now());
    table.index('role');
    table.index('status');
  });

  await knex.schema.createTable('mother_profiles', (table) => {
    table.uuid('id').primary().defaultTo(knex.raw('gen_random_uuid()'));
    table.uuid('user_id').notNullable().references('id').inTable('users').onDelete('CASCADE');
    table.date('lmp_date');
    table.date('due_date');
    table.integer('gestational_week');
    table.string('city', 100);
    table.string('profile_photo', 500);
    table.uuid('assigned_doctor_id').references('id').inTable('users').onDelete('SET NULL');
    table.timestamp('created_at').defaultTo(knex.fn.now());
    table.timestamp('updated_at').defaultTo(knex.fn.now());
    table.unique('user_id');
  });

  await knex.schema.createTable('health_providers', (table) => {
    table.uuid('id').primary().defaultTo(knex.raw('gen_random_uuid()'));
    table.string('name', 255).notNullable();
    table.string('location', 500);
    table.string('contact', 100);
    table.text('service_description');
    table.string('status', 20).defaultTo('active');
    table.timestamp('created_at').defaultTo(knex.fn.now());
    table.timestamp('updated_at').defaultTo(knex.fn.now());
    table.index('status');
  });

  await knex.schema.createTable('doctor_profiles', (table) => {
    table.uuid('id').primary().defaultTo(knex.raw('gen_random_uuid()'));
    table.uuid('user_id').notNullable().references('id').inTable('users').onDelete('CASCADE');
    table.uuid('health_provider_id').references('id').inTable('health_providers').onDelete('SET NULL');
    table.string('license_number', 100);
    table.string('specialization', 255);
    table.string('location', 500);
    table.jsonb('working_hours_json');
    table.jsonb('credential_docs_json');
    table.string('approval_status', 20).defaultTo('pending');
    table.uuid('approved_by').references('id').inTable('users').onDelete('SET NULL');
    table.timestamp('approved_at');
    table.string('photo_url', 500);
    table.text('bio');
    table.timestamp('created_at').defaultTo(knex.fn.now());
    table.timestamp('updated_at').defaultTo(knex.fn.now());
    table.unique('user_id');
    table.index('approval_status');
  });

  await knex.schema.createTable('doctor_availability_slots', (table) => {
    table.uuid('id').primary().defaultTo(knex.raw('gen_random_uuid()'));
    table.uuid('doctor_id').notNullable().references('id').inTable('users').onDelete('CASCADE');
    table.integer('day_of_week').notNullable();
    table.time('start_time').notNullable();
    table.time('end_time').notNullable();
    table.integer('slot_duration_minutes').defaultTo(30);
    table.boolean('is_active').defaultTo(true);
    table.timestamp('created_at').defaultTo(knex.fn.now());
    table.timestamp('updated_at').defaultTo(knex.fn.now());
    table.index(['doctor_id', 'is_active']);
  });

  await knex.schema.createTable('appointments', (table) => {
    table.uuid('id').primary().defaultTo(knex.raw('gen_random_uuid()'));
    table.uuid('mother_id').notNullable().references('id').inTable('users').onDelete('CASCADE');
    table.uuid('doctor_id').notNullable().references('id').inTable('users').onDelete('CASCADE');
    table.timestamp('slot_datetime').notNullable();
    table.string('status', 20).defaultTo('pending');
    table.timestamp('alternative_time_suggested');
    table.text('notes');
    table.timestamp('created_at').defaultTo(knex.fn.now());
    table.timestamp('updated_at').defaultTo(knex.fn.now());
    table.index(['mother_id', 'status']);
    table.index(['doctor_id', 'status']);
  });

  await knex.schema.createTable('clinical_records', (table) => {
    table.uuid('id').primary().defaultTo(knex.raw('gen_random_uuid()'));
    table.uuid('appointment_id').notNullable().references('id').inTable('appointments').onDelete('CASCADE');
    table.text('notes_text');
    table.text('prescription_text');
    table.string('prescription_file_url', 500);
    table.string('risk_indicator', 20).defaultTo('low');
    table.timestamp('created_at').defaultTo(knex.fn.now());
    table.index('risk_indicator');
  });

  await knex.schema.createTable('chat_messages', (table) => {
    table.uuid('id').primary().defaultTo(knex.raw('gen_random_uuid()'));
    table.uuid('mother_id').notNullable().references('id').inTable('users').onDelete('CASCADE');
    table.uuid('doctor_id').notNullable().references('id').inTable('users').onDelete('CASCADE');
    table.string('sender_role', 20).notNullable();
    table.text('message_text');
    table.string('attachment_url', 500);
    table.boolean('is_read').defaultTo(false);
    table.timestamp('created_at').defaultTo(knex.fn.now());
    table.index(['mother_id', 'doctor_id', 'created_at']);
  });

  await knex.schema.createTable('nutrition_content', (table) => {
    table.uuid('id').primary().defaultTo(knex.raw('gen_random_uuid()'));
    table.integer('trimester');
    table.string('title_am', 500);
    table.string('title_or', 500);
    table.string('title_en', 500);
    table.text('body_am');
    table.text('body_or');
    table.text('body_en');
    table.string('image_url', 500);
    table.boolean('is_published').defaultTo(false);
    table.timestamp('created_at').defaultTo(knex.fn.now());
    table.timestamp('updated_at').defaultTo(knex.fn.now());
    table.index(['trimester', 'is_published']);
  });

  await knex.schema.createTable('fetal_tracker_content', (table) => {
    table.uuid('id').primary().defaultTo(knex.raw('gen_random_uuid()'));
    table.integer('week_number').unique().notNullable();
    table.string('size_comparison', 255);
    table.text('milestone_am');
    table.text('milestone_or');
    table.text('milestone_en');
    table.text('tips_am');
    table.text('tips_or');
    table.text('tips_en');
    table.string('image_url', 500);
    table.timestamp('created_at').defaultTo(knex.fn.now());
    table.timestamp('updated_at').defaultTo(knex.fn.now());
  });

  await knex.schema.createTable('exercise_content', (table) => {
    table.uuid('id').primary().defaultTo(knex.raw('gen_random_uuid()'));
    table.string('name_am', 500);
    table.string('name_or', 500);
    table.string('name_en', 500);
    table.jsonb('trimester_flags');
    table.integer('duration_min');
    table.text('safety_notes_am');
    table.text('safety_notes_or');
    table.text('safety_notes_en');
    table.string('media_url', 500);
    table.boolean('is_published').defaultTo(false);
    table.timestamp('created_at').defaultTo(knex.fn.now());
    table.timestamp('updated_at').defaultTo(knex.fn.now());
    table.index('is_published');
  });

  await knex.schema.createTable('sleep_tips', (table) => {
    table.uuid('id').primary().defaultTo(knex.raw('gen_random_uuid()'));
    table.integer('trimester');
    table.string('title_am', 500);
    table.string('title_or', 500);
    table.string('title_en', 500);
    table.text('description_am');
    table.text('description_or');
    table.text('description_en');
    table.string('illustration_url', 500);
    table.timestamp('created_at').defaultTo(knex.fn.now());
    table.timestamp('updated_at').defaultTo(knex.fn.now());
    table.index('trimester');
  });

  await knex.schema.createTable('music_tracks', (table) => {
    table.uuid('id').primary().defaultTo(knex.raw('gen_random_uuid()'));
    table.string('title_am', 500);
    table.string('title_or', 500);
    table.string('title_en', 500);
    table.string('category', 100);
    table.integer('duration');
    table.string('thumbnail_url', 500);
    table.string('media_url', 500);
    table.boolean('is_active').defaultTo(true);
    table.timestamp('created_at').defaultTo(knex.fn.now());
    table.timestamp('updated_at').defaultTo(knex.fn.now());
    table.index(['category', 'is_active']);
  });

  await knex.schema.createTable('notifications', (table) => {
    table.uuid('id').primary().defaultTo(knex.raw('gen_random_uuid()'));
    table.string('title_am', 500);
    table.string('title_or', 500);
    table.string('title_en', 500);
    table.text('body_am');
    table.text('body_or');
    table.text('body_en');
    table.string('target_group', 50).defaultTo('all');
    table.uuid('target_user_id').references('id').inTable('users').onDelete('SET NULL');
    table.string('sent_by', 50).defaultTo('system');
    table.timestamp('scheduled_at');
    table.timestamp('sent_at');
    table.integer('open_count').defaultTo(0);
    table.timestamp('created_at').defaultTo(knex.fn.now());
    table.index(['target_group', 'scheduled_at']);
  });

  await knex.schema.createTable('reminders', (table) => {
    table.uuid('id').primary().defaultTo(knex.raw('gen_random_uuid()'));
    table.uuid('user_id').notNullable().references('id').inTable('users').onDelete('CASCADE');
    table.string('type', 50).notNullable();
    table.text('message');
    table.timestamp('scheduled_at');
    table.timestamp('sent_at');
    table.timestamp('created_at').defaultTo(knex.fn.now());
    table.index(['user_id', 'type']);
  });

  await knex.schema.createTable('emergency_contacts', (table) => {
    table.uuid('id').primary().defaultTo(knex.raw('gen_random_uuid()'));
    table.uuid('mother_id').notNullable().references('id').inTable('users').onDelete('CASCADE');
    table.string('contact_name', 255).notNullable();
    table.string('phone', 50).notNullable();
    table.string('relationship', 100);
    table.timestamp('created_at').defaultTo(knex.fn.now());
    table.index('mother_id');
  });

  await knex.schema.createTable('health_tips', (table) => {
    table.uuid('id').primary().defaultTo(knex.raw('gen_random_uuid()'));
    table.string('title_am', 500);
    table.string('title_or', 500);
    table.string('title_en', 500);
    table.text('warning_signs_am');
    table.text('warning_signs_or');
    table.text('warning_signs_en');
    table.text('first_aid_am');
    table.text('first_aid_or');
    table.text('first_aid_en');
    table.timestamp('created_at').defaultTo(knex.fn.now());
    table.timestamp('updated_at').defaultTo(knex.fn.now());
  });

  await knex.schema.createTable('user_health_logs', (table) => {
    table.uuid('id').primary().defaultTo(knex.raw('gen_random_uuid()'));
    table.uuid('mother_id').notNullable().references('id').inTable('users').onDelete('CASCADE');
    table.date('log_date').notNullable();
    table.decimal('weight_kg', 5, 2);
    table.string('mood', 50);
    table.jsonb('symptoms_json');
    table.integer('symptom_severity'); // 1-10
    table.timestamp('created_at').defaultTo(knex.fn.now());
    table.index(['mother_id', 'log_date']);
  });

  await knex.schema.createTable('community_groups', (table) => {
    table.uuid('id').primary().defaultTo(knex.raw('gen_random_uuid()'));
    table.integer('trimester_group');
    table.string('name', 255).notNullable();
    table.timestamp('created_at').defaultTo(knex.fn.now());
  });

  await knex.schema.createTable('community_posts', (table) => {
    table.uuid('id').primary().defaultTo(knex.raw('gen_random_uuid()'));
    table.uuid('user_id').notNullable().references('id').inTable('users').onDelete('CASCADE');
    table.uuid('group_id').references('id').inTable('community_groups').onDelete('CASCADE');
    table.text('content').notNullable();
    table.boolean('is_anonymous').defaultTo(false);
    table.boolean('is_deleted').defaultTo(false);
    table.uuid('deleted_by_admin_id').references('id').inTable('users').onDelete('SET NULL');
    table.timestamp('created_at').defaultTo(knex.fn.now());
    table.index('group_id');
    table.index('user_id');
  });

  await knex.schema.createTable('community_comments', (table) => {
    table.uuid('id').primary().defaultTo(knex.raw('gen_random_uuid()'));
    table.uuid('post_id').notNullable().references('id').inTable('community_posts').onDelete('CASCADE');
    table.uuid('user_id').notNullable().references('id').inTable('users').onDelete('CASCADE');
    table.text('content').notNullable();
    table.boolean('is_deleted').defaultTo(false);
    table.timestamp('created_at').defaultTo(knex.fn.now());
    table.index('post_id');
  });

  await knex.schema.createTable('audit_logs', (table) => {
    table.uuid('id').primary().defaultTo(knex.raw('gen_random_uuid()'));
    table.uuid('admin_id').references('id').inTable('users').onDelete('SET NULL');
    table.string('action_type', 100).notNullable();
    table.string('target_table', 100);
    table.uuid('target_id');
    table.jsonb('details_json');
    table.timestamp('created_at').defaultTo(knex.fn.now());
    table.index('admin_id');
    table.index('action_type');
    table.index('created_at');
  });
};

exports.down = async function (knex) {
  const tables = [
    'audit_logs', 'community_comments', 'community_posts', 'community_groups',
    'user_health_logs', 'health_tips', 'emergency_contacts', 'reminders',
    'notifications', 'music_tracks', 'sleep_tips', 'exercise_content',
    'fetal_tracker_content', 'nutrition_content', 'chat_messages',
    'clinical_records', 'appointments', 'doctor_availability_slots',
    'doctor_profiles', 'health_providers', 'mother_profiles', 'users'
  ];
  for (const t of tables) {
    await knex.schema.dropTableIfExists(t);
  }
};

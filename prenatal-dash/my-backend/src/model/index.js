/**
 * MaternaLink PostgreSQL Sequelize Models & Table Schemas
 * Central Sequelize initialization, Model loader, and Associations manager
 */

const { Sequelize, DataTypes, Model } = require('sequelize');

// Initialize PostgreSQL connection with Sequelize
const sequelize = process.env.DATABASE_URL
  ? new Sequelize(process.env.DATABASE_URL, {
      dialect: 'postgres',
      logging: process.env.NODE_ENV === 'development' ? (msg) => console.log('📊 Sequelize:', msg) : false,
      pool: {
        max: 20,
        min: 0,
        idle: 30000,
        acquire: 30000,
      },
    })
  : new Sequelize(
      process.env.DB_NAME || 'maternalink',
      process.env.DB_USER || 'postgres',
      process.env.DB_PASSWORD || 'postgres',
      {
        host: process.env.DB_HOST || 'localhost',
        port: parseInt(process.env.DB_PORT, 10) || 5432,
        dialect: 'postgres',
        logging: process.env.NODE_ENV === 'development' ? (msg) => console.log('📊 Sequelize:', msg) : false,
        pool: {
          max: 20,
          min: 0,
          idle: 30000,
          acquire: 30000,
        },
      }
    );

const db = {
  sequelize,
  Sequelize,
  DataTypes,
  Model,
};

// ── 1. Auth & Users ──────────────────────────────────────────────────
db.User = require('./auth/User')(sequelize);
db.Device = require('./auth/Device')(sequelize);

// ── 2. Mother & Health Tracking ──────────────────────────────────────
db.MotherProfile = require('./mother/MotherProfile')(sequelize);
db.UserHealthLog = require('./mother/UserHealthLog')(sequelize);
db.EmergencyContact = require('./mother/EmergencyContact')(sequelize);

// ── 3. Doctor & Provider ─────────────────────────────────────────────
db.DoctorProfile = require('./doctor/DoctorProfile')(sequelize);
db.HealthProvider = require('./doctor/HealthProvider')(sequelize);
db.DoctorAvailabilitySlot = require('./doctor/DoctorAvailabilitySlot')(sequelize);

// ── 4. Appointment & Clinical Records ─────────────────────────────────
db.Appointment = require('./appointment/Appointment')(sequelize);
db.ClinicalRecord = require('./appointment/ClinicalRecord')(sequelize);

// ── 5. Chat & Direct Messaging ───────────────────────────────────────
db.ChatMessage = require('./chat/ChatMessage')(sequelize);
db.DirectMessage = require('./chat/DirectMessage')(sequelize);

// ── 6. Community Hub ─────────────────────────────────────────────────
db.CommunityGroup = require('./community/CommunityGroup')(sequelize);
db.CommunityPost = require('./community/CommunityPost')(sequelize);
db.CommunityComment = require('./community/CommunityComment')(sequelize);
db.CommunityPostLike = require('./community/CommunityPostLike')(sequelize);
db.CommunityRule = require('./community/CommunityRule')(sequelize);

// ── 7. Nutrition Content & Weekly CMS ────────────────────────────────
db.NutritionWeek = require('./nutrition/NutritionWeek')(sequelize);
db.NutritionTip = require('./nutrition/NutritionTip')(sequelize);
db.NutritionContent = require('./nutrition/NutritionContent')(sequelize);

// ── 8. Exercise Content & Weekly CMS ─────────────────────────────────
db.ExerciseWeek = require('./exercise/ExerciseWeek')(sequelize);
db.Exercise = require('./exercise/Exercise')(sequelize);
db.ExerciseContent = require('./exercise/ExerciseContent')(sequelize);

// ── 9. Sleep Content & Weekly CMS ────────────────────────────────────
db.SleepWeek = require('./sleep/SleepWeek')(sequelize);
db.SleepTip = require('./sleep/SleepTip')(sequelize);

// ── 10. Fetal Development Tracker & CMS ──────────────────────────────
db.FetalWeeklyContent = require('./fetal/FetalWeeklyContent')(sequelize);
db.FetalDevelopmentItem = require('./fetal/FetalDevelopmentItem')(sequelize);
db.FetalChecklistItem = require('./fetal/FetalChecklistItem')(sequelize);
db.FetalTrackerContent = require('./fetal/FetalTrackerContent')(sequelize);

// ── 11. Music & Sound Therapy ────────────────────────────────────────
db.MusicTrack = require('./music/MusicTrack')(sequelize);

// ── 12. Health Tips & Warnings ───────────────────────────────────────
db.HealthTip = require('./healthTip/HealthTip')(sequelize);

// ── 13. Notifications & Reminders ────────────────────────────────────
db.Notification = require('./notification/Notification')(sequelize);
db.NotificationRead = require('./notification/NotificationRead')(sequelize);
db.Reminder = require('./notification/Reminder')(sequelize);

// ── 14. Admin & Security Audit ───────────────────────────────────────
db.AuditLog = require('./admin/AuditLog')(sequelize);

// ── Run Model Associations ───────────────────────────────────────────
Object.keys(db).forEach((modelName) => {
  if (db[modelName] && typeof db[modelName].associate === 'function') {
    db[modelName].associate(db);
  }
});

// ── Controller & Router Mappings ─────────────────────────────────────
db.CONTROLLER_TABLE_MAPPING = {
  'auth.controller.js': ['User', 'MotherProfile', 'Device'],
  'mother.controller.js': ['MotherProfile', 'User', 'UserHealthLog', 'EmergencyContact', 'DoctorProfile', 'HealthProvider'],
  'doctor.controller.js': ['DoctorProfile', 'User', 'HealthProvider', 'DoctorAvailabilitySlot', 'Appointment', 'ClinicalRecord'],
  'appointment.controller.js': ['Appointment', 'ClinicalRecord', 'DoctorProfile', 'User'],
  'chat.controller.js': ['ChatMessage', 'User'],
  'community.controller.js': ['CommunityGroup', 'CommunityPost', 'CommunityComment', 'CommunityPostLike', 'CommunityRule', 'DirectMessage', 'User', 'MotherProfile'],
  'emergency.controller.js': ['EmergencyContact', 'HealthTip', 'User'],
  'nutrition.controller.js': ['NutritionTip', 'NutritionWeek', 'NutritionContent'],
  'nutritionWeekController.js': ['NutritionWeek'],
  'exercise.controller.js': ['Exercise', 'ExerciseWeek', 'ExerciseContent'],
  'exerciseWeekController.js': ['ExerciseWeek'],
  'sleep.controller.js': ['SleepTip', 'SleepWeek'],
  'sleepWeekController.js': ['SleepWeek'],
  'fetal.controller.js': ['FetalWeeklyContent', 'FetalDevelopmentItem', 'FetalChecklistItem', 'FetalTrackerContent'],
  'music.controller.js': ['MusicTrack'],
  'healthTip.controller.js': ['HealthTip'],
  'notification.controller.js': ['Notification', 'NotificationRead', 'Reminder', 'Device', 'User'],
  'admin.controller.js': ['User', 'DoctorProfile', 'MotherProfile', 'HealthProvider', 'Appointment', 'AuditLog', 'CommunityPost'],
  'chatbot.controller.js': ['User', 'MotherProfile'],
};

db.ROUTER_TABLE_MAPPING = {
  '/api/v1/auth': ['User', 'MotherProfile', 'Device'],
  '/api/v1/mothers': ['MotherProfile', 'User', 'UserHealthLog', 'EmergencyContact'],
  '/api/v1/doctors': ['DoctorProfile', 'User', 'HealthProvider', 'DoctorAvailabilitySlot'],
  '/api/v1/appointments': ['Appointment', 'ClinicalRecord'],
  '/api/v1/chat': ['ChatMessage'],
  '/api/v1/community': ['CommunityGroup', 'CommunityPost', 'CommunityComment', 'CommunityPostLike', 'CommunityRule', 'DirectMessage'],
  '/api/v1/emergency': ['EmergencyContact', 'HealthTip'],
  '/api/v1/nutrition': ['NutritionTip', 'NutritionWeek', 'NutritionContent'],
  '/api/v1/fetal': ['FetalWeeklyContent', 'FetalDevelopmentItem', 'FetalChecklistItem', 'FetalTrackerContent'],
  '/api/v1/exercise': ['Exercise', 'ExerciseWeek', 'ExerciseContent'],
  '/api/v1/sleep': ['SleepTip', 'SleepWeek'],
  '/api/v1/music': ['MusicTrack'],
  '/api/v1/health-tips': ['HealthTip'],
  '/api/v1/notifications': ['Notification', 'NotificationRead', 'Reminder', 'Device'],
  '/api/v1/admin': ['User', 'DoctorProfile', 'MotherProfile', 'HealthProvider', 'Appointment', 'AuditLog', 'CommunityPost'],
  '/api/v1/chatbot': ['User', 'MotherProfile'],
};

module.exports = db;

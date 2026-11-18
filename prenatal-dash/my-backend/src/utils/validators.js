const { body, param, query, validationResult } = require('express-validator');
const { sendError } = require('./apiResponse');

const validate = (req, res, next) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    const messages = errors.array().map((e) => `${e.path}: ${e.msg}`).join('; ');
    return sendError(res, 422, 'Validation failed', errors.array());
  }
  next();
};

// Auth validators
const registerRules = [
  body('role').optional().isIn(['mother', 'doctor']).withMessage('Role must be mother or doctor'),
  body('phone').notEmpty().withMessage('Phone is required').trim(),
  body('name').optional().trim(),
  body('language').optional().isIn(['am', 'or', 'om', 'en', 'so']).withMessage('Language must be am, or, or en'),
  body('password').optional().isLength({ min: 6 }).withMessage('Password must be at least 6 characters'),
  body('firebaseToken').optional().isString(),
];

const loginRules = [
  body('phone').notEmpty().withMessage('Phone is required').trim(),
  body('password').optional(),
];

const adminLoginRules = [
  body('email').isEmail().withMessage('Valid email is required').normalizeEmail(),
  body('password').notEmpty().withMessage('Password is required'),
];

const otpSendRules = [
  body('phone').notEmpty().withMessage('Phone is required').trim(),
];

const otpVerifyRules = [
  body('phone').notEmpty().withMessage('Phone is required').trim(),
  body('otp').notEmpty().withMessage('OTP is required'),
];

const forgotPasswordRules = [
  body('phone').notEmpty().withMessage('Phone is required').trim(),
];

const resetPasswordRules = [
  body('phone').notEmpty().withMessage('Phone is required').trim(),
  body('otp').notEmpty().withMessage('OTP is required'),
  body('password').isLength({ min: 6 }).withMessage('Password must be at least 6 characters'),
];

// Content validators
const contentRules = [
  body('title_am').optional().notEmpty(),
  body('title_or').optional().notEmpty(),
  body('title_en').optional().notEmpty(),
];

const nutritionRules = [
  ...contentRules,
  body('trimester').optional().isIn([1, 2, 3]).withMessage('Trimester must be 1, 2, or 3'),
];

const fetalRules = [
  body().custom((_, { req }) => {
    const raw = req.body.weekNumber ?? req.body.week_number;
    if (raw === undefined || raw === null || raw === '') {
      throw new Error('Week number is required');
    }
    const num = Number(raw);
    if (!Number.isInteger(num) || num < 1 || num > 42) {
      throw new Error('Week must be between 1 and 42');
    }
    return true;
  }),
];

const musicRules = [
  body('category').optional().isIn(['relaxation', 'meditation', 'lullaby', 'classical', 'nature', 'stories']).withMessage('Invalid category'),
];

const notificationRules = [
  body('title_am').optional(),
  body('body_am').optional(),
  body('target_group').optional().isIn(['all', 'mothers', 'doctors', 'specific_user', 'user', 'trimester', 'week', 'month']),
];

const ISO_DATETIME_WITH_TIMEZONE_RE =
  /T\d{2}:\d{2}(?::\d{2}(?:\.\d+)?)?(?:Z|[+-]\d{2}:?\d{2})$/i;
const TIME_OF_DAY_RE = /^([01]\d|2[0-3]):[0-5]\d(?::00)?$/;
const DATE_ONLY_RE = /^\d{4}-\d{2}-\d{2}$/;

const timeToMinutes = (value) => {
  if (typeof value !== 'string' || !TIME_OF_DAY_RE.test(value)) return null;
  const [hours, minutes] = value.split(':').map(Number);
  return hours * 60 + minutes;
};

const dateOnlyToUtc = (value) => {
  if (typeof value !== 'string' || !DATE_ONLY_RE.test(value)) return null;
  const [year, month, day] = value.split('-').map(Number);
  if (year < 1000 || year > 9999) return null;
  const date = new Date(Date.UTC(year, month - 1, day));
  if (
    date.getUTCFullYear() !== year ||
    date.getUTCMonth() !== month - 1 ||
    date.getUTCDate() !== day
  ) {
    return null;
  }
  return date;
};

const appointmentRules = [
  body('doctorId')
    .notEmpty()
    .withMessage('Doctor ID is required')
    .isUUID()
    .toLowerCase(),
  body('slotDatetime')
    .notEmpty()
    .withMessage('Slot datetime is required')
    .isISO8601({ strict: true, strictSeparator: true })
    .withMessage('slotDatetime must be a valid ISO 8601 datetime')
    .matches(ISO_DATETIME_WITH_TIMEZONE_RE)
    .withMessage('slotDatetime must include Z or an explicit UTC offset'),
];

const availabilityDoctorIdRules = [
  param('id').isUUID().withMessage('Doctor id must be a UUID').toLowerCase(),
];

const availabilitySlotIdRules = [
  param('id').isUUID().withMessage('Doctor id must be a UUID').toLowerCase(),
  param('slotId').isUUID().withMessage('Slot id must be a UUID').toLowerCase(),
];

const availabilityListRules = [
  ...availabilityDoctorIdRules,
  query('includeInactive')
    .optional({ values: 'falsy' })
    .isBoolean()
    .withMessage('includeInactive must be a boolean')
    .toBoolean(),
];

const availableSlotsRules = [
  ...availabilityDoctorIdRules,
  query('from')
    .optional({ values: 'undefined' })
    .isString()
    .withMessage('from must be a date in YYYY-MM-DD format')
    .custom((value) => {
      if (!dateOnlyToUtc(value)) {
        throw new Error('from must be a valid date in YYYY-MM-DD format');
      }
      return true;
    }),
  query('to')
    .optional({ values: 'undefined' })
    .isString()
    .withMessage('to must be a date in YYYY-MM-DD format')
    .custom((value) => {
      if (!dateOnlyToUtc(value)) {
        throw new Error('to must be a valid date in YYYY-MM-DD format');
      }
      return true;
    }),
  query().custom((_, { req }) => {
    if (req.query.from === undefined || req.query.to === undefined) return true;
    const from = dateOnlyToUtc(req.query.from);
    const to = dateOnlyToUtc(req.query.to);
    if (!from || !to) return true;
    const spanDays = (to.getTime() - from.getTime()) / (24 * 60 * 60 * 1000);
    if (spanDays < 0) {
      throw new Error('from must be on or before to');
    }
    if (spanDays > 30) {
      throw new Error('Date range must not exceed 31 local calendar days');
    }
    return true;
  }),
];

const availabilityCreateRules = [
  ...availabilityDoctorIdRules,
  body('dayOfWeek')
    .isInt({ min: 0, max: 6 })
    .withMessage('dayOfWeek must be an integer between 0 (Sunday) and 6 (Saturday)')
    .toInt(),
  body('startTime')
    .isString()
    .withMessage('startTime is required')
    .matches(TIME_OF_DAY_RE)
    .withMessage('startTime must be HH:mm or HH:mm:00'),
  body('endTime')
    .isString()
    .withMessage('endTime is required')
    .matches(TIME_OF_DAY_RE)
    .withMessage('endTime must be HH:mm or HH:mm:00'),
  body('slotDurationMinutes')
    .optional()
    .isInt({ min: 5, max: 240 })
    .withMessage('slotDurationMinutes must be an integer between 5 and 240')
    .toInt(),
  body('isActive')
    .optional()
    .isBoolean()
    .withMessage('isActive must be a boolean')
    .toBoolean(),
  body().custom((_, { req }) => {
    const { startTime, endTime, slotDurationMinutes } = req.body;
    const start = timeToMinutes(startTime);
    const end = timeToMinutes(endTime);
    if (start === null || end === null) return true;
    if (start >= end) throw new Error('startTime must be earlier than endTime');
    const duration = slotDurationMinutes === undefined ? 30 : Number(slotDurationMinutes);
    if (Number.isInteger(duration) && duration > end - start) {
      throw new Error('slotDurationMinutes must fit within the availability window');
    }
    return true;
  }),
];

const AVAILABILITY_UPDATE_FIELDS = [
  'dayOfWeek',
  'startTime',
  'endTime',
  'slotDurationMinutes',
  'isActive',
];

const availabilityUpdateRules = [
  ...availabilitySlotIdRules,
  body('dayOfWeek')
    .optional()
    .isInt({ min: 0, max: 6 })
    .withMessage('dayOfWeek must be an integer between 0 (Sunday) and 6 (Saturday)')
    .toInt(),
  body('startTime')
    .optional()
    .isString()
    .withMessage('startTime must be HH:mm or HH:mm:00')
    .matches(TIME_OF_DAY_RE)
    .withMessage('startTime must be HH:mm or HH:mm:00'),
  body('endTime')
    .optional()
    .isString()
    .withMessage('endTime must be HH:mm or HH:mm:00')
    .matches(TIME_OF_DAY_RE)
    .withMessage('endTime must be HH:mm or HH:mm:00'),
  body('slotDurationMinutes')
    .optional()
    .isInt({ min: 5, max: 240 })
    .withMessage('slotDurationMinutes must be an integer between 5 and 240')
    .toInt(),
  body('isActive')
    .optional()
    .isBoolean()
    .withMessage('isActive must be a boolean')
    .toBoolean(),
  body().custom((_, { req }) => {
    if (!AVAILABILITY_UPDATE_FIELDS.some((field) => req.body[field] !== undefined)) {
      throw new Error(`At least one of ${AVAILABILITY_UPDATE_FIELDS.join(', ')} is required`);
    }
    return true;
  }),
];

const appointmentRespondRules = [
  body('status').isIn(['confirmed', 'rejected']).withMessage('Status must be confirmed or rejected'),
  // camelCase is the canonical field. snake_case is still accepted for
  // backward compatibility; both are read by the controller.
  body('alternativeTimeSuggested')
    .optional({ values: 'falsy' })
    .isISO8601()
    .withMessage('alternativeTimeSuggested must be a valid ISO 8601 date'),
  body('alternative_time')
    .optional({ values: 'falsy' })
    .isISO8601()
    .withMessage('alternative_time must be a valid ISO 8601 date'),
];

const clinicalRecordRules = [
  // camelCase is the canonical contract. snake_case aliases remain accepted so
  // older clients are not silently ignored.
  body('notesText').optional({ values: 'falsy' }).isString(),
  body('prescriptionText').optional({ values: 'falsy' }).isString(),
  body('prescriptionFileUrl').optional({ values: 'falsy' }).isString(),
  body('riskIndicator')
    .optional({ values: 'falsy' })
    .isIn(['low', 'medium', 'high'])
    .withMessage('riskIndicator must be low, medium or high'),
  body('notes_text').optional({ values: 'falsy' }).isString(),
  body('prescription_text').optional({ values: 'falsy' }).isString(),
  body('prescription_file_url').optional({ values: 'falsy' }).isString(),
  body('risk_indicator')
    .optional({ values: 'falsy' })
    .isIn(['low', 'medium', 'high'])
    .withMessage('risk_indicator must be low, medium or high'),
];

const doctorRegisterRules = [
  body('licenseNumber').notEmpty().withMessage('License number is required'),
  body('specialization').notEmpty().withMessage('Specialization is required'),
  body('location').notEmpty().withMessage('Location is required'),
];

const emergencyContactRules = [
  body('contactName').notEmpty().withMessage('Contact name is required'),
  body('phone').notEmpty().withMessage('Phone is required'),
];

// The controller speaks camelCase, so the rules below validate the payload it
// actually reads. The legacy snake_case rules are kept (nothing sends
// snake_case, they are inert) to avoid changing unrelated behaviour.
const healthLogRules = [
  body('log_date').optional().isISO8601(),
  body('weight_kg').optional().isFloat({ min: 20, max: 200 }),
  body('symptom_severity').optional().isInt({ min: 0, max: 10 }),
  body('weightKg').optional().isFloat({ min: 20, max: 200 }),
  body('mood').optional().isIn(['happy', 'normal', 'sad', 'anxious', 'tired', 'energetic']),
  body('symptomSeverity').optional().isInt({ min: 0, max: 10 }),
  body('symptomsJson').optional().custom((v) => {
    if (v === null || typeof v === 'object') return true; // object or array
    throw new Error('symptomsJson must be an object or array');
  }),
  body('bloodPressureSystolic').optional().isInt({ min: 60, max: 200 }),
  body('bloodPressureDiastolic').optional().isInt({ min: 40, max: 140 }),
  body('kickCount').optional().isInt({ min: 0, max: 100 }),
  body('notes').optional().isString().isLength({ max: 1000 }),
];

const communityPostRules = [
  body('content').notEmpty().withMessage('Content is required'),
  body('group_id').optional().isUUID(),
  body('is_anonymous').optional().isBoolean(),
];

const communityCommentRules = [
  body('content').notEmpty().withMessage('Content is required'),
];

const chatbotRules = [
  body('message').notEmpty().withMessage('Message is required'),
];

const healthProviderRules = [
  body('name').notEmpty().withMessage('Provider name is required'),
  body('location').optional().trim(),
  body('contact').optional().trim(),
];

const paginationRules = [
  query('page').optional().trim().isInt({ min: 1 }).withMessage('Page must be a positive integer').toInt(),
  query('limit').optional().trim().isInt({ min: 1, max: 100 }).withMessage('Limit must be 1-100').toInt(),
];

module.exports = {
  validate,
  registerRules,
  loginRules,
  adminLoginRules,
  otpSendRules,
  otpVerifyRules,
  forgotPasswordRules,
  resetPasswordRules,
  contentRules,
  nutritionRules,
  fetalRules,
  musicRules,
  notificationRules,
  appointmentRules,
  appointmentRespondRules,
  availabilityDoctorIdRules,
  availabilitySlotIdRules,
  availabilityListRules,
  availableSlotsRules,
  availabilityCreateRules,
  availabilityUpdateRules,
  clinicalRecordRules,
  doctorRegisterRules,
  emergencyContactRules,
  healthLogRules,
  communityPostRules,
  communityCommentRules,
  chatbotRules,
  healthProviderRules,
  paginationRules,
};

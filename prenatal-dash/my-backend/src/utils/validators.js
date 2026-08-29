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
  body('language').optional().isIn(['am', 'or', 'en']).withMessage('Language must be am, or, or en'),
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
  body('week_number').isInt({ min: 1, max: 42 }).withMessage('Week must be between 1 and 42'),
];

const musicRules = [
  body('category').optional().isIn(['relaxation', 'meditation', 'lullaby', 'classical', 'nature']).withMessage('Invalid category'),
];

const notificationRules = [
  body('title_am').optional(),
  body('body_am').optional(),
  body('target_group').optional().isIn(['all', 'mothers', 'doctors', 'specific_user']),
];

const appointmentRules = [
  body('doctorId').notEmpty().withMessage('Doctor ID is required').isUUID(),
  body('slotDatetime').notEmpty().withMessage('Slot datetime is required').isISO8601(),
];

const appointmentRespondRules = [
  body('status').isIn(['confirmed', 'rejected']).withMessage('Status must be confirmed or rejected'),
  body('alternative_time').optional().isISO8601(),
];

const clinicalRecordRules = [
  body('notes_text').optional(),
  body('prescription_text').optional(),
  body('risk_indicator').optional().isIn(['low', 'medium', 'high']),
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

const healthLogRules = [
  body('log_date').optional().isISO8601(),
  body('weight_kg').optional().isFloat({ min: 20, max: 200 }),
  body('mood').optional().isIn(['happy', 'normal', 'sad', 'anxious', 'tired', 'energetic']),
  body('symptom_severity').optional().isInt({ min: 0, max: 10 }),
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
  query('page').optional().isInt({ min: 1 }).withMessage('Page must be a positive integer'),
  query('limit').optional().isInt({ min: 1, max: 100 }).withMessage('Limit must be 1-100'),
];

module.exports = {
  validate,
  registerRules,
  loginRules,
  adminLoginRules,
  otpSendRules,
  otpVerifyRules,
  forgotPasswordRules,
  contentRules,
  nutritionRules,
  fetalRules,
  musicRules,
  notificationRules,
  appointmentRules,
  appointmentRespondRules,
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

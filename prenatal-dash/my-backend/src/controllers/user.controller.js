const User = require('../models/User');
const { sendSuccess, sendError } = require('../utils/apiResponse');
const { getPregnancyProgress } = require('../services/pregnancyCalculator');

// ── GET /api/v1/users/me ─────────────────────────────────────────────────────
exports.getMe = async (req, res, next) => {
    try {
        const user = await User.findById(req.user._id);
        const progress = user.lmpDate ? getPregnancyProgress(user.lmpDate) : null;

        return sendSuccess(res, 200, 'Profile retrieved', {
            user: { ...user.toJSON(), ...progress },
        });
    } catch (err) {
        next(err);
    }
};

// ── PUT /api/v1/users/me ─────────────────────────────────────────────────────
exports.updateMe = async (req, res, next) => {
    try {
        const { name, language, lmpDate } = req.body;
        const updates = {};
        if (name) updates.name = name;
        if (language) updates.language = language;
        if (lmpDate) updates.lmpDate = lmpDate;

        const user = await User.findById(req.user._id);
        Object.assign(user, updates);
        await user.save(); // Triggers pre-save hooks for dueDate/currentWeek

        const progress = user.lmpDate ? getPregnancyProgress(user.lmpDate) : null;

        return sendSuccess(res, 200, 'Profile updated', {
            user: { ...user.toJSON(), ...progress },
        });
    } catch (err) {
        next(err);
    }
};

// ── PUT /api/v1/users/emergency-contacts ─────────────────────────────────────
exports.updateEmergencyContacts = async (req, res, next) => {
    try {
        const { emergencyContacts } = req.body;

        if (!Array.isArray(emergencyContacts)) {
            return sendError(res, 400, 'emergencyContacts must be an array.');
        }

        const user = await User.findByIdAndUpdate(
            req.user._id,
            { emergencyContacts },
            { new: true, runValidators: true }
        );

        return sendSuccess(res, 200, 'Emergency contacts updated', {
            emergencyContacts: user.emergencyContacts,
        });
    } catch (err) {
        next(err);
    }
};

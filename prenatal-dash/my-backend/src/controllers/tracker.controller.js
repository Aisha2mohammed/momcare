const User = require('../models/User');
const NutritionGuide = require('../models/NutritionGuide');
const FetalDevelopment = require('../models/FetalDevelopment');
const Exercise = require('../models/Exercise');
const { getPregnancyProgress, getTrimester } = require('../services/pregnancyCalculator');
const { sendSuccess, sendError } = require('../utils/apiResponse');

// ── GET /api/v1/tracker/progress ─────────────────────────────────────────────
exports.getProgress = async (req, res, next) => {
    try {
        const user = await User.findById(req.user._id);

        if (!user.lmpDate) {
            return sendError(res, 400, 'LMP date not set. Please update your profile to track progress.');
        }

        const lang = req.query.lang || user.language || 'am';
        const progress = getPregnancyProgress(user.lmpDate);
        const { currentWeek, currentTrimester } = progress;

        // Fetch fetal data for current week
        const fetalData = await FetalDevelopment.findOne({ week: currentWeek });

        // Fetch 1 nutrition tip for current trimester
        const nutritionTip = await NutritionGuide.findOne({
            trimester: currentTrimester,
            isPublished: true,
        }).sort({ createdAt: -1 });

        // Fetch 1 exercise tip
        const exerciseTip = await Exercise.findOne({
            trimester: currentTrimester,
            isPublished: true,
        }).sort({ createdAt: -1 });

        const l = lang === 'or' ? 'or' : 'am';

        const localizeField = (obj) => (obj?.[l] || obj?.am || '');

        return sendSuccess(res, 200, 'Pregnancy progress retrieved', {
            progress,
            user: {
                name: user.name,
                language: user.language,
                lmpDate: user.lmpDate,
                dueDate: user.dueDate,
            },
            fetalDevelopment: fetalData ? {
                week: fetalData.week,
                sizeComparison: localizeField(fetalData.sizeComparison),
                weightGrams: fetalData.weightGrams,
                lengthCm: fetalData.lengthCm,
                milestones: localizeField(fetalData.milestones),
                tipsForMother: localizeField(fetalData.tipsForMother),
                imageUrl: fetalData.imageUrl,
            } : null,
            nutritionTip: nutritionTip ? {
                id: nutritionTip._id,
                title: localizeField(nutritionTip.title),
                body: localizeField(nutritionTip.body),
                imageUrl: nutritionTip.imageUrl,
            } : null,
            exerciseTip: exerciseTip ? {
                id: exerciseTip._id,
                title: localizeField(exerciseTip.title),
                description: localizeField(exerciseTip.description),
                category: exerciseTip.category,
                durationMinutes: exerciseTip.durationMinutes,
                imageUrl: exerciseTip.imageUrl,
            } : null,
        });
    } catch (err) {
        next(err);
    }
};

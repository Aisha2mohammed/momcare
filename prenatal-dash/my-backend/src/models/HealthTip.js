const mongoose = require('mongoose');

const healthTipSchema = new mongoose.Schema({
    title: { am: { type: String }, or: { type: String } },
    body: { am: { type: String }, or: { type: String } },
    category: {
        type: String,
        enum: ['general', 'nutrition', 'emergency_signs', 'mental_health', 'hygiene'],
        default: 'general',
    },
    trimester: {
        type: Number,
        enum: [0, 1, 2, 3],
        default: 0,
    },
    isPublished: { type: Boolean, default: false },
}, { timestamps: true });

healthTipSchema.index({ category: 1, trimester: 1 });

module.exports = mongoose.model('HealthTip', healthTipSchema);

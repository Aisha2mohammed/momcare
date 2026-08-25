const mongoose = require('mongoose');

const sleepTipSchema = new mongoose.Schema({
    title: { am: { type: String }, or: { type: String } },
    description: { am: { type: String }, or: { type: String } },
    trimester: {
        type: Number,
        enum: [1, 2, 3, 0], // 0 = all trimesters
        default: 0,
    },
    position: {
        type: String,
        enum: ['left_side', 'right_side', 'back', 'pillow_support', 'other'],
        default: 'other',
    },
    imageUrl: { type: String },
    isPublished: { type: Boolean, default: false },
}, { timestamps: true });

module.exports = mongoose.model('SleepTip', sleepTipSchema);

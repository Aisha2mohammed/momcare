const mongoose = require('mongoose');

const exerciseSchema = new mongoose.Schema({
    title: { am: { type: String }, or: { type: String } },
    description: { am: { type: String }, or: { type: String } },
    trimester: {
        type: Number,
        enum: [1, 2, 3],
        required: [true, 'Trimester is required'],
    },
    category: {
        type: String,
        enum: ['stretching', 'breathing', 'walking', 'yoga', 'kegel', 'other'],
        default: 'other',
    },
    durationMinutes: { type: Number },
    imageUrl: { type: String },
    videoUrl: { type: String },
    isPublished: { type: Boolean, default: false },
}, { timestamps: true });

exerciseSchema.index({ trimester: 1, isPublished: 1 });

module.exports = mongoose.model('Exercise', exerciseSchema);

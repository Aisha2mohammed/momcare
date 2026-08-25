const mongoose = require('mongoose');

const fetalDevelopmentSchema = new mongoose.Schema({
    week: {
        type: Number,
        min: 1,
        max: 42,
        unique: true,
        required: [true, 'Week number is required'],
    },
    sizeComparison: { am: { type: String }, or: { type: String } },
    weightGrams: { type: Number },
    lengthCm: { type: Number },
    milestones: { am: { type: String }, or: { type: String } },
    tipsForMother: { am: { type: String }, or: { type: String } },
    imageUrl: { type: String },
}, { timestamps: true });

module.exports = mongoose.model('FetalDevelopment', fetalDevelopmentSchema);

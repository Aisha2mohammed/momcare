const mongoose = require('mongoose');

const bilingualSchema = {
    am: { type: String, default: '' },
    or: { type: String, default: '' },
};

const foodItemSchema = new mongoose.Schema({
    name: { am: String, or: String },
    benefit: { am: String, or: String },
}, { _id: false });

const nutritionGuideSchema = new mongoose.Schema({
    trimester: {
        type: Number,
        enum: [1, 2, 3],
        required: [true, 'Trimester is required'],
    },
    title: bilingualSchema,
    body: bilingualSchema,
    foods: [foodItemSchema],
    imageUrl: { type: String },
    isPublished: { type: Boolean, default: false },
}, { timestamps: true });

nutritionGuideSchema.index({ trimester: 1, isPublished: 1 });

module.exports = mongoose.model('NutritionGuide', nutritionGuideSchema);

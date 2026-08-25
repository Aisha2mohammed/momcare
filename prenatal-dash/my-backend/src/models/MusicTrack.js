const mongoose = require('mongoose');

const musicTrackSchema = new mongoose.Schema({
    title: {
        am: { type: String },
        or: { type: String },
    },
    category: {
        type: String,
        enum: ['relaxation', 'meditation', 'lullaby'],
        required: [true, 'Category is required'],
    },
    audioUrl: { type: String, required: [true, 'Audio URL is required'] },
    thumbnailUrl: { type: String },
    durationSeconds: { type: Number },
    isActive: { type: Boolean, default: true },
}, { timestamps: true });

musicTrackSchema.index({ category: 1, isActive: 1 });

module.exports = mongoose.model('MusicTrack', musicTrackSchema);

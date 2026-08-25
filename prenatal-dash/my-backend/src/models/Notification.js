const mongoose = require('mongoose');

const notificationSchema = new mongoose.Schema({
    title: {
        am: { type: String },
        or: { type: String },
    },
    body: {
        am: { type: String },
        or: { type: String },
    },
    type: {
        type: String,
        enum: ['reminder', 'alert', 'tip'],
        required: true,
    },
    targetLanguage: {
        type: String,
        enum: ['am', 'or', 'all'],
        default: 'all',
    },
    targetTrimester: {
        type: Number,
        enum: [0, 1, 2, 3], // 0 = all
        default: 0,
    },
    scheduledAt: { type: Date },
    sentAt: { type: Date },
    sentCount: { type: Number, default: 0 },
    status: {
        type: String,
        enum: ['draft', 'scheduled', 'sent'],
        default: 'draft',
    },
    createdBy: { type: mongoose.Schema.Types.ObjectId, ref: 'Admin' },
}, { timestamps: true });

notificationSchema.index({ status: 1, scheduledAt: 1 });

module.exports = mongoose.model('Notification', notificationSchema);

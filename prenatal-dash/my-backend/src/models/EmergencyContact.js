const mongoose = require('mongoose');

const emergencyContactSchema = new mongoose.Schema({
    hospitalName: { type: String, required: [true, 'Hospital name is required'] },
    phone: { type: String, required: [true, 'Phone is required'] },
    city: { type: String, required: [true, 'City is required'] },
    region: { type: String },
    latitude: { type: Number },
    longitude: { type: Number },
    isActive: { type: Boolean, default: true },
}, { timestamps: true });

emergencyContactSchema.index({ city: 1, isActive: 1 });
emergencyContactSchema.index({ region: 1, isActive: 1 });

module.exports = mongoose.model('EmergencyContact', emergencyContactSchema);

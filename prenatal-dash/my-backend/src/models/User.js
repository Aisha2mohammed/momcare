const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');

const emergencyContactSchema = new mongoose.Schema({
    name: { type: String, required: true },
    phone: { type: String, required: true },
}, { _id: false });

const userSchema = new mongoose.Schema({
    phone: {
        type: String,
        unique: true,
        required: [true, 'Phone number is required'],
        trim: true,
    },
    name: { type: String, trim: true },
    password: { type: String, select: false },
    language: {
        type: String,
        enum: ['am', 'or'],
        default: 'am',
    },
    lmpDate: { type: Date },   // Last Menstrual Period
    dueDate: { type: Date },   // Auto-calculated (lmpDate + 280 days)
    currentWeek: { type: Number, min: 1, max: 42 },
    fcmToken: { type: String },
    emergencyContacts: [emergencyContactSchema],
    isActive: { type: Boolean, default: true },
}, { timestamps: true });

// Auto-calculate dueDate and currentWeek before save
userSchema.pre('save', function (next) {
    if (this.lmpDate) {
        const lmp = new Date(this.lmpDate);
        this.dueDate = new Date(lmp.getTime() + 280 * 24 * 60 * 60 * 1000);
        const msPerWeek = 7 * 24 * 60 * 60 * 1000;
        const weeksElapsed = Math.floor((Date.now() - lmp.getTime()) / msPerWeek) + 1;
        this.currentWeek = Math.max(1, Math.min(42, weeksElapsed));
    }
    next();
});

// Hash password before save
userSchema.pre('save', async function (next) {
    if (!this.isModified('password') || !this.password) return next();
    this.password = await bcrypt.hash(this.password, 12);
    next();
});

userSchema.methods.comparePassword = async function (candidatePassword) {
    return bcrypt.compare(candidatePassword, this.password);
};

// Remove password from JSON output
userSchema.methods.toJSON = function () {
    const obj = this.toObject();
    delete obj.password;
    return obj;
};

module.exports = mongoose.model('User', userSchema);

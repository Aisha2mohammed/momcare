const multer = require('multer');
const cloudinary = require('../config/cloudinary');
const { CloudinaryStorage } = require('multer-storage-cloudinary');
const { sendError } = require('../utils/apiResponse');

// ── Image upload storage ─────────────────────────────────────────────────────
const imageStorage = new CloudinaryStorage({
    cloudinary,
    params: {
        folder: 'pregnancy-app/images',
        allowed_formats: ['jpg', 'jpeg', 'png', 'webp'],
        transformation: [{ width: 800, height: 600, crop: 'limit', quality: 'auto' }],
    },
});

// ── Audio upload storage ─────────────────────────────────────────────────────
const audioStorage = new CloudinaryStorage({
    cloudinary,
    params: {
        folder: 'pregnancy-app/audio',
        allowed_formats: ['mp3', 'wav', 'ogg', 'm4a'],
        resource_type: 'video', // Cloudinary stores audio under video resource type
    },
});

// ── Filter helpers ───────────────────────────────────────────────────────────
const imageFilter = (req, file, cb) => {
    if (file.mimetype.startsWith('image/')) {
        cb(null, true);
    } else {
        cb(new Error('Only image files are allowed!'), false);
    }
};

const audioFilter = (req, file, cb) => {
    const allowedMimes = ['audio/mpeg', 'audio/wav', 'audio/ogg', 'audio/mp4', 'audio/x-m4a'];
    if (allowedMimes.includes(file.mimetype) || file.mimetype.startsWith('audio/')) {
        cb(null, true);
    } else {
        cb(new Error('Only audio files are allowed!'), false);
    }
};

// ── Exported middleware ──────────────────────────────────────────────────────
const uploadImage = multer({
    storage: imageStorage,
    fileFilter: imageFilter,
    limits: { fileSize: 5 * 1024 * 1024 }, // 5 MB
}).single('image');

const uploadAudio = multer({
    storage: audioStorage,
    fileFilter: audioFilter,
    limits: { fileSize: 50 * 1024 * 1024 }, // 50 MB
}).single('audio');

const uploadFields = multer({
    storage: imageStorage,
    limits: { fileSize: 50 * 1024 * 1024 },
}).fields([
    { name: 'image', maxCount: 1 },
    { name: 'thumbnail', maxCount: 1 },
]);

// ── Error wrapper ────────────────────────────────────────────────────────────
const handleUpload = (uploadFn) => (req, res, next) => {
    uploadFn(req, res, (err) => {
        if (err instanceof multer.MulterError) {
            return sendError(res, 400, `Upload error: ${err.message}`);
        }
        if (err) {
            return sendError(res, 400, err.message);
        }
        next();
    });
};

module.exports = {
    uploadImage: handleUpload(uploadImage),
    uploadAudio: handleUpload(uploadAudio),
    uploadFields: handleUpload(uploadFields),
};

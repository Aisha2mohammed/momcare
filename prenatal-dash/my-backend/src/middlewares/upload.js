const multer = require('multer');
const path = require('path');
const fs = require('fs');

// Ensure destination folder exists
const uploadDir = path.join(__dirname, '../../uploads');
if (!fs.existsSync(uploadDir)) {
  fs.mkdirSync(uploadDir, { recursive: true });
}

const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, uploadDir);
  },
  filename: (req, file, cb) => {
    const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1e9);
    let ext = path.extname(file.originalname || '').toLowerCase();
    if (!ext) {
      if (file.mimetype === 'image/png') ext = '.png';
      else if (file.mimetype === 'image/webp') ext = '.webp';
      else ext = '.jpg';
    }
    cb(null, `${file.fieldname}-${uniqueSuffix}${ext}`);
  },
});

const fileFilter = (req, file, cb) => {
  const ext = path.extname(file.originalname || '').toLowerCase();
  const allowedExts = [
    '.jpg', '.jpeg', '.png', '.webp', '.gif',
    '.mp4', '.webm', '.mov', '.pdf',
    '.mp3', '.wav', '.ogg', '.m4a', '.aac'
  ];
  const allowedTypes = [
    'image/jpeg',
    'image/jpg',
    'image/png',
    'image/webp',
    'image/gif',
    'video/mp4',
    'video/webm',
    'video/quicktime',
    'application/pdf',
    'audio/mpeg',
    'audio/mp3',
    'audio/wav',
    'audio/x-wav',
    'audio/ogg',
    'audio/mp4',
    'audio/aac',
    'audio/webm',
  ];

  if (
    allowedTypes.includes(file.mimetype) ||
    allowedExts.includes(ext) ||
    (file.mimetype && file.mimetype.startsWith('image/')) ||
    (file.mimetype === 'application/octet-stream' && (allowedExts.includes(ext) || !ext))
  ) {
    cb(null, true);
  } else {
    cb(new Error(`Unsupported file format: ${file.mimetype}`), false);
  }
};

const upload = multer({
  storage,
  fileFilter,
  limits: {
    fileSize: 50 * 1024 * 1024, // 50MB max file limit (covers images, pdfs, and short videos)
  },
});

// Music track admin form: one image + one audio file per language, all optional
// (any of these can be sent as a *Url string instead of a file - see music.controller.js).
const musicUploadFields = upload.fields([
  { name: 'image', maxCount: 1 },
  { name: 'audio_en', maxCount: 1 },
  { name: 'audio_am', maxCount: 1 },
  { name: 'audio_om', maxCount: 1 },
  { name: 'audio_so', maxCount: 1 },
]);

module.exports = upload;
module.exports.musicUploadFields = musicUploadFields;
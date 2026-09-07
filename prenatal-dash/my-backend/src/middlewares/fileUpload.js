const path = require('path');
const fs = require('fs');
const multer = require('multer');

// Ensure uploads directory exists
const uploadsDir = path.join(__dirname, '../../uploads');
if (!fs.existsSync(uploadsDir)) {
  fs.mkdirSync(uploadsDir, { recursive: true });
}

// Storage configuration
const storage = multer.diskStorage({
  destination: function (req, file, cb) {
    cb(null, uploadsDir);
  },
  filename: function (req, file, cb) {
    const ext = path.extname(file.originalname).toLowerCase() || '.bin';
    const cleanBase = path.basename(file.originalname, ext).replace(/[^a-zA-Z0-9_-]/g, '_').substring(0, 30);
    const uniqueSuffix = `${Date.now()}-${Math.round(Math.random() * 1e9)}`;
    cb(null, `${cleanBase}-${uniqueSuffix}${ext}`);
  },
});

// File filter accepting images, videos, audio, and pdf documents
const fileFilter = (req, file, cb) => {
  const allowedMimePrefixes = ['image/', 'video/', 'audio/'];
  const isPdf = file.mimetype === 'application/pdf' || file.originalname.toLowerCase().endsWith('.pdf');

  if (allowedMimePrefixes.some(prefix => file.mimetype.startsWith(prefix)) || isPdf) {
    cb(null, true);
  } else {
    cb(new Error(`File type '${file.mimetype}' is not supported. Please upload an image, video, audio, or PDF.`), false);
  }
};

const upload = multer({
  storage,
  fileFilter,
  limits: {
    fileSize: 100 * 1024 * 1024, // 100 MB max
  },
});

// Middleware supporting 'file', 'media', 'image', 'video' field names
const handleFileUpload = (req, res, next) => {
  const uploadSingle = upload.any();
  uploadSingle(req, res, (err) => {
    if (err instanceof multer.MulterError) {
      return res.status(400).json({ success: false, error: { message: `Upload error: ${err.message}` } });
    } else if (err) {
      return res.status(400).json({ success: false, error: { message: err.message } });
    }
    next();
  });
};

module.exports = { handleFileUpload };

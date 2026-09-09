const express = require('express');
const router = express.Router();
const upload = require('../middlewares/upload');
const exerciseController = require('../controllers/exercise.controller');
const exerciseWeekController = require('../controllers/exerciseWeekController');
const { requireAdmin } = require('../middlewares/roleGuard');

const handleMedia = (req, fieldName) => {
  if (req.files && req.files[fieldName] && req.files[fieldName][0]) {
    return `/uploads/${req.files[fieldName][0].filename}`;
  }
  return req.body[fieldName] || null;
};

// --- EXERCISES (Tips / Content) ---
router.get('/tips', exerciseController.getAll);
router.post(
  '/tips',
  requireAdmin,
  upload.fields([
    { name: 'imageUrl', maxCount: 1 },
    { name: 'videoUrl', maxCount: 1 },
    { name: 'pdfUrl', maxCount: 1 }
  ]),
  (req, res, next) => {
    req.body.imageUrl = handleMedia(req, 'imageUrl');
    req.body.videoUrl = handleMedia(req, 'videoUrl');
    req.body.pdfUrl = handleMedia(req, 'pdfUrl');
    exerciseController.create(req, res, next);
  }
);

// --- EXERCISE WEEKS ---
router.get('/weeks', exerciseWeekController.getAll);
router.post('/weeks', requireAdmin, exerciseWeekController.create);
router.put('/weeks/:id', requireAdmin, exerciseWeekController.update);
router.delete('/weeks/:id', requireAdmin, exerciseWeekController.remove);

module.exports = router;
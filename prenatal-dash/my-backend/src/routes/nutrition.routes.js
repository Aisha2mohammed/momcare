const express = require('express');
const router = express.Router();
const upload = require('../middlewares/upload');
const nutritionController = require('../controllers/nutrition.controller');
const nutritionWeekController = require('../controllers/nutritionWeekController');
const { requireAdmin } = require('../middlewares/roleGuard');

const handleMedia = (req, fieldName) => {
  if (req.files && req.files[fieldName] && req.files[fieldName][0]) {
    return `/uploads/${req.files[fieldName][0].filename}`;
  }
  return req.body[fieldName] || null;
};

// --- NUTRITION TIPS (Content) ---
router.get('/tips', nutritionController.getAll);
router.get('/tips/:id', nutritionController.getOne);

router.post(
  '/tips',
  requireAdmin,
  upload.fields([{ name: 'imageUrl', maxCount: 1 }]),
  (req, res, next) => {
    req.body.imageUrl = handleMedia(req, 'imageUrl');
    nutritionController.create(req, res, next);
  }
);

router.put(
  '/tips/:id',
  requireAdmin,
  upload.fields([{ name: 'imageUrl', maxCount: 1 }]),
  (req, res, next) => {
    req.body.imageUrl = handleMedia(req, 'imageUrl');
    nutritionController.update(req, res, next);
  }
);

router.delete('/tips/:id', requireAdmin, nutritionController.remove);

// --- NUTRITION WEEKS (trimester/month/week + why_important + hydration) ---
router.get('/weeks', nutritionWeekController.getAll);
router.post('/weeks', requireAdmin, nutritionWeekController.create);
router.put('/weeks/:id', requireAdmin, nutritionWeekController.update);
router.delete('/weeks/:id', requireAdmin, nutritionWeekController.remove);

module.exports = router;
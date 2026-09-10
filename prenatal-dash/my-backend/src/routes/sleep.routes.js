const express = require('express');
const router = express.Router();
const upload = require('../middlewares/upload');
const sleepController = require('../controllers/sleep.controller');
const sleepWeekController = require('../controllers/sleepWeekController');
const { requireAdmin } = require('../middlewares/roleGuard');

// Helper function to resolve upload path or body URL
const handleMedia = (req, fieldName) => {
  if (req.files && req.files[fieldName] && req.files[fieldName][0]) {
    return `/uploads/${req.files[fieldName][0].filename}`;
  }
  return req.body[fieldName] || null;
};

// --- SLEEP TIPS (Content) ---
router.get('/tips', sleepController.getAll);
router.get('/tips/:id', sleepController.getOne);
router.post(
  '/tips',
  requireAdmin,
  upload.fields([{ name: 'illustrationUrl', maxCount: 1 }]),
  (req, res, next) => {
    req.body.illustrationUrl = handleMedia(req, 'illustrationUrl');
    sleepController.create(req, res, next);
  }
);
router.delete('/tips/:id', requireAdmin, sleepController.remove);

// --- SLEEP WEEKS ---
router.get('/weeks', sleepWeekController.getAll);
router.post('/weeks', requireAdmin, sleepWeekController.create);
router.put('/weeks/:id', requireAdmin, sleepWeekController.update);
router.delete('/weeks/:id', requireAdmin, sleepWeekController.remove);

module.exports = router;
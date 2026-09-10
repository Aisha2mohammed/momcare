const express = require('express');
const router = express.Router();
const fetalController = require('../controllers/fetal.controller');
const { validate, fetalRules, paginationRules } = require('../utils/validators');
const { requireAdmin } = require('../middlewares/roleGuard');
const upload = require('../middlewares/upload'); // <--- Imported Multer upload middleware

// Mother-facing
router.get('/', paginationRules, validate, fetalController.getAll);
router.get('/:week', fetalController.getByWeek);

// Admin — main week record
// 'upload.single("image")' parses multipart/form-data BEFORE validation rules
router.post(
  '/',
  requireAdmin,
  upload.single('image'),
  fetalRules,
  validate,
  fetalController.create
);

router.put(
  '/:id',
  requireAdmin,
  upload.single('image'),
  fetalController.update
);

router.delete('/:id', requireAdmin, fetalController.remove);

module.exports = router;
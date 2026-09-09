const express = require('express');
const router = express.Router();
const musicController = require('../controllers/music.controller');
const { musicUploadFields } = require('../middlewares/upload');
const { validate, musicRules, paginationRules } = require('../utils/validators');
const { requireAdmin } = require('../middlewares/roleGuard');

// multer must run BEFORE the validators, since it's what populates req.body
// for multipart/form-data requests (JSON-only requests skip it fine too).
router.get('/', paginationRules, validate, musicController.getAll);
router.get('/:id', musicController.getOne);
router.post('/', requireAdmin, musicUploadFields, musicRules, validate, musicController.create);
router.put('/:id', requireAdmin, musicUploadFields, musicController.update);
router.delete('/:id', requireAdmin, musicController.remove);

module.exports = router;
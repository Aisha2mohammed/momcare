const express = require('express');
const router = express.Router();
const musicController = require('../controllers/music.controller');
const { validate, musicRules, paginationRules } = require('../utils/validators');
const { requireAdmin } = require('../middlewares/roleGuard');

router.get('/', paginationRules, validate, musicController.getAll);
router.get('/:id', musicController.getOne);
router.post('/', requireAdmin, musicRules, validate, musicController.create);
router.put('/:id', requireAdmin, musicController.update);
router.delete('/:id', requireAdmin, musicController.remove);

module.exports = router;

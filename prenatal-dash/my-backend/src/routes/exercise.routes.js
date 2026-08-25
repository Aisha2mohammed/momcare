const express = require('express');
const router = express.Router();
const exerciseController = require('../controllers/exercise.controller');
const { validate, paginationRules } = require('../utils/validators');
const { requireAdmin } = require('../middlewares/roleGuard');

router.get('/', paginationRules, validate, exerciseController.getAll);
router.get('/:id', exerciseController.getOne);
router.post('/', requireAdmin, exerciseController.create);
router.put('/:id', requireAdmin, exerciseController.update);
router.delete('/:id', requireAdmin, exerciseController.remove);

module.exports = router;

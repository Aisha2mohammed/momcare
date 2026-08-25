const express = require('express');
const router = express.Router();
const nutritionController = require('../controllers/nutrition.controller');
const { validate, nutritionRules, paginationRules } = require('../utils/validators');
const { requireAdmin } = require('../middlewares/roleGuard');

router.get('/', paginationRules, validate, nutritionController.getAll);
router.get('/:id', nutritionController.getOne);
router.post('/', requireAdmin, nutritionRules, validate, nutritionController.create);
router.put('/:id', requireAdmin, nutritionController.update);
router.delete('/:id', requireAdmin, nutritionController.remove);

module.exports = router;

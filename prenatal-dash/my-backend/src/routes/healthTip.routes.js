const express = require('express');
const router = express.Router();
const healthTipController = require('../controllers/healthTip.controller');
const { validate, paginationRules } = require('../utils/validators');
const { requireAdmin } = require('../middlewares/roleGuard');

router.get('/', paginationRules, validate, healthTipController.getAll);
router.get('/:id', healthTipController.getOne);
router.post('/', requireAdmin, healthTipController.create);
router.put('/:id', requireAdmin, healthTipController.update);
router.delete('/:id', requireAdmin, healthTipController.remove);

module.exports = router;


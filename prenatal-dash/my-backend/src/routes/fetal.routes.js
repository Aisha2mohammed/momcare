const express = require('express');
const router = express.Router();
const fetalController = require('../controllers/fetal.controller');
const { validate, fetalRules, paginationRules } = require('../utils/validators');
const { requireAdmin } = require('../middlewares/roleGuard');

router.get('/', paginationRules, validate, fetalController.getAll);
router.get('/:week', fetalController.getByWeek);
router.post('/', requireAdmin, fetalRules, validate, fetalController.create);
router.put('/:id', requireAdmin, fetalController.update);
router.delete('/:id', requireAdmin, fetalController.remove);

module.exports = router;

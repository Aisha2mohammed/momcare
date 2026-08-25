const express = require('express');
const router = express.Router();
const sleepController = require('../controllers/sleep.controller');
const { validate, paginationRules } = require('../utils/validators');
const { requireAdmin } = require('../middlewares/roleGuard');

router.get('/', paginationRules, validate, sleepController.getAll);
router.get('/:id', sleepController.getOne);
router.post('/', requireAdmin, sleepController.create);
router.put('/:id', requireAdmin, sleepController.update);
router.delete('/:id', requireAdmin, sleepController.remove);

module.exports = router;

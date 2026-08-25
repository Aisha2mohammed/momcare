const express = require('express');
const router = express.Router();
const emergencyController = require('../controllers/emergency.controller');
const { validate, emergencyContactRules, paginationRules } = require('../utils/validators');
const { requireAdmin } = require('../middlewares/roleGuard');

router.get('/contacts', paginationRules, validate, emergencyController.getContacts);
router.get('/health-tips', paginationRules, validate, emergencyController.getHealthTips);
router.post('/contacts', requireAdmin, emergencyContactRules, validate, emergencyController.createContact);
router.put('/contacts/:id', requireAdmin, emergencyController.updateContact);
router.delete('/contacts/:id', requireAdmin, emergencyController.deleteContact);

module.exports = router;


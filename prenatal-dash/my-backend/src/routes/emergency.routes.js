const express = require('express');
const router = express.Router();
const emergencyController = require('../controllers/emergency.controller');
const { validate, paginationRules } = require('../utils/validators');

// Per-mother emergency contacts live at /mothers/:id/emergency-contacts
// (mother.controller.js). The old /emergency/contacts facility-directory
// endpoints were removed — see the note in emergency.controller.js.
router.get('/health-tips', paginationRules, validate, emergencyController.getHealthTips);

module.exports = router;


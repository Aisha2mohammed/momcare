const express = require('express');
const router = express.Router();
const motherController = require('../controllers/mother.controller');
const { validate, healthLogRules, emergencyContactRules, paginationRules } = require('../utils/validators');
const auth = require('../middlewares/auth');
const { requireRole } = require('../middlewares/roleGuard');

router.use(auth);
router.use(requireRole('mother', 'admin'));

router.get('/:id/profile', motherController.getProfile);
router.put('/:id/profile', motherController.updateProfile);
router.get('/:id/gestational-week', motherController.getGestationalWeek);
router.get('/:id/health-logs', paginationRules, validate, motherController.getHealthLogs);
router.post('/:id/health-logs', healthLogRules, validate, motherController.createHealthLog);
router.get('/:id/emergency-contacts', motherController.getEmergencyContacts);
router.post('/:id/emergency-contacts', emergencyContactRules, validate, motherController.createEmergencyContact);
router.post('/:id/emergency-alert', motherController.emergencyAlert);
router.post('/:id/assign-doctor', motherController.assignDoctor);

module.exports = router;

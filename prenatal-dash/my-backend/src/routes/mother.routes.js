const express = require('express');
const router = express.Router();
const motherController = require('../controllers/mother.controller');
const { validate, healthLogRules, emergencyContactRules, paginationRules } = require('../utils/validators');
const auth = require('../middlewares/auth');
const { requireRole } = require('../middlewares/roleGuard');
const { requireSelfOrAdmin } = require('../middlewares/ownership');

router.use(auth);
router.use(requireRole('mother', 'admin'));

// Every route below is keyed by :id — only the owning mother (or an admin) may
// use it. Without this any logged-in mother could read/edit another mother's
// profile, health logs, contacts and gestational week by changing the id.
// NOTE: the guard must sit on each route, not router.use(), because router.use
// middleware runs before Express has populated req.params.
const ownsSelf = requireSelfOrAdmin('id');

router.get('/:id/profile', ownsSelf, motherController.getProfile);
router.put('/:id/profile', ownsSelf, motherController.updateProfile);
router.get('/:id/gestational-week', ownsSelf, motherController.getGestationalWeek);
router.get('/:id/health-logs', ownsSelf, paginationRules, validate, motherController.getHealthLogs);
router.post('/:id/health-logs', ownsSelf, healthLogRules, validate, motherController.createHealthLog);
router.get('/:id/emergency-contacts', ownsSelf, motherController.getEmergencyContacts);
router.post('/:id/emergency-contacts', ownsSelf, emergencyContactRules, validate, motherController.createEmergencyContact);
router.post('/:id/emergency-alert', ownsSelf, motherController.emergencyAlert);
router.post('/:id/assign-doctor', ownsSelf, motherController.assignDoctor);

module.exports = router;

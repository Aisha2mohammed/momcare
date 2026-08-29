const express = require('express');
const router = express.Router();
const doctorController = require('../controllers/doctor.controller');
const { validate, doctorRegisterRules, paginationRules, appointmentRules } = require('../utils/validators');
const auth = require('../middlewares/auth');
const { requireRole, requireApprovedDoctor } = require('../middlewares/roleGuard');

// Public routes (no auth required - for mothers browsing doctors)
router.get('/health-providers', doctorController.getHealthProviders);
router.get('/health-providers/:id/doctors', doctorController.getDoctorsByProvider);
router.get('/public/:id', doctorController.getDoctorPublicProfile);

// Doctor registration & self-service (JWT-protected, role=doctor)
router.post('/register', auth, doctorRegisterRules, validate, doctorController.registerDoctor);
router.get('/:id/profile', auth, requireRole('doctor'), doctorController.getDoctorProfile);
router.put('/:id/profile', auth, requireRole('doctor'), doctorController.updateDoctorProfile);
// Any authenticated user (including mothers) may view a doctor's availability slots
router.get('/:id/availability-slots', auth, doctorController.getAvailabilitySlots);
router.post('/:id/availability-slots', auth, requireRole('doctor'), doctorController.createAvailabilitySlot);
router.put('/:id/availability-slots/:slotId', auth, requireRole('doctor'), doctorController.updateAvailabilitySlot);
router.get('/:id/appointments', auth, requireRole('doctor'), paginationRules, validate, doctorController.getDoctorAppointments);
router.get('/:id/patients', auth, requireRole('doctor'), requireApprovedDoctor, doctorController.getDoctorPatients);
router.post('/:id/notify', auth, requireRole('doctor'), requireApprovedDoctor, doctorController.notifyPatients);

module.exports = router;

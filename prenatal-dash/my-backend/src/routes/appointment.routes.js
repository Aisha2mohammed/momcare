const express = require('express');
const router = express.Router();
const appointmentController = require('../controllers/appointment.controller');
const { validate, appointmentRules, appointmentRespondRules, clinicalRecordRules, paginationRules } = require('../utils/validators');
const auth = require('../middlewares/auth');
const { requireRole, requireApprovedDoctor } = require('../middlewares/roleGuard');

router.post('/', auth, requireRole('mother'), appointmentRules, validate, appointmentController.bookAppointment);
router.get('/:id', auth, appointmentController.getAppointment);
router.put('/:id/status', auth, appointmentController.updateAppointmentStatus);
router.put('/:id/respond', auth, requireRole('doctor'), appointmentRespondRules, validate, requireApprovedDoctor, appointmentController.respondToAppointment);
router.post('/:id/clinical-record', auth, requireRole('doctor'), clinicalRecordRules, validate, requireApprovedDoctor, appointmentController.addClinicalRecord);

module.exports = router;

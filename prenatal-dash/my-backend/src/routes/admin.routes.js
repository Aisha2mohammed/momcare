const express = require('express');
const router = express.Router();
const adminController = require('../controllers/admin.controller');
const { validate, paginationRules, healthProviderRules } = require('../utils/validators');
const { requireAdmin } = require('../middlewares/roleGuard');

router.use(requireAdmin);

// Dashboard & Users
router.get('/dashboard', adminController.getDashboard);
router.get('/users', paginationRules, validate, adminController.getUsers);
router.put('/users/:id/suspend', adminController.suspendUser);
router.put('/users/:id/reactivate', adminController.reactivateUser);

// Doctor Approval
router.get('/doctors/pending', adminController.getPendingDoctors);
router.put('/doctors/:id/approve', adminController.approveDoctor);
router.put('/doctors/:id/reject', adminController.rejectDoctor);

// Health Providers
router.get('/health-providers', adminController.getHealthProviders);
router.post('/health-providers', healthProviderRules, validate, adminController.createHealthProvider);
router.put('/health-providers/:id', adminController.updateHealthProvider);
router.put('/health-providers/:id/status', adminController.toggleHealthProviderStatus);

// Content Management (CRUD for all content types is handled via respective routes)
// Audit Logs
router.get('/audit-logs', paginationRules, validate, adminController.getAuditLogs);

// Community Moderation
router.delete('/community/posts/:id', adminController.moderatePost);
router.put('/community/rules', adminController.updateCommunityRules);

// Stats
router.get('/stats', adminController.getStats);

module.exports = router;


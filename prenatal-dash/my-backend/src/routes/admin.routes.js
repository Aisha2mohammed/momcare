const express = require('express');
const router = express.Router();
const adminController = require('../controllers/admin.controller');
const { validate, paginationRules, healthProviderRules } = require('../utils/validators');
const { requireAdmin } = require('../middlewares/roleGuard');

router.use(requireAdmin);

// Dashboard & Users
router.get('/dashboard', adminController.getDashboard);
router.get('/users', paginationRules, validate, adminController.getUsers);
// Mother approval workflow — '/users/pending' must precede the '/users/:id/...'
// routes so Express does not treat 'pending' as an :id.
router.get('/users/pending', paginationRules, validate, adminController.getPendingUsers);
router.put('/users/:id/approve', adminController.approveUser);
router.put('/users/:id/reject', adminController.rejectUser);
router.put('/users/:id/suspend', adminController.suspendUser);
router.put('/users/:id/reactivate', adminController.reactivateUser);

// Generic CMS upload
const upload = require('../middlewares/upload');
router.post('/cms/upload', upload.single('file'), (req, res) => {
  if (!req.file) {
    return res.status(400).json({ success: false, error: { message: 'No file uploaded' } });
  }
  const url = `/uploads/${req.file.filename}`;
  res.json({
    success: true,
    data: {
      url: url,
      relativeUrl: url,
      filename: req.file.filename,
      size: req.file.size,
      mimetype: req.file.mimetype
    }
  });
});

// Doctor Approval
router.get('/doctors/pending', adminController.getPendingDoctors);
router.put('/doctors/:id/approve', adminController.approveDoctor);
router.put('/doctors/:id/reject', adminController.rejectDoctor);

// Mother health logs (read-only mirror of /mothers/:id/health-logs)
router.get('/mothers/:id/health-logs', paginationRules, validate, adminController.getMotherHealthLogs);

// Health Providers
router.get('/health-providers', adminController.getHealthProviders);
router.post('/health-providers', healthProviderRules, validate, adminController.createHealthProvider);
router.put('/health-providers/:id', adminController.updateHealthProvider);
router.put('/health-providers/:id/status', adminController.toggleHealthProviderStatus);


// Audit Logs
router.get('/audit-logs', paginationRules, validate, adminController.getAuditLogs);

// Community Moderation
router.delete('/community/posts/:id', adminController.moderatePost);
router.put('/community/rules', adminController.updateCommunityRules);

// Notifications
const notificationController = require('../controllers/notification.controller');
router.get('/notifications', paginationRules, validate, notificationController.getHistory);
router.post('/notifications', notificationRules, validate, notificationController.sendNow);

// Stats
router.get('/stats', adminController.getStats);

module.exports = router;


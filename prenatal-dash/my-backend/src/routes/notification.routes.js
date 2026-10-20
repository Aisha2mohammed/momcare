const express = require('express');
const router = express.Router();
const notificationController = require('../controllers/notification.controller');
const { validate, notificationRules, paginationRules } = require('../utils/validators');
const auth = require('../middlewares/auth');
const { requireRole } = require('../middlewares/roleGuard');

// Admin
router.post('/send', auth, requireRole('admin'), notificationRules, validate, notificationController.sendNow);
router.post('/schedule', auth, requireRole('admin'), notificationRules, validate, notificationController.schedule);
router.get('/history', auth, requireRole('admin'), paginationRules, validate, notificationController.getHistory);

// Any logged-in user (mother app)
router.get('/me', auth, paginationRules, validate, notificationController.getMyNotifications);
router.get('/unread-count', auth, notificationController.getUnreadCount);
router.put('/read-all', auth, notificationController.markAllRead);

// Push token registration
router.post('/devices', auth, notificationController.registerDevice);
router.delete('/devices', auth, notificationController.unregisterDevice);

// Keep this last, because it has a :id parameter
router.put('/:id/read', auth, notificationController.markRead);

module.exports = router;
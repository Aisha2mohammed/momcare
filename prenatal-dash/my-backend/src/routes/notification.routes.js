const express = require('express');
const router = express.Router();
const notificationController = require('../controllers/notification.controller');
const { validate, notificationRules, paginationRules } = require('../utils/validators');
const auth = require('../middlewares/auth');
const { requireRole } = require('../middlewares/roleGuard');

router.post('/send', auth, requireRole('admin'), notificationRules, validate, notificationController.sendNow);
router.post('/schedule', auth, requireRole('admin'), notificationRules, validate, notificationController.schedule);
router.get('/history', auth, requireRole('admin'), paginationRules, validate, notificationController.getHistory);

module.exports = router;


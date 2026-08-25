const express = require('express');
const router = express.Router();

const userController = require('../controllers/user.controller');
const auth = require('../middlewares/auth');

router.use(auth); // All user routes require authentication

router.get('/me', userController.getMe);
router.put('/me', userController.updateMe);
router.put('/emergency-contacts', userController.updateEmergencyContacts);

module.exports = router;

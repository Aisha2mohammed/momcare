const express = require('express');
const router = express.Router();
const authController = require('../controllers/auth.controller');
const { validate, registerRules, loginRules, adminLoginRules, otpSendRules, otpVerifyRules, forgotPasswordRules } = require('../utils/validators');
const auth = require('../middlewares/auth');

router.post('/register', registerRules, validate, authController.register);
router.post('/login', loginRules, validate, authController.login);
router.post('/admin/login', adminLoginRules, validate, authController.adminLogin);
router.post('/otp/send', otpSendRules, validate, authController.sendOtp);
router.post('/otp/verify', otpVerifyRules, validate, authController.verifyOtp);
router.post('/forgot-password', forgotPasswordRules, validate, authController.forgotPassword);
router.post('/admin/register', authController.adminRegister);
router.put('/fcm-token', auth, authController.updateFcmToken);

module.exports = router;

const express = require('express');
const router = express.Router();
const authController = require('../controllers/auth.controller');
const { validate, registerRules, loginRules, adminLoginRules, otpSendRules, otpVerifyRules, forgotPasswordRules, resetPasswordRules } = require('../utils/validators');
const auth = require('../middlewares/auth');
const upload = require('../middlewares/upload');

router.post('/register', registerRules, validate, authController.register);
router.post('/upload', upload.single('file'), authController.uploadFile);
router.post('/login', loginRules, validate, authController.login);
router.post('/admin/login', adminLoginRules, validate, authController.adminLogin);
router.post('/otp/send', otpSendRules, validate, authController.sendOtp);
router.post('/otp/verify', otpVerifyRules, validate, authController.verifyOtp);
router.post('/forgot-password', forgotPasswordRules, validate, authController.forgotPassword);
router.post('/reset-password', resetPasswordRules, validate, authController.resetPassword);
router.post('/admin/register', authController.adminRegister);
router.put('/fcm-token', auth, authController.updateFcmToken);
router.get('/status', auth, authController.getStatus);

module.exports = router;

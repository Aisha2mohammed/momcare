const express = require('express');
const router = express.Router();
const chatbotController = require('../controllers/chatbot.controller');
const auth = require('../middlewares/auth');

router.post('/ask', auth, chatbotController.ask);

module.exports = router;


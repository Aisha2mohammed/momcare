const express = require('express');
const router = express.Router();
const chatController = require('../controllers/chat.controller');
const { validate, paginationRules } = require('../utils/validators');
const auth = require('../middlewares/auth');

router.use(auth);

router.get('/:motherId/:doctorId/messages', paginationRules, validate, chatController.getMessages);
router.post('/:motherId/:doctorId/messages', chatController.sendMessage);

module.exports = router;

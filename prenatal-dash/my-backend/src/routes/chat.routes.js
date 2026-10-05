const express = require('express');
const router = express.Router();
const chatController = require('../controllers/chat.controller');
const { validate, paginationRules } = require('../utils/validators');
const auth = require('../middlewares/auth');
const { requireSelfOrAdmin } = require('../middlewares/ownership');

router.use(auth);

// The thread belongs to exactly two participants. Require the caller to be one
// of them so a logged-in user cannot read someone else's private messages.
// NOTE: must sit on each route, not router.use(), because router.use middleware
// runs before Express has populated req.params.
const isParticipant = requireSelfOrAdmin('motherId', 'doctorId');

router.get('/:motherId/:doctorId/messages', isParticipant, paginationRules, validate, chatController.getMessages);
router.post('/:motherId/:doctorId/messages', isParticipant, chatController.sendMessage);

module.exports = router;

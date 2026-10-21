const express = require('express');
const router = express.Router();
const communityController = require('../controllers/community.controller');
const { validate, paginationRules } = require('../utils/validators');
const auth = require('../middlewares/auth');
const optionalAuth = require('../middlewares/optionalAuth');
const { requireAdmin } = require('../middlewares/roleGuard');

// Public routes (optional auth enriches liked_by_me for signed-in users)
router.get('/groups', communityController.getGroups);
router.get('/groups/:id/posts', optionalAuth, paginationRules, validate, communityController.getGroupPosts);
router.get('/posts', optionalAuth, paginationRules, validate, communityController.getAllPosts);
router.get('/posts/:id/comments', paginationRules, validate, communityController.getPostComments);
router.get('/rules', communityController.getCommunityRules);

// Authenticated user routes
router.post('/posts', auth, communityController.createPost);
router.put('/posts/:id', auth, communityController.updateMyPost);
router.put('/posts/:id/edit', auth, communityController.updateMyPost);
router.delete('/posts/:id', auth, communityController.deleteMyPost);
router.delete('/posts/:id/delete', auth, communityController.deleteMyPost);
router.post('/posts/:id/comments', auth, communityController.createComment);
router.put('/posts/:id/like', auth, communityController.likePost);
router.put('/posts/:id/flag', auth, communityController.reportPost);

// Direct Messaging (Mother-to-Mother private chat)
router.get('/direct-messages/conversations', auth, communityController.getConversations);
router.get('/direct-messages/:otherUserId', auth, paginationRules, validate, communityController.getDirectMessages);
router.post('/direct-messages/:otherUserId', auth, communityController.sendDirectMessage);
router.post('/direct-messages', auth, communityController.sendDirectMessage);
router.put('/direct-messages/messages/:messageId', auth, communityController.updateDirectMessage);
router.put('/direct-messages/:messageId', auth, communityController.updateDirectMessage);
router.put('/direct-messages/:messageId/edit', auth, communityController.updateDirectMessage);
router.delete('/direct-messages/messages/:messageId', auth, communityController.deleteDirectMessage);
router.delete('/direct-messages/:messageId', auth, communityController.deleteDirectMessage);
router.delete('/direct-messages/:messageId/delete', auth, communityController.deleteDirectMessage);

// Admin moderation
router.get('/admin/posts', requireAdmin, paginationRules, validate, communityController.getAdminPosts);
router.put('/admin/posts/:id/dismiss-flag', requireAdmin, communityController.dismissFlag);
router.delete('/admin/posts/:id', requireAdmin, communityController.deletePost);
router.put('/admin/rules', requireAdmin, communityController.updateCommunityRules);

module.exports = router;



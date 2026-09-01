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
router.get('/posts/:id/comments', paginationRules, validate, communityController.getPostComments);

// Authenticated user routes
router.post('/posts', auth, communityController.createPost);
router.post('/posts/:id/comments', auth, communityController.createComment);
router.put('/posts/:id/like', auth, communityController.likePost);

// Admin moderation
router.delete('/admin/posts/:id', requireAdmin, communityController.deletePost);

module.exports = router;


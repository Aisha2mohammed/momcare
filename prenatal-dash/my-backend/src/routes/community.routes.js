const express = require('express');
const router = express.Router();
const communityController = require('../controllers/community.controller');
const { validate, paginationRules } = require('../utils/validators');
const auth = require('../middlewares/auth');
const { requireAdmin } = require('../middlewares/roleGuard');

// Public routes
router.get('/groups', communityController.getGroups);
router.get('/groups/:id/posts', paginationRules, validate, communityController.getGroupPosts);

// Authenticated user routes
router.post('/posts', auth, communityController.createPost);
router.post('/posts/:id/comments', auth, communityController.createComment);
router.put('/posts/:id/like', auth, communityController.likePost);

// Admin moderation
router.delete('/admin/posts/:id', requireAdmin, communityController.deletePost);

module.exports = router;


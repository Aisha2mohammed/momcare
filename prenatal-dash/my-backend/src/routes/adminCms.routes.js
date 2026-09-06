const express = require('express');
const router = express.Router({ mergeParams: true });
const adminCmsController = require('../controllers/adminCms.controller');

// All routes here inherit admin authentication via roleGuard in admin.routes.js
// or explicitly applied here for extra security
const { requireAdmin } = require('../middlewares/roleGuard');
router.use(requireAdmin);

// Standard CMS REST endpoints for all 5 modules:
// nutrition, fetal, exercises, sleep, music
router.get('/:module', adminCmsController.list);
router.get('/:module/:id', adminCmsController.getOne);
router.post('/:module', adminCmsController.create);
router.put('/:module/:id', adminCmsController.update);
router.delete('/:module/:id', adminCmsController.remove);

module.exports = router;

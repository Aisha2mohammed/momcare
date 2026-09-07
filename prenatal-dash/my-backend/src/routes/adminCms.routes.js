const express = require('express');
const router = express.Router({ mergeParams: true });
const adminCmsController = require('../controllers/adminCms.controller');
const { handleFileUpload } = require('../middlewares/fileUpload');

// All routes here inherit admin authentication via roleGuard in admin.routes.js
// or explicitly applied here for extra security
const { requireAdmin } = require('../middlewares/roleGuard');
router.use(requireAdmin);

// CMS Media Upload (Images, Videos, PDFs)
router.post('/upload', handleFileUpload, adminCmsController.uploadMedia);

// Append nutrient section to existing week guide
router.patch('/nutrition/:id/add-nutrient', adminCmsController.appendNutrient);
router.post('/nutrition/:id/add-nutrient', adminCmsController.appendNutrient);

// Standard CMS REST endpoints for all 5 modules:
// nutrition, fetal, exercises, sleep, music
router.get('/:module', adminCmsController.list);
router.get('/:module/:id', adminCmsController.getOne);
router.post('/:module', adminCmsController.create);
router.put('/:module/:id', adminCmsController.update);
router.delete('/:module/:id', adminCmsController.remove);

module.exports = router;


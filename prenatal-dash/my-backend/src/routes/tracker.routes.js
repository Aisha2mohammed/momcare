const express = require('express');
const router = express.Router();

const trackerController = require('../controllers/tracker.controller');
const auth = require('../middlewares/auth');

router.use(auth);

router.get('/progress', trackerController.getProgress);

module.exports = router;

const jwt = require('jsonwebtoken');
const { query } = require('../config/db');
const { sendError } = require('../utils/apiResponse');

/**
 * Verify Firebase token or JWT for mother users
 * Mothers: verified via Firebase (phone OTP)
 * Doctors/Admins: verified via JWT
 */
const auth = async (req, res, next) => {
  try {
    let token;
    if (req.headers.authorization && req.headers.authorization.startsWith('Bearer ')) {
      token = req.headers.authorization.split(' ')[1];
    }

    if (!token) {
      return sendError(res, 401, 'Access denied. No token provided.');
    }

    // Try JWT first (for doctor/admin sessions)
    try {
      const decoded = jwt.verify(token, process.env.JWT_SECRET);
      const user = await query('SELECT id, name, phone, email, role, language, status FROM users WHERE id = $1', [decoded.id]);
      if (user.rows.length === 0) {
        return sendError(res, 401, 'User not found.');
      }
      if (user.rows[0].status === 'suspended') {
        return sendError(res, 403, 'Your account has been suspended.');
      }
      req.user = user.rows[0];
      req.userId = user.rows[0].id;
      req.userRole = user.rows[0].role;
      return next();
    } catch (jwtErr) {
      // If JWT fails, try Firebase (mothers)
    }

    // Firebase verification for mother users
    try {
      const { admin } = require('../config/firebase');
      if (!admin) {
        return sendError(res, 401, 'Firebase not configured for auth.');
      }
      const decodedToken = await admin.auth().verifyIdToken(token);
      const firebaseUid = decodedToken.uid;
      const phone = decodedToken.phone_number;

      // Find or create user with this Firebase UID
      let userResult = await query('SELECT id, name, phone, email, role, language, status FROM users WHERE firebase_uid = $1', [firebaseUid]);
      
      if (userResult.rows.length === 0) {
        // Auto-register mother via Firebase
        userResult = await query(
          `INSERT INTO users (role, phone, firebase_uid, language) 
           VALUES ('mother', $1, $2, $3) 
           RETURNING id, name, phone, email, role, language, status`,
          [phone || decodedToken.phone_number, firebaseUid, req.headers['accept-language']?.substring(0, 2) || 'am']
        );
      }

      const user = userResult.rows[0];
      if (user.status === 'suspended') {
        return sendError(res, 403, 'Your account has been suspended.');
      }

      req.user = user;
      req.userId = user.id;
      req.userRole = 'mother';
      req.firebaseUser = decodedToken;
      return next();
    } catch (fbErr) {
      return sendError(res, 401, 'Invalid authentication token.');
    }
  } catch (err) {
    next(err);
  }
};

module.exports = auth;

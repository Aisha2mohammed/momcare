const jwt = require('jsonwebtoken');
const { query } = require('../config/db');
const { sendError } = require('../utils/apiResponse');

// A rejected account is locked out of protected resources, but it must still
// be able to read its own rejection state so the app can show the "not
// approved" screen. Suspended accounts remain blocked everywhere.
const isAuthStatusRequest = (req) =>
  req.method === 'GET' && /\/auth\/status\/?$/.test(req.originalUrl.split('?')[0]);

/**
 * Authenticate a backend-issued JWT for any role.
 * Account status is checked on every request.
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

    try {
      const decoded = jwt.verify(token, process.env.JWT_SECRET);
      const user = await query('SELECT id, name, phone, email, role, language, status FROM users WHERE id = $1', [decoded.id]);
      if (user.rows.length === 0) {
        return sendError(res, 401, 'User not found.');
      }
      if (user.rows[0].status === 'suspended') {
        return sendError(res, 403, 'Your account has been suspended.');
      }
      if (user.rows[0].status === 'rejected' && !isAuthStatusRequest(req)) {
        return sendError(res, 403, 'Your account was not approved.');
      }
      req.user = user.rows[0];
      req.userId = user.rows[0].id;
      req.userRole = user.rows[0].role;
      return next();
    } catch (err) {
      return sendError(res, 401, 'Invalid authentication token.');
    }
  } catch (err) {
    next(err);
  }
};

module.exports = auth;

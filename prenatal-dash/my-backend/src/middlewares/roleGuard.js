const { sendError } = require('../utils/apiResponse');
const { query } = require('../config/db');

/**
 * Middleware to check user role
 * @param  {...string} roles - Allowed roles (e.g., 'admin', 'doctor', 'mother')
 */
const requireRole = (...roles) => {
  return (req, res, next) => {
    if (!req.user || !req.userRole) {
      return sendError(res, 401, 'Authentication required.');
    }
    if (!roles.includes(req.userRole)) {
      return sendError(res, 403, `Forbidden. Required role: ${roles.join(' or ')}`);
    }
    next();
  };
};

/**
 * Middleware: Ensure doctor is approved
 * Used on doctor-specific endpoints after auth
 */
const requireApprovedDoctor = async (req, res, next) => {
  try {
    if (req.userRole !== 'doctor') {
      return sendError(res, 403, 'Forbidden. Doctor account required.');
    }

    const result = await query(
      'SELECT approval_status FROM doctor_profiles WHERE user_id = $1',
      [req.userId]
    );

    if (result.rows.length === 0) {
      return sendError(res, 404, 'Doctor profile not found. Please complete registration.');
    }

    if (result.rows[0].approval_status !== 'approved') {
      return sendError(res, 403, `Your account is ${result.rows[0].approval_status}. Please wait for admin approval.`);
    }

    next();
  } catch (err) {
    next(err);
  }
};

/**
 * Middleware: Admin only (also checks JWT)
 */
const requireAdmin = async (req, res, next) => {
  try {
    let token;
    if (req.headers.authorization && req.headers.authorization.startsWith('Bearer ')) {
      token = req.headers.authorization.split(' ')[1];
    }

    if (!token) {
      return sendError(res, 401, 'Admin access denied. No token provided.');
    }

    const jwt = require('jsonwebtoken');
    const decoded = jwt.verify(token, process.env.JWT_SECRET);

    if (decoded.role !== 'admin') {
      return sendError(res, 403, 'Forbidden. Admin privileges required.');
    }

    const result = await query(
      'SELECT id, name, email, role, language, status FROM users WHERE id = $1 AND role = $2',
      [decoded.id, 'admin']
    );

    if (result.rows.length === 0) {
      return sendError(res, 401, 'Admin not found.');
    }

    if (result.rows[0].status === 'suspended') {
      return sendError(res, 403, 'Admin account is deactivated.');
    }

    req.user = result.rows[0];
    req.userId = result.rows[0].id;
    req.userRole = 'admin';
    req.isAdmin = true;
    next();
  } catch (err) {
    if (err.name === 'JsonWebTokenError' || err.name === 'TokenExpiredError') {
      return sendError(res, 401, 'Invalid admin token.');
    }
    next(err);
  }
};

module.exports = { requireRole, requireApprovedDoctor, requireAdmin };

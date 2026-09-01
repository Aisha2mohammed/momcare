const jwt = require('jsonwebtoken');
const { query } = require('../config/db');

/**
 * Like `auth`, but never rejects: attaches req.user when a valid JWT is
 * present and the account exists, otherwise continues anonymously.
 * Used to enrich public endpoints (e.g. liked_by_me) for signed-in users.
 */
const optionalAuth = async (req, res, next) => {
  let token;
  if (req.headers.authorization && req.headers.authorization.startsWith('Bearer ')) {
    token = req.headers.authorization.split(' ')[1];
  }
  if (!token) return next();

  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    const user = await query('SELECT id, name, phone, email, role, language, status FROM users WHERE id = $1', [decoded.id]);
    if (user.rows.length === 0 || user.rows[0].status === 'suspended') {
      return next();
    }
    req.user = user.rows[0];
    req.userId = user.rows[0].id;
    req.userRole = user.rows[0].role;
  } catch (err) {
    // Invalid/expired token: treat as anonymous.
  }
  return next();
};

module.exports = optionalAuth;
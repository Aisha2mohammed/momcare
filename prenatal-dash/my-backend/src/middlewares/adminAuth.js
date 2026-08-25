const jwt = require('jsonwebtoken');
const Admin = require('../models/Admin');
const { sendError } = require('../utils/apiResponse');

const adminAuth = async (req, res, next) => {
    try {
        let token;
        if (req.headers.authorization && req.headers.authorization.startsWith('Bearer ')) {
            token = req.headers.authorization.split(' ')[1];
        }

        if (!token) {
            return sendError(res, 401, 'Admin access denied. No token provided.');
        }

        const decoded = jwt.verify(token, process.env.JWT_SECRET);

        if (decoded.role !== 'admin') {
            return sendError(res, 403, 'Forbidden. Admin privileges required.');
        }

        const admin = await Admin.findById(decoded.id).select('-password');
        if (!admin) {
            return sendError(res, 401, 'Admin not found.');
        }

        if (!admin.isActive) {
            return sendError(res, 403, 'Admin account is deactivated.');
        }

        req.admin = admin;
        next();
    } catch (err) {
        if (err.name === 'JsonWebTokenError') {
            return sendError(res, 401, 'Invalid admin token.');
        }
        if (err.name === 'TokenExpiredError') {
            return sendError(res, 401, 'Admin token has expired.');
        }
        next(err);
    }
};

module.exports = adminAuth;

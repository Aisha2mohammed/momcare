/**
 * Centralized error handling middleware
 * Catches all errors and returns consistent { error: { message, code } } shape
 */
const errorHandler = (err, req, res, next) => {
  let statusCode = err.statusCode || 500;
  let message = err.message || 'Internal Server Error';

  // PostgreSQL unique violation
  if (err.code === '23505') {
    statusCode = 409;
    const detail = err.detail || '';
    const matches = detail.match(/Key \((.*?)\)=\((.*?)\)/);
    message = matches ? `A record with this ${matches[1]} already exists.` : 'Duplicate entry.';
  }

  // PostgreSQL foreign key violation
  if (err.code === '23503') {
    statusCode = 400;
    message = 'Referenced record not found.';
  }

  // PostgreSQL not null violation
  if (err.code === '23502') {
    statusCode = 400;
    message = `Required field missing: ${err.column || 'unknown'}`;
  }

  // PostgreSQL invalid input
  if (err.code === '22P02') {
    statusCode = 400;
    message = 'Invalid input format.';
  }

  // JWT Errors
  if (err.name === 'JsonWebTokenError') {
    statusCode = 401;
    message = 'Invalid token.';
  }
  if (err.name === 'TokenExpiredError') {
    statusCode = 401;
    message = 'Token has expired.';
  }

  // Validation Error (express-validator)
  if (err.type === 'ValidationError' || err.name === 'ValidationError') {
    statusCode = 422;
    message = err.message || 'Validation failed';
  }

  // Firebase auth errors
  if (err.code && err.code.startsWith('auth/')) {
    statusCode = 401;
    message = err.message || 'Authentication failed';
  }

  if (process.env.NODE_ENV === 'development') {
    console.error('❌ Error:', err);
    return res.status(statusCode).json({
      error: { message, code: statusCode, stack: err.stack },
    });
  }

  res.status(statusCode).json({
    error: { message, code: statusCode },
  });
};

module.exports = errorHandler;

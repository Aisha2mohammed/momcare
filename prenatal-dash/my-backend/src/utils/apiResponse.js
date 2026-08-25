/**
 * Unified API Response Helpers
 * Consistent { success, message, data, meta } shape
 */

const sendSuccess = (res, statusCode = 200, message = 'Success', data = {}, meta = null) => {
  const response = { success: true, message, data };
  if (meta) response.meta = meta;
  return res.status(statusCode).json(response);
};

const sendError = (res, statusCode = 500, message = 'Internal Server Error', errors = null) => {
  const response = {
    error: { message, code: statusCode },
  };
  if (errors) response.error.details = errors;
  if (process.env.NODE_ENV === 'development') {
    response.error.timestamp = new Date().toISOString();
  }
  return res.status(statusCode).json(response);
};

const sendPaginated = (res, data, page, limit, total, message = 'Data retrieved successfully') => {
  return res.status(200).json({
    success: true,
    message,
    data,
    meta: {
      total,
      page: Number(page),
      limit: Number(limit),
      totalPages: Math.ceil(total / limit),
      hasNext: page * limit < total,
      hasPrev: page > 1,
    },
  });
};

const paginationParams = (query) => {
  const page = Math.max(1, parseInt(query.page, 10) || 1);
  const limit = Math.min(100, Math.max(1, parseInt(query.limit, 10) || 20));
  const offset = (page - 1) * limit;
  return { page, limit, offset };
};

module.exports = { sendSuccess, sendError, sendPaginated, paginationParams };

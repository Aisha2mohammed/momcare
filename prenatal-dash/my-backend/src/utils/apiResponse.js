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
  const pagination = {
    total,
    page: Number(page),
    limit: Number(limit),
    totalPages: Math.ceil(total / limit),
    hasNext: page * limit < total,
    hasPrev: page > 1,
  };
  return res.status(200).json({
    success: true,
    message,
    data,
    // `meta` is the canonical key used by the mobile app. `pagination` is an
    // identical alias kept because admin-panal's cmsClient.list reads
    // res.pagination — without it every admin list falls back to
    // { total: <current page length> } and reports wrong totals.
    meta: pagination,
    pagination,
  });
};

const paginationParams = (query) => {
  const page = Math.max(1, parseInt(query.page, 10) || 1);
  const limit = Math.min(100, Math.max(1, parseInt(query.limit, 10) || 20));
  const offset = (page - 1) * limit;
  return { page, limit, offset };
};

module.exports = { sendSuccess, sendError, sendPaginated, paginationParams };

const { sendError } = require('../utils/apiResponse');

/**
 * True when the caller is an administrator. `auth` sets req.userRole, and
 * `requireAdmin` additionally sets req.isAdmin.
 */
const callerIsAdmin = (req) => req.userRole === 'admin' || req.isAdmin === true;

const UUID_RE =
  /^[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;

const canonicalizeUuid = (value) =>
  typeof value === 'string' && UUID_RE.test(value) ? value.toLowerCase() : value;

/**
 * Ownership guard for routes whose URL identifies the resource owner.
 *
 * Requires that at least one of the named route params equals the caller's own
 * id, so a logged-in user cannot read or mutate someone else's record just by
 * editing the id in the URL. Administrators bypass.
 *
 * Must be mounted *after* an authenticating middleware (auth / requireAdmin) so
 * that req.userId is populated.
 *
 * @param {...string} paramNames route params to accept, e.g. 'id', or
 *                              'motherId', 'doctorId' when either may match.
 */
const requireSelfOrAdmin = (...paramNames) => {
  return (req, res, next) => {
    if (!req.userId) {
      return sendError(res, 401, 'Authentication required.');
    }
    if (callerIsAdmin(req)) {
      return next();
    }
    const owns = paramNames.some(
      (name) => canonicalizeUuid(req.params[name]) === canonicalizeUuid(req.userId)
    );
    if (!owns) {
      return sendError(res, 403, 'Forbidden. You may only access your own resources.');
    }
    return next();
  };
};

module.exports = { requireSelfOrAdmin, callerIsAdmin };
const { query } = require('../config/db');

/**
 * Log an admin action to the audit_logs table
 * @param {string} adminId - UUID of the admin performing the action
 * @param {string} actionType - e.g., 'APPROVE_DOCTOR', 'REJECT_DOCTOR', 'SUSPEND_USER', 'CREATE_CONTENT', etc.
 * @param {string} targetTable - The database table affected
 * @param {string} targetId - UUID of the affected row
 * @param {object} details - JSON object with before/after or additional context
 */
const logAdminAction = async (adminId, actionType, targetTable, targetId, details = {}) => {
  try {
    await query(
      `INSERT INTO audit_logs (admin_id, action_type, target_table, target_id, details_json)
       VALUES ($1, $2, $3, $4, $5)`,
      [adminId, actionType, targetTable, targetId, JSON.stringify(details)]
    );
    console.log(`📝 Audit log: ${actionType} on ${targetTable}(${targetId}) by admin ${adminId}`);
  } catch (err) {
    console.error('❌ Audit log error:', err.message);
    // Don't throw - audit logging should never break the main flow
  }
};

module.exports = { logAdminAction };

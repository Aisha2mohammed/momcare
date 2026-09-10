const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { query, getClient } = require('../config/db');
const { initFirebase, admin } = require('../config/firebase');
const { sendSuccess, sendError } = require('../utils/apiResponse');
const { getPregnancyProgress } = require('../services/pregnancyCalculator');
const { getIO } = require('../config/socket');

// ── Helper: Generate JWT ───────────────────────────────────────────────
const signToken = (id, role = 'user') => {
  return jwt.sign({ id, role }, process.env.JWT_SECRET, {
    expiresIn: process.env.JWT_EXPIRES_IN || '30d',
  });
};

// ── POST /api/v1/auth/register ─────────────────────────────────────────
exports.register = async (req, res, next) => {
  const client = await getClient();
  try {
    const { phone, name, language = 'am', password, role = 'mother', lmpDate } = req.body;

    // Check if user exists
    const existing = await query('SELECT id FROM users WHERE phone = $1', [phone]);
    if (existing.rows.length > 0) {
      return sendError(res, 409, 'A user with this phone number already exists.');
    }

    let passwordHash = null;
    if (password) {
      passwordHash = await bcrypt.hash(password, 12);
    }

    await client.query('BEGIN');

    const userResult = await client.query(
      `INSERT INTO users (role, name, phone, email, password_hash, language, status)
       VALUES ($1, $2, $3, $4, $5, $6, 'active')
       RETURNING id, role, name, phone, email, language, status, created_at`,
      [role, name || null, phone, req.body.email || null, passwordHash, language]
    );
    const user = userResult.rows[0];

    // If role is mother, create mother profile
    if (role === 'mother' && lmpDate) {
      const dueDate = new Date(new Date(lmpDate).getTime() + 280 * 24 * 60 * 60 * 1000);
      const gestationalWeek = Math.max(1, Math.min(42,
        Math.floor((Date.now() - new Date(lmpDate).getTime()) / (7 * 24 * 60 * 60 * 1000)) + 1
      ));

      await client.query(
        `INSERT INTO mother_profiles (user_id, lmp_date, due_date, gestational_week)
         VALUES ($1, $2, $3, $4)`,
        [user.id, lmpDate, dueDate, gestationalWeek]
      );
    }

    // If role is doctor, create doctor profile placeholder
    if (role === 'doctor') {
      await client.query(
        `INSERT INTO doctor_profiles (user_id, approval_status)
         VALUES ($1, 'pending')`,
        [user.id]
      );
    }

    await client.query('COMMIT');

    const token = signToken(user.id, role);

    return sendSuccess(res, 201, 'Registration successful', {
      token,
      user: { ...user, role },
    });
  } catch (err) {
    await client.query('ROLLBACK').catch(() => {});
    next(err);
  } finally {
    client.release();
  }
};

// ── POST /api/v1/auth/login ────────────────────────────────────────────
exports.login = async (req, res, next) => {
  try {
    const { phone, password } = req.body;

    const result = await query(
      'SELECT id, role, name, phone, email, language, status, password_hash FROM users WHERE phone = $1',
      [phone]
    );

    if (result.rows.length === 0) {
      return sendError(res, 401, 'Invalid credentials.');
    }

    const user = result.rows[0];

    if (user.status !== 'active') {
      return sendError(res, 403, 'Your account has been deactivated.');
    }

    // If password is set, verify it
    if (user.password_hash && password) {
      const isMatch = await bcrypt.compare(password, user.password_hash);
      if (!isMatch) return sendError(res, 401, 'Invalid credentials.');
    } else if (!user.password_hash && !password) {
      // Allow phone-only login for OTP-style flow
    } else {
      return sendError(res, 401, 'Invalid credentials.');
    }

    const token = signToken(user.id, user.role);

    // Get pregnancy progress if mother
    let progress = null;
    if (user.role === 'mother') {
      const profileResult = await query(
        'SELECT lmp_date FROM mother_profiles WHERE user_id = $1',
        [user.id]
      );
      if (profileResult.rows.length > 0 && profileResult.rows[0].lmp_date) {
        progress = getPregnancyProgress(profileResult.rows[0].lmp_date);
      }
    }

    const { password_hash, ...safeUser } = user;

    return sendSuccess(res, 200, 'Login successful', {
      token,
      user: { ...safeUser, ...progress },
    });
  } catch (err) {
    next(err);
  }
};

// ── POST /api/v1/auth/admin/login ─────────────────────────────────────
exports.adminLogin = async (req, res, next) => {
  try {
    const { email, password } = req.body;

    const result = await query(
      'SELECT id, role, name, email, password_hash, status FROM users WHERE email = $1 AND role = $2',
      [email, 'admin']
    );

    if (result.rows.length === 0) {
      return sendError(res, 401, 'Invalid admin credentials.');
    }

    const admin = result.rows[0];

    if (admin.status !== 'active') {
      return sendError(res, 403, 'Admin account is deactivated.');
    }

    const isMatch = await bcrypt.compare(password, admin.password_hash);
    if (!isMatch) {
      return sendError(res, 401, 'Invalid admin credentials.');
    }

    const token = jwt.sign(
      { id: admin.id, role: 'admin' },
      process.env.JWT_SECRET,
      { expiresIn: process.env.JWT_EXPIRES_IN || '30d' }
    );

    // Update last login
    await query('UPDATE users SET updated_at = NOW() WHERE id = $1', [admin.id]);

    const { password_hash, ...safeAdmin } = admin;

    return sendSuccess(res, 200, 'Admin login successful', { token, admin: safeAdmin });
  } catch (err) {
    next(err);
  }
};

// ── POST /api/v1/auth/otp/send ─────────────────────────────────────────
exports.sendOtp = async (req, res, next) => {
  try {
    const { phone } = req.body;

    if (!phone) {
      return sendError(res, 400, 'Phone number is required.');
    }

    // In production, integrate with SMS provider (e.g., Twilio, Africa's Talking)
    // For now, simulate OTP sending
    const otp = Math.floor(100000 + Math.random() * 900000).toString();

    // Store OTP temporarily (in production use Redis with TTL)
    // For demo, we store in a simple in-memory map
    if (!global.otpStore) global.otpStore = new Map();
    global.otpStore.set(phone, { otp, expiresAt: Date.now() + 5 * 60 * 1000 });

    console.log(`📱 OTP for ${phone}: ${otp}`);

    return sendSuccess(res, 200, 'OTP sent successfully', { phone });
  } catch (err) {
    next(err);
  }
};

// ── POST /api/v1/auth/otp/verify ──────────────────────────────────────
exports.verifyOtp = async (req, res, next) => {
  try {
    const { phone, otp } = req.body;

    if (!phone || !otp) {
      return sendError(res, 400, 'Phone and OTP are required.');
    }

    // Verify OTP
    if (!global.otpStore) global.otpStore = new Map();
    const stored = global.otpStore.get(phone);

    if (!stored) {
      return sendError(res, 400, 'No OTP found. Please request a new one.');
    }

    if (Date.now() > stored.expiresAt) {
      global.otpStore.delete(phone);
      return sendError(res, 400, 'OTP has expired. Please request a new one.');
    }

    if (stored.otp !== otp) {
      return sendError(res, 400, 'Invalid OTP.');
    }

    global.otpStore.delete(phone);

    // Find or create user
    let userResult = await query(
      'SELECT id, role, name, phone, language, status FROM users WHERE phone = $1',
      [phone]
    );

    let token;
    if (userResult.rows.length > 0) {
      const user = userResult.rows[0];
      token = signToken(user.id, user.role);
      return sendSuccess(res, 200, 'OTP verified. Login successful.', {
        token,
        user,
        isNewUser: false,
      });
    } else {
      // New user - return token with incomplete registration flag
      token = jwt.sign({ phone, temp: true }, process.env.JWT_SECRET, { expiresIn: '15m' });
      return sendSuccess(res, 200, 'OTP verified. Please complete registration.', {
        token,
        isNewUser: true,
      });
    }
  } catch (err) {
    next(err);
  }
};

// ── POST /api/v1/auth/forgot-password ──────────────────────────────────
exports.forgotPassword = async (req, res, next) => {
  try {
    const { phone } = req.body;

    const existing = await query('SELECT id FROM users WHERE phone = $1', [phone]);
    if (existing.rows.length === 0) {
      return sendError(res, 404, 'No account found with this phone number.');
    }

    // Generate reset OTP
    const otp = Math.floor(100000 + Math.random() * 900000).toString();
    if (!global.otpStore) global.otpStore = new Map();
    global.otpStore.set(`reset:${phone}`, { otp, expiresAt: Date.now() + 5 * 60 * 1000 });

    console.log(`🔑 Password Reset OTP for ${phone}: ${otp}`);

    return sendSuccess(res, 200, 'Reset OTP sent to your phone.');
  } catch (err) {
    next(err);
  }
};

// ── POST /api/v1/auth/reset-password ───────────────────────────────────
exports.resetPassword = async (req, res, next) => {
  try {
    const { phone, otp, password } = req.body;

    if (!phone || !otp || !password) {
      return sendError(res, 400, 'Phone, OTP and new password are required.');
    }

    if (!global.otpStore) global.otpStore = new Map();
    const stored = global.otpStore.get(`reset:${phone}`);

    if (!stored) {
      return sendError(res, 400, 'No reset OTP found. Please request a new one.');
    }

    if (Date.now() > stored.expiresAt) {
      global.otpStore.delete(`reset:${phone}`);
      return sendError(res, 400, 'Reset OTP has expired. Please request a new one.');
    }

    if (stored.otp !== otp) {
      return sendError(res, 400, 'Invalid OTP.');
    }

    global.otpStore.delete(`reset:${phone}`);

    const userResult = await query('SELECT id FROM users WHERE phone = $1', [phone]);
    if (userResult.rows.length === 0) {
      return sendError(res, 404, 'No account found with this phone number.');
    }

    const passwordHash = await bcrypt.hash(password, 12);
    await query('UPDATE users SET password_hash = $1 WHERE id = $2', [
      passwordHash,
      userResult.rows[0].id,
    ]);

    return sendSuccess(res, 200, 'Password reset successfully. Please login with your new password.');
  } catch (err) {
    next(err);
  }
};

// ── PUT /api/v1/auth/fcm-token ─────────────────────────────────────────
exports.updateFcmToken = async (req, res, next) => {
  try {
    const { fcmToken } = req.body;
    if (!fcmToken) {
      return sendError(res, 400, 'FCM token is required.');
    }

    await query('UPDATE users SET fcm_token = $1 WHERE id = $2', [fcmToken, req.user.id]);

    return sendSuccess(res, 200, 'FCM token updated', { fcmToken });
  } catch (err) {
    next(err);
  }
};

// ── POST /api/v1/auth/admin/register (internal/seeding) ──────────────
exports.adminRegister = async (req, res, next) => {
  try {
    const { name, email, password, secret } = req.body;

    if (secret !== process.env.ADMIN_REGISTRATION_SECRET) {
      return sendError(res, 403, 'Invalid registration secret.');
    }

    const existing = await query('SELECT id FROM users WHERE email = $1', [email]);
    if (existing.rows.length > 0) {
      return sendError(res, 409, 'Admin with this email already exists.');
    }

    const passwordHash = await bcrypt.hash(password, 12);

    const result = await query(
      `INSERT INTO users (role, name, email, password_hash, language, status)
       VALUES ('admin', $1, $2, $3, 'en', 'active')
       RETURNING id, role, name, email, language, status, created_at`,
      [name, email, passwordHash]
    );

    const admin = result.rows[0];
    const token = jwt.sign(
      { id: admin.id, role: 'admin' },
      process.env.JWT_SECRET,
      { expiresIn: process.env.JWT_EXPIRES_IN || '30d' }
    );

    return sendSuccess(res, 201, 'Admin created successfully', { token, admin });
  } catch (err) {
    next(err);
  }
};

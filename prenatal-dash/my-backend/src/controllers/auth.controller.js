const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const axios = require('axios'); // ← NEW (AfroMessage SMS)
const { query, getClient } = require('../config/db');
const { initFirebase, admin } = require('../config/firebase');
const { sendSuccess, sendError } = require('../utils/apiResponse');
const { getPregnancyProgress } = require('../services/pregnancyCalculator');
const { getIO } = require('../config/socket');

// ── Helper: Pregnancy progress for mothers ─────────────────────────────
// Returns {} for non-mothers and for mothers with no LMP date set, so
// `lmpDate` is present in a login response only when the core profile is
// complete. Shared by /auth/login and /auth/otp/verify so the two stay in sync.
const getMotherProgress = async (userId, role) => {
  if (role !== 'mother') return {};
  const profileResult = await query(
    'SELECT lmp_date FROM mother_profiles WHERE user_id = $1',
    [userId]
  );
  if (profileResult.rows.length > 0 && profileResult.rows[0].lmp_date) {
    return getPregnancyProgress(profileResult.rows[0].lmp_date);
  }
  return {};
};

// ── Helper: Generate JWT ───────────────────────────────────────────────
const signToken = (id, role = 'user') => {
  return jwt.sign({ id, role }, process.env.JWT_SECRET, {
    expiresIn: process.env.JWT_EXPIRES_IN || '30d',
  });
};

// ── Helper: Ethiopian phone variants normalizer ────────────────────────
const getPhoneVariants = (rawPhone) => {
  if (!rawPhone) return [];
  const clean = String(rawPhone).trim().replace(/[\s-()]/g, '');
  const variants = new Set([clean]);

  if (clean.startsWith('+251')) {
    variants.add('0' + clean.slice(4));
    variants.add(clean.slice(1));
    variants.add(clean.slice(4));
  } else if (clean.startsWith('251')) {
    variants.add('+' + clean);
    variants.add('0' + clean.slice(3));
    variants.add(clean.slice(3));
  } else if (clean.startsWith('09') || clean.startsWith('07')) {
    variants.add('+251' + clean.slice(1));
    variants.add('251' + clean.slice(1));
    variants.add(clean.slice(1));
  } else if (clean.startsWith('9') || clean.startsWith('7')) {
    variants.add('+251' + clean);
    variants.add('0' + clean);
    variants.add('251' + clean);
  }
  return Array.from(variants);
};

// ── Helper: Send SMS through AfroMessage (NEW) ─────────────────────────
// Needs AFROMESSAGE_API_KEY and AFROMESSAGE_SENDER_ID in .env.
// Throws an Error if the gateway rejects the message.
const sendAfroSms = async (phone, message) => {
  const response = await axios.post(
    'https://api.afromessage.com/api/send',
    {
      from: process.env.AFROMESSAGE_SENDER_ID,
      to: phone,
      message,
    },
    {
      headers: {
        Authorization: `Bearer ${process.env.AFROMESSAGE_API_KEY}`,
        'Content-Type': 'application/json',
      },
      timeout: 15000,
    }
  );

  // AfroMessage answers { acknowledge: 'success' | 'error', ... }
  const ack = response.data && response.data.acknowledge;
  if (response.status !== 200 || (ack && ack !== 'success')) {
    console.error('AfroMessage API failed:', JSON.stringify(response.data));
    throw new Error('Failed to send SMS via AfroMessage');
  }
  return response.data;
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

    // New mothers need admin approval before they are active; doctors keep
    // users.status = 'active' and are gated by doctor_profiles.approval_status.
    const signupStatus = role === 'doctor' ? 'active' : 'pending';

    const userResult = await client.query(
      `INSERT INTO users (role, name, phone, email, password_hash, language, status)
       VALUES ($1, $2, $3, $4, $5, $6, $7)
       RETURNING id, role, name, phone, email, language, status, created_at`,
      [role, name || null, phone, req.body.email || null, passwordHash, language, signupStatus]
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
    const variants = getPhoneVariants(phone);

    const result = await query(
      'SELECT id, role, name, phone, email, language, status, password_hash FROM users WHERE phone = ANY($1)',
      [variants]
    );

    if (result.rows.length === 0) {
      return sendError(res, 401, 'Invalid credentials.');
    }

    const user = result.rows[0];

    // 'active' and 'pending' may sign in (a pending mother is let in so the app
    // can render its "waiting for approval" screen); suspended/rejected cannot.
    if (user.status === 'suspended') {
      return sendError(res, 403, 'Your account has been suspended.');
    }
    if (user.status === 'rejected') {
      return sendError(res, 403, 'Your account was not approved.');
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

    // Get pregnancy progress if mother (lmpDate present only when LMP is set)
    const progress = await getMotherProgress(user.id, user.role);

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
// CHANGED: OTP is now delivered by SMS through AfroMessage.
exports.sendOtp = async (req, res, next) => {
  try {
    const { phone } = req.body;

    if (!phone) {
      return sendError(res, 400, 'Phone number is required.');
    }

    const otp = Math.floor(100000 + Math.random() * 900000).toString();

    // Store OTP temporarily (in production use Redis with TTL)
    if (!global.otpStore) global.otpStore = new Map();
    global.otpStore.set(phone, { otp, expiresAt: Date.now() + 5 * 60 * 1000 });

    try {
      await sendAfroSms(phone, `Your MomCare verification code is ${otp}. It expires in 5 minutes.`);
    } catch (smsErr) {
      // SMS failed: drop the stored OTP so it can't be used
      global.otpStore.delete(phone);
      console.error('Send OTP SMS error:', smsErr.response?.data || smsErr.message);
      return sendError(res, 502, 'Failed to send OTP via SMS. Please try again.');
    }

    if (process.env.NODE_ENV !== 'production') {
      console.log(`📱 OTP for ${phone}: ${otp}`);
    }

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
      // Mirror /auth/login: suspended/rejected are blocked, while 'active' and
      // 'pending' proceed. `status` is part of the returned user so both flows
      // let the client show the pending-approval screen consistently.
      if (user.status === 'suspended') {
        return sendError(res, 403, 'Your account has been suspended.');
      }
      if (user.status === 'rejected') {
        return sendError(res, 403, 'Your account was not approved.');
      }
      token = signToken(user.id, user.role);
      // Same contract as /auth/login: include pregnancy progress so clients
      // can tell whether the mother has completed her core profile.
      const progress = await getMotherProgress(user.id, user.role);
      return sendSuccess(res, 200, 'OTP verified. Login successful.', {
        token,
        user: { ...user, ...progress },
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
// Sends reset verification code by SMS through AfroMessage
exports.forgotPassword = async (req, res, next) => {
  try {
    const { phone } = req.body;
    if (!phone) return sendError(res, 400, 'Phone number is required.');

    const variants = getPhoneVariants(phone);
    const existing = await query('SELECT id, phone, name FROM users WHERE phone = ANY($1)', [variants]);
    if (existing.rows.length === 0) {
      return sendError(res, 404, 'No account found with this phone number.');
    }

    const user = existing.rows[0];
    const canonicalPhone = user.phone || phone.trim();

    // Generate 6-digit reset OTP
    const otp = Math.floor(100000 + Math.random() * 900000).toString();
    if (!global.otpStore) global.otpStore = new Map();
    const expiry = Date.now() + 10 * 60 * 1000; // 10 minutes

    // Store under both entered phone and canonical user phone
    global.otpStore.set(`reset:${canonicalPhone}`, { otp, expiresAt: expiry });
    global.otpStore.set(`reset:${phone.trim()}`, { otp, expiresAt: expiry });

    try {
      await sendAfroSms(canonicalPhone, `Your MomCare password reset code is ${otp}. It expires in 10 minutes.`);
    } catch (smsErr) {
      console.error('Forgot password SMS error:', smsErr.response?.data || smsErr.message);
      if (process.env.NODE_ENV !== 'production') {
        console.log(`⚠️ SMS gateway error, but dev reset OTP for ${canonicalPhone} is: ${otp}`);
      } else {
        global.otpStore.delete(`reset:${canonicalPhone}`);
        global.otpStore.delete(`reset:${phone.trim()}`);
        return sendError(res, 502, 'Failed to send reset code via SMS. Please try again.');
      }
    }

    if (process.env.NODE_ENV !== 'production') {
      console.log(`🔑 Password Reset OTP for ${canonicalPhone}: ${otp}`);
    }

    return sendSuccess(res, 200, 'Reset OTP sent to your phone.', { phone: canonicalPhone });
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

    const cleanOtp = String(otp).trim();
    const variants = getPhoneVariants(phone);

    const userResult = await query(
      'SELECT id, role, name, phone, email, language, status FROM users WHERE phone = ANY($1)',
      [variants]
    );
    if (userResult.rows.length === 0) {
      return sendError(res, 404, 'No account found with this phone number.');
    }
    const user = userResult.rows[0];
    const canonicalPhone = user.phone || phone.trim();

    if (!global.otpStore) global.otpStore = new Map();
    const stored = global.otpStore.get(`reset:${phone.trim()}`) ||
                   global.otpStore.get(`reset:${canonicalPhone}`);

    if (!stored) {
      return sendError(res, 400, 'No reset code found. Please request a new one.');
    }

    if (Date.now() > stored.expiresAt) {
      global.otpStore.delete(`reset:${phone.trim()}`);
      global.otpStore.delete(`reset:${canonicalPhone}`);
      return sendError(res, 400, 'Reset code has expired. Please request a new one.');
    }

    if (String(stored.otp).trim() !== cleanOtp) {
      return sendError(res, 400, 'Invalid verification code. Please check and try again.');
    }

    global.otpStore.delete(`reset:${phone.trim()}`);
    global.otpStore.delete(`reset:${canonicalPhone}`);

    const passwordHash = await bcrypt.hash(password, 12);
    await query('UPDATE users SET password_hash = $1 WHERE id = $2', [
      passwordHash,
      user.id,
    ]);

    return sendSuccess(res, 200, 'Password reset successfully. Please login with your new password.', {
      phone: canonicalPhone,
    });
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

// ── GET /api/v1/auth/status ───────────────────────────────────────────
exports.getStatus = async (req, res, next) => {
  try {
    const userResult = await query(
      'SELECT id, role, name, phone, email, language, status, approved_at, rejected_at FROM users WHERE id = $1',
      [req.user.id]
    );
    if (userResult.rows.length === 0) {
      return sendError(res, 404, 'User not found.');
    }
    const user = userResult.rows[0];
    const progress = await getMotherProgress(user.id, user.role);
    return sendSuccess(res, 200, 'Account status retrieved', {
      user: { ...user, ...progress },
      status: user.status,
      isApproved: user.status === 'active',
      isPending: user.status === 'pending',
      isRejected: user.status === 'rejected',
      isSuspended: user.status === 'suspended',
      needsProfileSetup: user.role === 'mother' && (!progress.lmpDate || progress.lmpDate.toString().trim() === ''),
    });
  } catch (err) {
    next(err);
  }
};
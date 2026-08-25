const express = require('express');
const helmet = require('helmet');
const cors = require('cors');
const morgan = require('morgan');
const rateLimit = require('express-rate-limit');
const errorHandler = require('./middlewares/errorHandler');

const app = express();

// ── Security Middlewares ──────────────────────────────────────────────
app.use(helmet());
app.use(cors({
  origin: process.env.ALLOWED_ORIGINS ? process.env.ALLOWED_ORIGINS.split(',') : '*',
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH'],
  allowedHeaders: ['Content-Type', 'Authorization'],
  credentials: true,
}));

// Rate Limiting: 100 requests per 15 minutes on /api/
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 100,
  standardHeaders: true,
  legacyHeaders: false,
  message: { error: { message: 'Too many requests, please try again later.', code: 429 } },
});
app.use('/api/', limiter);

// ── Body Parsing & Logging ───────────────────────────────────────────
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));
app.use(morgan(process.env.NODE_ENV === 'production' ? 'combined' : 'dev'));

// ── API Routes (v1) ─────────────────────────────────────────────────
const authRoutes = require('./routes/auth.routes');
const motherRoutes = require('./routes/mother.routes');
const doctorRoutes = require('./routes/doctor.routes');
const appointmentRoutes = require('./routes/appointment.routes');
const chatRoutes = require('./routes/chat.routes');
const nutritionRoutes = require('./routes/nutrition.routes');
const fetalRoutes = require('./routes/fetal.routes');
const exerciseRoutes = require('./routes/exercise.routes');
const sleepRoutes = require('./routes/sleep.routes');
const musicRoutes = require('./routes/music.routes');
const healthTipRoutes = require('./routes/healthTip.routes');
const notificationRoutes = require('./routes/notification.routes');
const emergencyRoutes = require('./routes/emergency.routes');
const communityRoutes = require('./routes/community.routes');
const chatbotRoutes = require('./routes/chatbot.routes');
const adminRoutes = require('./routes/admin.routes');

app.use('/api/v1/auth', authRoutes);
app.use('/api/v1/mothers', motherRoutes);
app.use('/api/v1/doctors', doctorRoutes);
app.use('/api/v1/appointments', appointmentRoutes);
app.use('/api/v1/chat', chatRoutes);
app.use('/api/v1/nutrition', nutritionRoutes);
app.use('/api/v1/fetal', fetalRoutes);
app.use('/api/v1/exercises', exerciseRoutes);
app.use('/api/v1/sleep-tips', sleepRoutes);
app.use('/api/v1/music', musicRoutes);
app.use('/api/v1/health-tips', healthTipRoutes);
app.use('/api/v1/notifications', notificationRoutes);
app.use('/api/v1/emergency', emergencyRoutes);
app.use('/api/v1/community', communityRoutes);
app.use('/api/v1/chatbot', chatbotRoutes);
app.use('/api/v1/admin', adminRoutes);

// ── Health Check ─────────────────────────────────────────────────────
const { query: dbQuery } = require('./config/db');
app.get('/api/v1/health', async (req, res) => {
  try {
    const result = await dbQuery('SELECT NOW() as current_time');
    res.status(200).json({
      success: true,
      status: 'OK',
      server: 'MaternaLink API',
      version: '1.0.0',
      timestamp: new Date().toISOString(),
      database: {
        status: 'connected',
        time: result.rows[0].current_time,
      },
      environment: process.env.NODE_ENV,
    });
  } catch (err) {
    res.status(503).json({
      success: false,
      status: 'DEGRADED',
      server: 'MaternaLink API',
      database: { status: 'disconnected', error: err.message },
    });
  }
});

// ── 404 Handler ─────────────────────────────────────────────────────
app.use((req, res) => {
  res.status(404).json({
    error: { message: `Route ${req.originalUrl} not found`, code: 404 },
  });
});

// ── Global Error Handler ────────────────────────────────────────────
app.use(errorHandler);

module.exports = app;

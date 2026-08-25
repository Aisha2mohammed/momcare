# MaternaLink Backend - Build Progress

## Phase 1: ✅ Project Scaffolding & Database Setup
- [x] Install new dependencies (pg, knex, socket.io, nodemailer, express-validator, etc.)
- [x] Create knexfile.js (dev, production, test environments)
- [x] Create .env.example
- [x] Create migration file with all 20+ tables
- [x] Create seed script (health providers)
- [x] Update package.json with new scripts

## Phase 2: ✅ Core Middleware & Utilities
- [x] Auth middleware (Firebase + JWT + role support)
- [x] Role guard middleware (requireRole, requireApprovedDoctor, requireAdmin)
- [x] Error handler (PostgreSQL error codes handled)
- [x] Audit logger service (centralized logAdminAction)
- [x] Pagination helper (sendPaginated in apiResponse.js)
- [x] Validation rules (all endpoint validators)

## Phase 3: ✅ Auth System
- [x] POST /auth/register (mother or doctor with role-specific fields)
- [x] POST /auth/login (phone + password, or OTP-style)
- [x] POST /auth/otp/send (in-memory OTP with TTL)
- [x] POST /auth/otp/verify (auto-register new mothers)
- [x] POST /auth/forgot-password (reset OTP flow)
- [x] PUT /auth/fcm-token (update device token)

## Phase 4: ✅ Mother Profile & Health Tracking
- [x] GET/PUT /mothers/:id/profile (with LMP auto-calculation)
- [x] GET /mothers/:id/gestational-week (from LMP)
- [x] GET/POST /mothers/:id/health-logs (symptoms, weight, mood)
- [x] GET/POST /mothers/:id/emergency-contacts (CRUD)
- [x] POST /mothers/:id/emergency-alert (GPS + contacts + socket)

## Phase 5: ✅ Content Endpoints
- [x] GET /fetal-tracker/:week (trilingual)
- [x] GET /nutrition?trimester= (trilingual)
- [x] GET /exercises?trimester= (trilingual)
- [x] GET /sleep-tips?trimester= (trilingual)
- [x] GET /music?category= (trilingual)
- [x] GET /health-tips (trilingual)
- [x] Admin CRUD for all content types

## Phase 6: ✅ Health Providers & Doctor Discovery
- [x] GET /health-providers (active only)
- [x] GET /health-providers/:id/doctors (approved only)
- [x] GET /doctors/:id (public profile, approved only)
- [x] POST /mothers/:id/assign-doctor

## Phase 7: ✅ Doctor Self-Service
- [x] POST /doctors/register (with credential docs)
- [x] GET/PUT /doctors/:id/profile
- [x] Availability slots CRUD (day/time/duration)
- [x] Doctor appointment list with status/date filters
- [x] Patient list sorted by risk indicator
- [x] Doctor notify patients (push notification)

## Phase 8: ✅ Appointments
- [x] POST /appointments (book with conflict check)
- [x] GET /appointments/:id (with doctor/mother details)
- [x] PUT /appointments/:id/status (socket + FCM)
- [x] PUT /appointments/:id/respond (doctor accept/reject)
- [x] POST /appointments/:id/clinical-record (notes + risk)

## Phase 9: ✅ Chat
- [x] GET /chat/:motherId/:doctorId/messages (paginated)
- [x] POST /chat/:motherId/:doctorId/messages (text + attachment)
- [x] Socket.io events (chat:message, chat:read, chat:join)

## Phase 10: ✅ Community
- [x] GET /community/groups
- [x] GET /community/groups/:id/posts (paginated, anonymous support)
- [x] POST /community/posts (with is_anonymous flag)
- [x] POST /community/posts/:id/comments
- [x] PUT /community/posts/:id/like
- [x] Admin moderation (delete posts, audit log)

## Phase 11: ✅ Notifications & Reminders
- [x] POST /notifications/send (admin, target all/mothers/doctors/specific)
- [x] POST /notifications/schedule (future scheduled)
- [x] GET /notifications/history (paginated)
- [x] Background service structure for reminders

## Phase 12: ✅ AI Chatbot
- [x] POST /chatbot/ask (pregnancy-scoped system prompt)
- [x] Language-aware responses (Amharic/Oromo/English)
- [x] Context-aware (gestational week, due date)

## Phase 13: ✅ Admin Panel
- [x] GET /admin/dashboard (analytics with distributions)
- [x] GET /admin/doctors/pending (with credentials)
- [x] PUT /admin/doctors/:id/approve (email notification)
- [x] PUT /admin/doctors/:id/reject (email notification)
- [x] PUT /admin/users/:id/suspend / reactivate
- [x] Full CRUD for content (nutrition, fetal, exercise, sleep, music, health tips)
- [x] Health providers management (CRUD + status toggle)
- [x] Community moderation (delete posts)
- [x] GET /admin/audit-logs (with date/action filters)
- [x] Every admin action logs to audit_logs

## Phase 14: ✅ Risk Indicator Scoring
- [x] calculateRiskIndicator(motherId) service
- [x] getPatientsByRisk(doctorId) service
- [x] Factors: clinical records, symptom severity/frequency, critical symptoms

## Phase 15: ✅ Docker Setup
- [x] Dockerfile (Node 18 Alpine)
- [x] docker-compose.yml (Backend + PostgreSQL 15)
- [x] Health check for PostgreSQL
- [x] Auto-migrate + seed on startup

## Phase 16: ✅ Documentation
- [x] README.md (setup, env vars, API docs, Docker)
- [x] .env.example (all config variables)

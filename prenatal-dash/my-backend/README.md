# MaternaLink — Smart Pregnancy Companion API

Production-ready REST API backend for MaternaLink, a pregnancy health platform connecting mothers with healthcare providers.

## Tech Stack

| Component        | Technology                                  |
|-----------------|---------------------------------------------|
| Runtime         | Node.js 18+                                 |
| Framework       | Express.js                                  |
| Database        | PostgreSQL 15+                              |
| Query Builder   | Knex.js                                     |
| Auth            | Firebase Admin SDK (phone OTP) + JWT        |
| Real-time       | Socket.io                                   |
| Email           | Nodemailer                                  |
| Validation      | express-validator                           |
| Security        | Helmet, CORS, Rate Limiting                 |
| Container       | Docker + docker-compose                     |

## Project Structure

```
/backend
├── server.js                  # Entry point
├── knexfile.js                # Database configuration
├── Dockerfile                 # Docker build
├── docker-compose.yml         # Local dev with PostgreSQL
├── .env.example               # Environment variables template
├── src/
│   ├── app.js                 # Express app setup (middleware, routes)
│   ├── config/
│   │   ├── db.js              # PostgreSQL connection pool
│   │   ├── firebase.js        # Firebase Admin initialization
│   │   ├── socket.js          # Socket.io server
│   │   └── mailer.js          # Nodemailer transport
│   ├── migrations/            # Knex database migrations
│   ├── seeds/                 # Seed data
│   ├── controllers/           # Route handlers
│   ├── routes/                # Express routers
│   ├── middleware/            # Auth, role guards, error handler
│   ├── services/              # Business logic
│   └── utils/                 # Validators, API response helpers
```

## Quick Start

### 1. Prerequisites
- Node.js 18+
- PostgreSQL 15+
- Firebase project (for Auth + FCM)
- SMTP credentials (for email notifications, optional)

### 2. Clone & Install

```bash
git clone <repo-url>
cd backend
npm install
```

### 3. Environment Variables

Copy `.env.example` to `.env` and fill in:

```bash
cp .env.example .env
```

Key variables:
| Variable | Description |
|----------|-------------|
| `PORT` | API server port (default: 5000) |
| `DATABASE_URL` | PostgreSQL connection string |
| `JWT_SECRET` | Secret key for JWT signing |
| `FIREBASE_SERVICE_ACCOUNT_PATH` | Path to Firebase service account JSON |
| `SMTP_HOST` | SMTP server (e.g., smtp.gmail.com) |
| `SMTP_USER` | SMTP email username |
| `SMTP_PASS` | SMTP app password |

### 4. Database Setup

```bash
# Create database
createdb maternalink

# Run migrations
npx knex migrate:latest

# Seed sample data
npm run seed
```

### 5. Start Server

```bash
# Development
npm run dev

# Production
npm start
```

Server starts at `http://localhost:5000`. Health check: `GET /api/v1/health`

## Docker (Recommended for Local Dev)

```bash
docker-compose up --build
```

This starts:
- **PostgreSQL 15** on port 5432
- **Backend API** on port 5000
- Auto-runs migrations + seeds on startup

## API Endpoints

### Authentication
| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/v1/auth/register` | Register mother or doctor |
| POST | `/api/v1/auth/login` | Login (phone + password) |
| POST | `/api/v1/auth/admin/login` | Admin login (email + password) |
| POST | `/api/v1/auth/otp/send` | Send phone OTP |
| POST | `/api/v1/auth/otp/verify` | Verify phone OTP |
| POST | `/api/v1/auth/forgot-password` | Request password reset |
| PUT | `/api/v1/auth/fcm-token` | Update FCM push token |

### Mother Profile & Tracking
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/v1/mothers/:id/profile` | Get mother profile |
| PUT | `/api/v1/mothers/:id/profile` | Update mother profile |
| GET | `/api/v1/mothers/:id/gestational-week` | Auto-calculated week |
| GET | `/api/v1/mothers/:id/health-logs` | Health log history |
| POST | `/api/v1/mothers/:id/health-logs` | Create health log |
| GET | `/api/v1/mothers/:id/emergency-contacts` | Emergency contacts |
| POST | `/api/v1/mothers/:id/emergency-contacts` | Add emergency contact |
| POST | `/api/v1/mothers/:id/emergency-alert` | Trigger emergency alert |
| POST | `/api/v1/mothers/:id/assign-doctor` | Assign a doctor |

### Content (Public)
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/v1/fetal/:week` | Fetal development by week |
| GET | `/api/v1/nutrition?trimester=` | Nutrition guides |
| GET | `/api/v1/exercises?trimester=` | Exercise recommendations |
| GET | `/api/v1/sleep-tips?trimester=` | Sleep tips |
| GET | `/api/v1/music?category=` | Relaxation music |
| GET | `/api/v1/health-tips` | Health & safety tips |
| GET | `/api/v1/health-providers` | Active health providers |
| GET | `/api/v1/health-providers/:id/doctors` | Approved doctors |

### Doctor Self-Service
| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/v1/doctors/register` | Submit doctor profile |
| GET | `/api/v1/doctors/:id/profile` | View own profile |
| PUT | `/api/v1/doctors/:id/profile` | Update profile |
| GET | `/api/v1/doctors/:id/availability-slots` | View slots |
| POST | `/api/v1/doctors/:id/availability-slots` | Create slot |
| PUT | `/api/v1/doctors/:id/availability-slots/:slotId` | Update slot |
| GET | `/api/v1/doctors/:id/appointments` | Filtered appointments |
| GET | `/api/v1/doctors/:id/patients` | Patient list (risk-sorted) |
| POST | `/api/v1/doctors/:id/notify` | Push notification to patients |

### Appointments
| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/v1/appointments` | Book appointment |
| GET | `/api/v1/appointments/:id` | Appointment details |
| PUT | `/api/v1/appointments/:id/status` | Update status |
| PUT | `/api/v1/appointments/:id/respond` | Doctor accepts/rejects |
| POST | `/api/v1/appointments/:id/clinical-record` | Add clinical notes |

### Chat
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/v1/chat/:motherId/:doctorId/messages` | Chat history |
| POST | `/api/v1/chat/:motherId/:doctorId/messages` | Send message |

### Community
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/v1/community/groups` | Community groups |
| GET | `/api/v1/community/groups/:id/posts` | Group posts |
| POST | `/api/v1/community/posts` | Create post |
| POST | `/api/v1/community/posts/:id/comments` | Add comment |
| PUT | `/api/v1/community/posts/:id/like` | Like post |

### Admin
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/v1/admin/dashboard` | Live analytics |
| GET | `/api/v1/admin/users` | List all users |
| PUT | `/api/v1/admin/users/:id/suspend` | Suspend user |
| PUT | `/api/v1/admin/users/:id/reactivate` | Reactivate user |
| GET | `/api/v1/admin/doctors/pending` | Pending doctor registrations |
| PUT | `/api/v1/admin/doctors/:id/approve` | Approve doctor |
| PUT | `/api/v1/admin/doctors/:id/reject` | Reject doctor |
| GET | `/api/v1/admin/health-providers` | List providers |
| POST | `/api/v1/admin/health-providers` | Create provider |
| PUT | `/api/v1/admin/health-providers/:id` | Update provider |
| PUT | `/api/v1/admin/health-providers/:id/status` | Toggle status |
| GET | `/api/v1/admin/audit-logs` | View audit trails |
| DELETE | `/api/v1/admin/community/posts/:id` | Moderate content |

### AI Chatbot
| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/v1/chatbot/ask` | Ask pregnancy-related questions |

## Database Tables

The migration creates 21 tables:

1. **users** — All user accounts (mothers, doctors, admins)
2. **mother_profiles** — Pregnancy-specific mother data
3. **health_providers** — Hospitals and clinics
4. **doctor_profiles** — Doctor credentials and approval
5. **doctor_availability_slots** — Weekly schedule templates
6. **appointments** — Appointment bookings
7. **clinical_records** — Visit notes and prescriptions
8. **chat_messages** — Doctor-mother messaging
9. **nutrition_content** — Trilingual nutrition guides
10. **fetal_tracker_content** — Week-by-week fetal development
11. **exercise_content** — Exercise recommendations
12. **sleep_tips** — Sleep advice by trimester
13. **music_tracks** — Relaxation music library
14. **notifications** — Push notification history
15. **reminders** — Scheduled reminders
16. **emergency_contacts** — User emergency contacts
17. **health_tips** — Health warning signs and first aid
18. **user_health_logs** — Daily symptom/weight tracking
19. **community_groups** — Trimester-based support groups
20. **community_posts** — Forum posts (anonymous support)
21. **community_comments** — Post comments
22. **audit_logs** — Admin action audit trail

## Key Features

### Trilingual Content
All content tables have `_am`, `_or`, `_en` field variants. Endpoints return all three variants, and localization happens client-side.

### Risk Indicator Scoring
The `riskIndicatorService.js` computes patient risk based on:
- Latest clinical record assessment
- Symptom severity from health logs (last 30 days)
- Symptom frequency
- Critical symptom detection (bleeding, severe pain, high BP, etc.)

### Audit Logging
Every admin mutating action writes to `audit_logs` with: who performed it, what action, target table/ID, and details JSON.

### Real-time Updates (Socket.io)
- **Chat rooms**: per mother-doctor pair
- **Appointment updates**: real-time status change notifications
- **Emergency alerts**: GPS location shared with doctor
- **Notification delivery**: push to specific user rooms

### Security
- Helmet for HTTP headers
- CORS with configured origins
- Rate limiting (100 req/15 min on /api/)
- Parameterized SQL queries (no SQL injection)
- JWT with expiration
- Firebase phone auth for mothers
- Role-based access control

## Running Tests

```bash
# All tests
npm test

# Watch mode
npm run test:watch

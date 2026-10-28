# 🚀 MaternaLink Backend — cPanel Deployment Guide

This guide provides step-by-step instructions to deploy the MaternaLink Node.js backend on any standard cPanel hosting environment using **"Setup Node.js App" (Phusion Passenger)** and **PostgreSQL**.

---

## 📋 Pre-Deployment Checklist

Before deploying, ensure you have:
- [x] Access to your **cPanel account**.
- [x] A domain or subdomain configured (e.g., `api.yourdomain.com` or `backend.yourdomain.com`).
- [x] cPanel feature **"Setup Node.js App"** enabled by your hosting provider.
- [x] Access to **PostgreSQL Databases** or **phpPgAdmin** in cPanel (or an external hosted PostgreSQL database like Neon/Supabase/RDS).

---

## Step 1: Create PostgreSQL Database & User in cPanel

1. Log into your **cPanel**.
2. Navigate to **PostgreSQL Databases** (under the *Databases* section).
3. **Create Database**:
   - Database name: e.g., `maternalink` (cPanel will prefix this, e.g. `username_maternalink`).
4. **Create Database User**:
   - Username: e.g., `dbuser` (cPanel will prefix this, e.g. `username_dbuser`).
   - Password: Generate a strong, secure password and save it securely.
5. **Add User to Database**:
   - Assign `username_dbuser` to `username_maternalink` and grant **ALL PRIVILEGES**.

> **Note**: For local cPanel PostgreSQL, the host is usually `localhost` or `127.0.0.1`, port is `5432`, and SSL is NOT required (`DB_SSL=false`).

---

## Step 2: Prepare Backend Files for Upload

1. Open your backend folder: `c:\flutter_project\momcare\prenatal-dash\my-backend`.
2. **DO NOT** include the following in your zip archive:
   - ❌ `node_modules/` (cPanel will install fresh Linux-compatible binaries)
   - ❌ Local test `.env` file (you will configure variables directly in cPanel)
   - ❌ Large test files inside `uploads/` (keep the `uploads/` folder and `uploads/.gitkeep`)
3. Select the rest of the backend files and folders:
   - `src/`
   - `model/`
   - `secrets/` (or your Firebase service account JSON)
   - `uploads/` (with `.gitkeep`)
   - `package.json`
   - `package-lock.json`
   - `knexfile.js`
   - `server.js`
   - `app.js`
4. Compress them into a single archive: `backend.zip`.

---

## Step 3: Upload Files via File Manager

1. In cPanel, open **File Manager**.
2. Navigate to your desired application directory:
   - For example: `/home/username/backend` (Recommended: keep backend files outside `public_html` for security).
   - Or `/home/username/api.yourdomain.com`.
3. Click **Upload** and upload `backend.zip`.
4. Right-click `backend.zip` and select **Extract**.
5. Ensure the extracted files sit directly in the folder (e.g., `/home/username/backend/app.js` and `package.json` exist).
6. Verify permissions on `uploads/`:
   - Right-click `uploads/` -> **Change Permissions** -> set to `755` (Read, Write, Execute for User; Read & Execute for Group/World).

---

## Step 4: Configure the Node.js Application in cPanel

1. In cPanel, search for and open **Setup Node.js App** (under *Software*).
2. Click **Create Application**.
3. Fill in the fields:
   - **Node.js version**: Choose **Node 18.x** or **Node 20.x LTS**.
   - **Application mode**: `Production`.
   - **Application root**: `backend` (or the folder path where you extracted the files, relative to `/home/username/`).
   - **Application URL**: Select your subdomain (e.g. `api.yourdomain.com`).
   - **Application startup file**: `app.js` (or `server.js` — MaternaLink supports both seamlessly).
4. Click **Create**.
5. Once created, click the **Stop Application** button temporarily while you add environment variables.

---

## Step 5: Configure Environment Variables

In the **Setup Node.js App** page, scroll down to the **Environment variables** section and click **Add Variable** for each of the following:

| Variable Name | Example Production Value | Description |
| :--- | :--- | :--- |
| `NODE_ENV` | `production` | Enables production optimizations & logging |
| `PORT` | `5000` | Internal port (Passenger handles proxying) |
| `JWT_SECRET` | *(64-char random secure string)* | Secret key for signing tokens |
| `JWT_EXPIRES_IN` | `30d` | JWT session lifetime |
| `DB_HOST` | `localhost` | Database host (or external host if remote) |
| `DB_PORT` | `5432` | PostgreSQL port |
| `DB_NAME` | `username_maternalink` | Your cPanel database name |
| `DB_USER` | `username_dbuser` | Your cPanel database user |
| `DB_PASSWORD` | `your_actual_db_password` | Your database password |
| `DB_SSL` | `false` | Keep `false` for cPanel DB (`true` for cloud DBs) |
| `ALLOWED_ORIGINS` | `https://yourdomain.com,https://admin.yourdomain.com` | Allowed frontend origins (CORS) |
| `FIREBASE_SERVICE_ACCOUNT_PATH` | `./secrets/firebase-key.json` | Path to Firebase credentials |
| `FIREBASE_API_KEY` | `your-firebase-api-key` | Firebase public API key |
| `FIREBASE_PROJECT_ID` | `your-firebase-project-id` | Firebase project identifier |
| `SMTP_HOST` | `mail.yourdomain.com` | Mail server hostname |
| `SMTP_PORT` | `465` | SSL mail port (or `587` for TLS) |
| `SMTP_USER` | `contact@yourdomain.com` | SMTP username |
| `SMTP_PASS` | `your_email_password` | SMTP password |
| `EMAIL_FROM` | `noreply@yourdomain.com` | Sender email address |
| `AFROMESSAGE_API_KEY` | *(your AfroMessage API Key)* | SMS OTP service key |
| `AFROMESSAGE_SENDER_ID` | *(your AfroMessage Sender ID)* | SMS Sender identifier |

*Alternatively, you can create a `.env` file directly inside the application root directory using File Manager.*

---

## Step 6: Install Dependencies & Run Database Migrations

1. At the top of your Node.js application page in cPanel, copy the command shown under:
   > *"Enter to the virtual environment. To enter to a virtual environment, run the command:"*
   > Example: `source /home/username/nodevenv/backend/20/bin/activate && cd /home/username/backend`
2. Open **Terminal** in cPanel (or connect via SSH).
3. Paste that command and press **Enter**.
4. Run:
   ```bash
   npm install --production
   ```
5. Once installation finishes, run the database migrations:
   ```bash
   npm run migrate
   ```
   *(Optional)* To seed initial CMS data:
   ```bash
   npm run seed:cms
   ```

---

## Step 7: Start & Verify the Application

1. Return to **Setup Node.js App** in cPanel.
2. Click **Start Application** (or **Restart**).
3. Test the deployment by opening the Health Check endpoint in your web browser:
   ```text
   https://api.yourdomain.com/api/v1/health
   ```
4. Expected Response:
   ```json
   {
     "success": true,
     "status": "OK",
     "server": "MaternaLink API",
     "version": "1.0.0",
     "database": {
       "status": "connected"
     },
     "environment": "production"
   }
   ```

---

## 🛠️ Troubleshooting & Tips

### 1. 503 Service Unavailable / Passenger Error
- Open cPanel **File Manager** -> Navigate to your backend directory -> check `stderr.log`.
- Common causes:
  - Wrong database password in environment variables.
  - Missing dependencies: run `npm install --production` in the virtualenv.

### 2. Database Connection Error ("ECONNREFUSED" or "no pg_hba.conf entry")
- Ensure `DB_HOST` is `localhost` or `127.0.0.1`.
- If using cPanel's local PostgreSQL, verify that `DB_SSL=false`.
- Ensure your database user is added to the database with `ALL PRIVILEGES`.

### 3. Rate Limiter (429 Too Many Requests)
- `app.set('trust proxy', 1)` is already configured in `src/app.js`, ensuring requests proxied through Phusion Passenger correctly evaluate client IP addresses.

### 4. How to Restart the Backend after Updates
- In cPanel **Setup Node.js App**, click the **Restart** button.
- Alternatively, via SSH or File Manager, create/update `tmp/restart.txt`:
  ```bash
  mkdir -p tmp && touch tmp/restart.txt
  ```

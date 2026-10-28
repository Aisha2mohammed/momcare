const admin = require('firebase-admin');
const path = require('path');
const fs = require('fs');

let firebaseApp = null;

const initFirebase = () => {
    if (firebaseApp) return firebaseApp;

    let serviceAccountPath = process.env.FIREBASE_SERVICE_ACCOUNT_PATH
        ? path.resolve(process.env.FIREBASE_SERVICE_ACCOUNT_PATH)
        : null;

    if (!serviceAccountPath || !fs.existsSync(serviceAccountPath)) {
        const fallbackSecrets = path.resolve(__dirname, '../../secrets/firebase-key.json');
        const fallbackRoot = path.resolve(__dirname, '../../firebase-service-account.json');
        if (fs.existsSync(fallbackSecrets)) {
            serviceAccountPath = fallbackSecrets;
        } else if (fs.existsSync(fallbackRoot)) {
            serviceAccountPath = fallbackRoot;
        }
    }

    if (!serviceAccountPath || !fs.existsSync(serviceAccountPath)) {
        console.warn('⚠️  Firebase service account file not found. Push notifications will be disabled.');
        return null;
    }

    try {
        const serviceAccount = require(serviceAccountPath);
        firebaseApp = admin.initializeApp({
            credential: admin.credential.cert(serviceAccount),
        });
        console.log('🔥 Firebase Admin initialized successfully');
        return firebaseApp;
    } catch (err) {
        console.error('❌ Failed to initialize Firebase:', err.message);
        return null;
    }
};

module.exports = { initFirebase, admin };

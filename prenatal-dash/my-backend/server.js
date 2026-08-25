require('dotenv').config();
const http = require('http');
const app = require('./src/app');
const { testConnection } = require('./src/config/db');
const { initFirebase } = require('./src/config/firebase');
const { initSocket } = require('./src/config/socket');
const { initMailer } = require('./src/config/mailer');

const PORT = process.env.PORT || 5000;

async function startServer() {
  // Test database connection
  const dbConnected = await testConnection();
  if (!dbConnected) {
    console.error('❌ Could not connect to PostgreSQL. Exiting.');
    process.exit(1);
  }

  // Initialize Firebase Admin
  initFirebase();

  // Initialize Mailer (nodemailer)
  initMailer();

  // Create HTTP server
  const httpServer = http.createServer(app);

  // Initialize Socket.io
  initSocket(httpServer);

  // Start listening
  httpServer.listen(PORT, () => {
    console.log('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    console.log('  🚀 MaternaLink API Server');
    console.log('  📡 Port: ' + PORT);
    console.log('  🌐 Environment: ' + (process.env.NODE_ENV || 'development'));
    console.log('  🔌 Health: http://localhost:' + PORT + '/api/v1/health');
    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
  });
}

startServer().catch((err) => {
  console.error('❌ Failed to start server:', err.message);
  process.exit(1);
});

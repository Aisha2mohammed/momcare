/**
 * cPanel Phusion Passenger Startup File
 *
 * cPanel's "Setup Node.js App" tool defaults to `app.js` as the Application Startup File.
 * This file delegates to `server.js` so that the application starts cleanly whether
 * configured as `app.js` or `server.js` in cPanel.
 */

module.exports = require('./server');

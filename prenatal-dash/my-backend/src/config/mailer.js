const nodemailer = require('nodemailer');

let transporter = null;

const initMailer = () => {
  if (transporter) return transporter;

  if (!process.env.SMTP_HOST) {
    console.warn('⚠️  SMTP not configured. Email notifications disabled.');
    return null;
  }

  transporter = nodemailer.createTransport({
    host: process.env.SMTP_HOST,
    port: parseInt(process.env.SMTP_PORT, 10) || 587,
    secure: process.env.SMTP_PORT === '465',
    auth: {
      user: process.env.SMTP_USER,
      pass: process.env.SMTP_PASS,
    },
  });

  return transporter;
};

/**
 * Send an email
 */
const sendEmail = async ({ to, subject, html }) => {
  if (!transporter) {
    console.warn('⚠️  Mailer not initialized. Skipping email.');
    return { success: false, reason: 'Mailer not initialized' };
  }

  try {
    const info = await transporter.sendMail({
      from: process.env.EMAIL_FROM || 'noreply@maternalink.com',
      to,
      subject,
      html,
    });
    console.log(`📧 Email sent to ${to}: ${info.messageId}`);
    return { success: true, messageId: info.messageId };
  } catch (err) {
    console.error('❌ Email send error:', err.message);
    return { success: false, reason: err.message };
  }
};

module.exports = { initMailer, sendEmail };

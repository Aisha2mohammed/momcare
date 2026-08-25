const { Server } = require('socket.io');
const jwt = require('jsonwebtoken');

let io = null;

/**
 * Initialize Socket.io server with authentication
 */
const initSocket = (httpServer) => {
  io = new Server(httpServer, {
    cors: {
      origin: process.env.ALLOWED_ORIGINS ? process.env.ALLOWED_ORIGINS.split(',') : '*',
      methods: ['GET', 'POST'],
      credentials: true,
    },
  });

  // Authentication middleware
  io.use((socket, next) => {
    const token = socket.handshake.auth?.token || socket.handshake.query?.token;
    if (!token) {
      return next(new Error('Authentication required'));
    }
    try {
      const decoded = jwt.verify(token, process.env.JWT_SECRET);
      socket.userId = decoded.id;
      socket.userRole = decoded.role || 'mother';
      next();
    } catch (err) {
      return next(new Error('Invalid token'));
    }
  });

  io.on('connection', (socket) => {
    console.log(`🔌 Socket connected: ${socket.userId} (${socket.userRole})`);

    // Join personal room for notifications/appointment updates
    socket.join(`user:${socket.userId}`);

    // Join doctor-mother chat room
    socket.on('chat:join', (data) => {
      const { motherId, doctorId } = data;
      const roomId = `chat:${motherId}:${doctorId}`;
      socket.join(roomId);
      console.log(`Socket ${socket.userId} joined room ${roomId}`);
    });

    // Handle chat message
    socket.on('chat:message', (data) => {
      const { motherId, doctorId, message } = data;
      const roomId = `chat:${motherId}:${doctorId}`;
      io.to(roomId).emit('chat:message', message);
    });

    // Handle read receipts
    socket.on('chat:read', (data) => {
      const { motherId, doctorId } = data;
      const roomId = `chat:${motherId}:${doctorId}`;
      io.to(roomId).emit('chat:read', { motherId, doctorId, readBy: socket.userId });
    });

    // Appointment status updates
    socket.on('appointment:update', (data) => {
      const { appointmentId, status, motherId, doctorId } = data;
      // Notify both parties
      if (motherId) io.to(`user:${motherId}`).emit('appointment:updated', { appointmentId, status });
      if (doctorId) io.to(`user:${doctorId}`).emit('appointment:updated', { appointmentId, status });
    });

    // Notification events
    socket.on('notification:send', (data) => {
      const { targetUserId } = data;
      if (targetUserId) {
        io.to(`user:${targetUserId}`).emit('notification:new', data);
      }
    });

    socket.on('disconnect', () => {
      console.log(`🔌 Socket disconnected: ${socket.userId}`);
    });
  });

  return io;
};

/**
 * Get Socket.io instance
 */
const getIO = () => {
  if (!io) throw new Error('Socket.io not initialized');
  return io;
};

/**
 * Emit event to specific user room
 */
const emitToUser = (userId, event, data) => {
  if (io) {
    io.to(`user:${userId}`).emit(event, data);
  }
};

/**
 * Emit event to chat room
 */
const emitToChat = (motherId, doctorId, event, data) => {
  if (io) {
    io.to(`chat:${motherId}:${doctorId}`).emit(event, data);
  }
};

module.exports = { initSocket, getIO, emitToUser, emitToChat };

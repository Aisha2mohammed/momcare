FROM node:18-alpine

WORKDIR /app

# Install dependencies
COPY package*.json ./
RUN npm ci --only=production

# Copy source
COPY . .

# Expose port
EXPOSE 5000

# Start server
CMD ["node", "server.js"]

# Build the React client
FROM node:18-alpine AS client-build
WORKDIR /app/client

# Copy client package files
COPY client/package*.json ./
RUN npm install

# Copy client source and build
COPY client/ ./
RUN npm run build

# Build the server
FROM node:18-alpine AS server-build
WORKDIR /app/server

# Copy server package files
COPY server/package*.json ./
RUN npm install --production

# Copy server source
COPY server/ ./

# Final stage
FROM node:18-alpine
WORKDIR /app

# Copy built client
COPY --from=client-build /app/client/build ./client/build

# Copy server with dependencies
COPY --from=server-build /app/server ./server

# Expose port
EXPOSE 4000

# Set working directory to server
WORKDIR /app/server

# Start the Express server
CMD ["node", "server.js"]

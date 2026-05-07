# Use a slim, stable Node.js base image
FROM node:20-alpine

# STAGE 1: Security Patch
# This updates the internal NPM packages to remove 
# vulnerabilities like brace-expansion and cross-spawn.
RUN npm install -g npm@latest

# STAGE 2: Application Setup
WORKDIR /app

# Copy dependency files first (optimizes Docker layer caching)
COPY package*.json ./

# Install only production dependencies and clean cache to save space
RUN npm install --omit=dev && npm cache clean --force

# Copy the rest of your application code
COPY . .

# STAGE 3: Runtime Configuration
# The app runs on port 3000
EXPOSE 3000

# Start the application
CMD ["node", "index.js"]
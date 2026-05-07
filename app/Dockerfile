# 1. Start with a stable, lightweight base
FROM node:20-alpine

# 2. Patch system-level vulnerabilities found in internal NPM tools
# This is what cleared your Trivy scan errors!
RUN npm install -g npm@latest

# 3. Set the working directory inside the container
WORKDIR /app

# 4. Copy dependency manifests first to leverage Docker layer caching
COPY package*.json ./

# 5. Install only production dependencies and purge the cache
# Use --omit=dev to keep the image slim and secure
RUN npm install --omit=dev && npm cache clean --force

# 6. Copy the rest of the application source code
COPY . .

# 7. Inform Docker the app listens on port 3000
EXPOSE 3000

# 8. Start the application
CMD ["node", "index.js"]
FROM node:20-alpine

# Add this line right after FROM to patch the internal NPM vulnerabilities
RUN npm install -g npm@latest

WORKDIR /app
COPY package*.json ./
RUN npm install --omit=dev
COPY . .
CMD ["node", "index.js"]
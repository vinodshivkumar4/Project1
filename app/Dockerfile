FROM node:20-alpine
RUN npm install -g npm@latest
WORKDIR /app
COPY package*.json ./
RUN npm install --omit=dev && npm cache clean --force
COPY . .
EXPOSE 3000
CMD ["node", "server.js"]
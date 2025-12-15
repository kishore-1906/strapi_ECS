FROM node:18-alpine

WORKDIR /app

# Copy dependency files first (better caching)
COPY strapi-app/package.json strapi-app/package-lock.json ./

# Install dependencies
RUN npm install

# Copy full Strapi app
COPY strapi-app/ .

# Build admin panel
RUN npm run build

EXPOSE 1337

CMD ["npm", "run", "start"]


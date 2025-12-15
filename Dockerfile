FROM node:18-bullseye

WORKDIR /app

# Copy dependency files
COPY strapi-app/package.json strapi-app/package-lock.json ./

# Install dependencies
RUN npm install

# Copy full Strapi app
COPY strapi-app/ .

# Build admin
RUN npm run build

EXPOSE 1337

CMD ["npm", "run", "start"]


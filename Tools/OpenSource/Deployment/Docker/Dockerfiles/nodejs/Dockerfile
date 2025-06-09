# Build stage
FROM node:20-alpine AS build

WORKDIR /app

COPY package*.json ./
RUN npm install --production

COPY . .

RUN npm run build  # if written in typescript

# Runtime stage
FROM node:20-alpine

WORKDIR /app

COPY --from=build /app ./

EXPOSE 3000

CMD ["node", "src/index.js"]

# or CMD ["npm", "start"]

# Stage 1: Build stage with Node 18
FROM node:18-alpine AS build

WORKDIR /usr/src/app
COPY package*.json ./
RUN npm install --production
COPY . .
RUN npm run build

FROM nginx

COPY --from=build /usr/src/app/dist /usr/share/nginx/html
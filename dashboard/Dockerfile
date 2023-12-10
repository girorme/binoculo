FROM node:12

WORKDIR /usr/src/app

COPY package*.json ./
RUN yarn install
COPY . .

EXPOSE 1234

ENTRYPOINT [ "npm", "run", "start" ]
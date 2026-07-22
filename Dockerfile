FROM node:18-alpine

# Create app directory
WORKDIR /usr/src/app

# Install app dependencies
COPY app/package*.json ./
RUN npm install --production

# Bundle app source
COPY app/ .

EXPOSE 8080
CMD [ "npm", "start" ]

FROM node:8.1-alpine

WORKDIR /home/node
COPY package.json ./
RUN npm install
COPY generate-static-docs ./

COPY src ./src/
COPY templates ./templates/
ENTRYPOINT [ "/bin/sh", "/home/node/generate-static-docs" ]
EXPOSE 3000

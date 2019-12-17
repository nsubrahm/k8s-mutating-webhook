FROM node:current-alpine

RUN mkdir -p /etc/certs

RUN mkdir -p /project/app
COPY app /project/app
COPY package.json /project 

WORKDIR /project
RUN npm i

EXPOSE 4443

USER node
CMD ["npm", "start"]
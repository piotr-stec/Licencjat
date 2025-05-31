FROM node:23.5.0

WORKDIR /app

COPY ./indexer/package.json ./

RUN npm install

COPY ./indexer .

RUN npm run build

CMD ["npm", "start"]

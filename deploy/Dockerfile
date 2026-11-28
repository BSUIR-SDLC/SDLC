FROM node:24-alpine
WORKDIR /app
COPY package.json ./
COPY packages ./packages
COPY apps ./apps
COPY db ./db
EXPOSE 3000
CMD ["node", "apps/api/src/server.ts"]

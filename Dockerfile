# Install dependencies only when needed
FROM node:14-alpine AS deps
# Check https://github.com/nodejs/docker-node/tree/b4117f9333da4138b03a546ec926ef50a31506c3#node14-alpine to understand why libc6-compat might be needed.
RUN apk add --no-cache libc6-compat
WORKDIR /app
COPY package.json ./
COPY yarn.lock ./
RUN yarn

# Rebuild the source code only when needed
FROM node:14-alpine AS builder
WORKDIR /app
COPY package.json ./
COPY tsconfig.json ./
COPY ./src/ ./src/
COPY ./public ./public/
COPY --from=deps /app/node_modules ./node_modules
RUN yarn build

# Production image, copy all the files and run next
FROM node:14-alpine AS runner
WORKDIR /app
COPY pm2.json ./
COPY *.env ./
RUN touch .env
RUN export $(cat .env)
RUN yarn global add pm2

ENV NODE_ENV production
ENV PORT 3000

# You only need to copy next.config.js if you are NOT using the default configuration
# COPY --from=builder /app/next.config.js ./
# COPY --from=builder /app/public ./public
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/package.json ./package.json
COPY --from=builder /app/tsconfig.json ./tsconfig.json


EXPOSE 3000

CMD [ "pm2-runtime", "start", "pm2.json" ]
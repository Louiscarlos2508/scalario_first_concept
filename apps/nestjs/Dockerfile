# syntax=docker/dockerfile:1.7
# --- Build stage ---
FROM node:20-alpine AS builder
WORKDIR /app

RUN apk add --no-cache curl \
 && corepack enable \
 && corepack prepare pnpm@9.12.0 --activate

COPY package.json pnpm-lock.yaml* ./
RUN pnpm install --frozen-lockfile || pnpm install

COPY tsconfig*.json nest-cli.json ./
COPY src ./src
RUN pnpm run build

# --- Runtime stage ---
FROM node:20-alpine AS runtime
WORKDIR /app
ENV NODE_ENV=production

RUN apk add --no-cache curl \
 && corepack enable \
 && corepack prepare pnpm@9.12.0 --activate

COPY package.json pnpm-lock.yaml* ./
RUN pnpm install --prod --frozen-lockfile || pnpm install --prod

COPY --from=builder /app/dist ./dist

EXPOSE 3000
HEALTHCHECK --interval=10s --timeout=5s --retries=5 \
  CMD curl -f http://localhost:3000/health || exit 1

CMD ["node", "dist/main.js"]

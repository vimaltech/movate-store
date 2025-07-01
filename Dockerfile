# ── Stage 1: Install dependencies ────────────────────────────
FROM node:20-alpine AS deps

WORKDIR /app

# Copy only package files first for cache optimization
COPY package.json yarn.lock ./

# Install production & build dependencies
RUN yarn install --frozen-lockfile


# ── Stage 2: Build application ───────────────────────────────
FROM node:20-alpine AS builder

WORKDIR /app

COPY --from=deps /app/node_modules ./node_modules
COPY . .

# Optional: if you use TypeScript
# RUN yarn build

# If you have Admin UI included in the same repo, build it
RUN yarn build


# ── Stage 3: Runtime container ───────────────────────────────
FROM node:20-alpine

WORKDIR /app

# Only keep built files
ENV NODE_ENV=production

COPY --from=builder /app .

EXPOSE 9000

# Run database migrations and start server
CMD ["sh", "-c", "medusa migrations run && yarn start"]

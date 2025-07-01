# ---------- Build stage -------------------------------------------------
FROM node:20-alpine AS build
WORKDIR /app

# Enable Corepack and activate Yarn 4.9.1
RUN corepack enable \
 && corepack prepare yarn@4.9.1 --activate

# Copy manifests and install dependencies into node_modules
COPY package.json yarn.lock ./
RUN yarn config set -H nodeLinker node-modules \
 && yarn install --immutable

# Copy source and build (compiles TS + Admin UI)
COPY . .

# ── NEW: declare the build‑time argument
ARG NEXT_PUBLIC_MEDUSA_PUBLISHABLE_KEY

# ── NEW: expose it to the build as an environment variable
ENV NEXT_PUBLIC_MEDUSA_PUBLISHABLE_KEY=${NEXT_PUBLIC_MEDUSA_PUBLISHABLE_KEY}

RUN yarn build        # adjust if your script name differs

# ---------- Runtime stage ----------------------------------------------
FROM node:20-alpine
WORKDIR /app

RUN corepack enable \
 && corepack prepare yarn@4.9.1 --activate

ENV NODE_ENV=production

# Bring in compiled app and its node_modules
COPY --from=build /app ./

EXPOSE 9000
CMD ["sh","-c","medusa migrations run && yarn start"]

############################################
# Stage 1 — install dependencies (Yarn 4)  #
############################################
FROM node:20-alpine AS deps

# Enable Corepack and activate the Yarn version requested by package.json
RUN corepack enable \
 && corepack prepare yarn@4.9.1 --activate

WORKDIR /app

# Copy only manifest files first to maximise Docker’s layer cache
COPY package.json yarn.lock ./

# Yarn 4 strict install (fails if lockfile is out of sync)
RUN yarn install --immutable


############################################
# Stage 2 — build application              #
############################################
FROM node:20-alpine AS builder

RUN corepack enable \
 && corepack prepare yarn@4.9.1 --activate

WORKDIR /app

# Re‑use deps from previous stage
COPY --from=deps /app/node_modules ./node_modules
COPY . .

# If you use TypeScript or include the Admin UI in the same repo,
# this will compile everything into dist/ or .next/ (as configured)
RUN yarn build


############################################
# Stage 3 — runtime container              #
############################################
FROM node:20-alpine

RUN corepack enable \
 && corepack prepare yarn@4.9.1 --activate

WORKDIR /app
ENV NODE_ENV=production

# Copy compiled app + node_modules only
COPY --from=builder /app ./

# Medusa backend listens on 9000
EXPOSE 9000

# Run DB migrations each time the container starts, then launch server
CMD ["sh","-c","medusa migrations run && yarn start"]

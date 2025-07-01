############################################
# Stage 1 – deps                           #
############################################
FROM node:20-alpine AS deps

WORKDIR /app

# Enable Corepack + Yarn 4.9.1
RUN corepack enable \
 && corepack prepare yarn@4.9.1 --activate

# Copy manifest files first
COPY package.json yarn.lock ./

# Force Yarn to use node_modules and install
RUN yarn config set -H nodeLinker node-modules \
 && yarn install --immutable


############################################
# Stage 2 – build                          #
############################################
FROM node:20-alpine AS builder

WORKDIR /app

RUN corepack enable \
 && corepack prepare yarn@4.9.1 --activate

# Bring in entire project (includes node_modules from deps)
COPY --from=deps /app ./
COPY . .

RUN yarn build


############################################
# Stage 3 – runtime                        #
############################################
FROM node:20-alpine

WORKDIR /app

RUN corepack enable \
 && corepack prepare yarn@4.9.1 --activate

ENV NODE_ENV=production

COPY --from=builder /app ./

EXPOSE 9000
CMD ["sh","-c","medusa migrations run && yarn start"]

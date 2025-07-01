############################################
# Stage 1 – deps                           #
############################################
FROM node:20-alpine AS deps

# Enable Corepack and Yarn 4.9.1
RUN corepack enable \
 && corepack prepare yarn@4.9.1 --activate

WORKDIR /app

COPY package.json yarn.lock ./

# 👇 Force Yarn to use the node‑modules linker, then install
RUN yarn config set nodeLinker node-modules \
 && yarn install --immutable


############################################
# Stage 2 – build                          #
############################################
FROM node:20-alpine AS builder

RUN corepack enable \
 && corepack prepare yarn@4.9.1 --activate \
 && yarn config set nodeLinker node-modules  # ensure same linker

WORKDIR /app

COPY --from=deps /app/node_modules ./node_modules
COPY . .

RUN yarn build


############################################
# Stage 3 – runtime                        #
############################################
FROM node:20-alpine

RUN corepack enable \
 && corepack prepare yarn@4.9.1 --activate \
 && yarn config set nodeLinker node-modules

WORKDIR /app
ENV NODE_ENV=production

COPY --from=builder /app ./

EXPOSE 9000
CMD ["sh","-c","medusa migrations run && yarn start"]

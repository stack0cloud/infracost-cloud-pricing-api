FROM node:20-alpine AS build

# Install pnpm
RUN corepack enable && corepack prepare pnpm@latest --activate

WORKDIR /usr/src/app
COPY package.json pnpm-lock.yaml ./
RUN pnpm install --prod --frozen-lockfile \
  && cp -R node_modules prod_node_modules \
  && pnpm install --frozen-lockfile
COPY . .
RUN pnpm run build

FROM node:20-alpine AS release

# Install pnpm and remove npm (reduces image size and eliminates npm vulnerabilities)
RUN corepack enable && corepack prepare pnpm@latest --activate \
  && npm uninstall -g npm

RUN apk add --no-cache bash curl postgresql-client

WORKDIR /usr/src/app
RUN mkdir -p data/products

RUN addgroup -g 1001 -S infracost && \
  adduser -u 1001 -S infracost -G infracost && \
  chown -R infracost:infracost /usr/src/app
USER 1001

COPY --from=build /usr/src/app/prod_node_modules ./node_modules
COPY --from=build /usr/src/app/dist ./dist
COPY package*.json ./
ENV NODE_ENV=production
EXPOSE 4000
CMD [ "node", "dist/server.js" ]

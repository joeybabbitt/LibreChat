# v0.8.3-rc1 + custom Railway config
FROM node:20-alpine AS node

# 1. Performance & MCP Tools
RUN apk add --no-cache jemalloc python3 py3-pip
ENV LD_PRELOAD=/usr/lib/libjemalloc.so.2
COPY --from=ghcr.io/astral-sh/uv:0.9.5-python3.12-alpine /usr/local/bin/uv /usr/local/bin/uvx /bin/
RUN uv --version

ARG NODE_MAX_OLD_SPACE_SIZE=6144

# 2. Create /app as root, then hand it to node
USER root
RUN mkdir -p /app && chown node:node /app
WORKDIR /app

# 3. Create Persistent Folder Structure
RUN mkdir -p /app/data/images \
             /app/data/uploads \
             /app/client/public \
             /app/logs

# 4. Symlinks for Railway volume
RUN ln -s /app/data/images /app/client/public/images && \
    ln -s /app/data/uploads /app/uploads

# 5. Fix violations.json crash + chown ALL of /app
RUN touch /app/data/violations.json && \
    chmod 777 /app/data/violations.json && \
    chown -R node:node /app

USER node

# 6. Install dependencies
COPY --chown=node:node package.json package-lock.json ./
COPY --chown=node:node api/package.json ./api/package.json
COPY --chown=node:node client/package.json ./client/package.json
COPY --chown=node:node packages/data-provider/package.json ./packages/data-provider/package.json
COPY --chown=node:node packages/data-schemas/package.json ./packages/data-schemas/package.json
COPY --chown=node:node packages/api/package.json ./packages/api/package.json

RUN \
    touch .env ; \
    mkdir -p /app/client/public/images /app/logs /app/uploads ; \
    npm config set fetch-retry-maxtimeout 600000 ; \
    npm config set fetch-retries 5 ; \
    npm config set fetch-retry-mintimeout 15000 ; \
    npm ci --no-audit

COPY --chown=node:node . .

RUN \
    NODE_OPTIONS="--max-old-space-size=${NODE_MAX_OLD_SPACE_SIZE}" npm run frontend; \
    npm prune --production; \
    npm cache clean --force

# 7. Apply your config
COPY --chown=node:node librechat_production.yaml ./librechat.yaml

EXPOSE 3080
ENV HOST=0.0.0.0

# 8. Migrations + start
CMD ["sh", "-c", "chown -R node:node /app/data && npm run migrate:agent-permissions && npm run migrate:prompt-permissions && npm run backend"]

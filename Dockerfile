# v0.8.2-rc3 (Customized for JB)
# Base node image
# JB Gemini Edited
FROM node:20-alpine AS node

# 1. Keep your performance optimizations (jemalloc)
RUN apk add --no-cache jemalloc python3 py3-pip
ENV LD_PRELOAD=/usr/lib/libjemalloc.so.2

# 2. Keep your 'uv' installation for MCP
COPY --from=ghcr.io/astral-sh/uv:0.9.5-python3.12-alpine /usr/local/bin/uv /usr/local/bin/uvx /bin/

# 3. Set your custom memory limit
ARG NODE_MAX_OLD_SPACE_SIZE=6144

RUN mkdir -p /app && chown node:node /app
WORKDIR /app

USER node

# 4. Copy package files (Newest structure)
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
    npm ci --no-audit

COPY --chown=node:node . .

# 5. Build frontend with your memory limit
RUN \
    NODE_OPTIONS="--max-old-space-size=${NODE_MAX_OLD_SPACE_SIZE}" npm run frontend; \
    npm prune --production; \
    npm cache clean --force

# 6. Apply your specific config file
# Note: Ensure 'librechat_production.yaml' exists in your root folder
COPY librechat_production.yaml ./librechat.yaml

EXPOSE 3080
ENV HOST=0.0.0.0
# CMD ["npm", "run", "backend"]
# temp change
CMD ["sh", "-c", "npm run migrate && npm run backend"]

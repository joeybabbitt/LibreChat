# Base image with latest LibreChat features
FROM ghcr.io/danny-avila/librechat-dev:latest

# 1. Performance & MCP Tools
USER root
RUN apk add --no-cache jemalloc python3 py3-pip
ENV LD_PRELOAD=/usr/lib/libjemalloc.so.2
COPY --from=ghcr.io/astral-sh/uv:0.9.5-python3.12-alpine /usr/local/bin/uv /usr/local/bin/uvx /bin/

# 2. Set the working directory
WORKDIR /app

# 3. Create Persistent Folder Structure
# This MUST happen before symlinking to avoid the "No such file" error
RUN mkdir -p /app/data/images \
             /app/data/uploads \
             /app/client/public \
             /app/logs

# 4. Create the Symlinks
# Links your permanent Volume (/app/data) to the app folders
RUN ln -s /app/data/images /app/client/public/images && \
    ln -s /app/data/uploads /app/uploads

# 5. Set Permissions & Fix violations.json Crash
# We create the file as root and give it full permissions before switching users
RUN touch /app/data/violations.json && \
    chmod 777 /app/data/violations.json && \
    chown -R node:node /app/data /app/client/public/images /app/uploads

ENV NODE_OPTIONS="--max-old-space-size=2048"

# Switch to non-root user for security
USER node

# 6. Apply your specific config file
COPY --chown=node:node librechat_production.yaml ./librechat.yaml

# 7. Run Migrations & Start Backend
# This finally unlocks your Marketplace, Agents, and Prompts
CMD ["sh", "-c", "npm run migrate:agent-permissions && npm run migrate:prompt-permissions && npm run backend"]

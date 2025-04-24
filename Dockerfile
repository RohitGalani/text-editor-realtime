# Stage 1: Build UI assets
FROM node:18-alpine AS adminbuild

RUN npm install -g pnpm@latest
WORKDIR /opt/etherpad-lite
COPY . .
RUN pnpm install
RUN pnpm run build:ui

# Stage 2: Production image
FROM node:18-alpine AS production

LABEL maintainer="Etherpad team, https://github.com/ether/etherpad-lite"

# Optional timezone support
ARG TIMEZONE=UTC
ENV TIMEZONE=${TIMEZONE}

# Add etherpad user
RUN addgroup -S etherpad && adduser -S etherpad -G etherpad

# Install necessary dependencies
RUN apk add --no-cache \
    curl \
    bash \
    ca-certificates \
    git \
    tzdata && \
    cp /usr/share/zoneinfo/${TIMEZONE} /etc/localtime && \
    echo "${TIMEZONE}" > /etc/timezone

# Set working directory
WORKDIR /opt/etherpad-lite

# Copy built files
COPY --chown=etherpad:etherpad --from=adminbuild /opt/etherpad-lite .

# Switch to non-root user
USER etherpad

# Expose Etherpad port
EXPOSE 9001

# Health check
HEALTHCHECK --interval=10s --timeout=5s --start-period=15s \
  CMD curl --silent http://localhost:9001/health | grep -E "pass|ok|up" > /dev/null || exit 1

# Start Etherpad
CMD ["pnpm", "run", "start"]

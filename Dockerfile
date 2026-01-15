# Use the latest stable Directus image
FROM directus/directus:latest

# Set environment variables for Node.js
ENV NODE_ENV=production
ENV NPM_CONFIG_LOGLEVEL=warn

# Install system dependencies needed for extensions
RUN apk add --no-cache \
    build-base \
    python3 \
    make \
    g++ \
    git \
    && rm -rf /var/cache/apk/*

# Create a non-root user for security (Directus already uses 'node' user)
# Ensure proper permissions for extensions and uploads
RUN mkdir -p /directus/extensions /directus/uploads \
    && chown -R node:node /directus

# Set working directory
WORKDIR /directus

# Switch to non-root user
USER node

# Expose Directus port
EXPOSE 8055

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:8055/health || exit 1

# Default command (Directus will use its own entrypoint)
CMD ["npx", "directus", "start"]

# Use the latest stable Directus image
FROM directus/directus:latest

# Set environment variables for Node.js
ENV NODE_ENV=production
ENV NPM_CONFIG_LOGLEVEL=warn

# Install PostgreSQL client for running SQL scripts
USER root
RUN apk add --no-cache postgresql-client
USER node

# Create directories for extensions and uploads
RUN mkdir -p /directus/extensions /directus/uploads /directus/scripts

# Copy custom extension (without node_modules)
COPY --chown=node:node ./extensions/directus-extension-cotizador /directus/extensions/directus-extension-cotizador

# Copy initialization scripts
COPY --chown=node:node ./scripts/init-directus.sh /directus/init-directus.sh
COPY --chown=node:node ./scripts/init-schema.sql /directus/scripts/init-schema.sql
RUN chmod +x /directus/init-directus.sh

# Set working directory
WORKDIR /directus

# Expose Directus port
EXPOSE 8055

# Default command with custom initialization
CMD ["/directus/init-directus.sh"]

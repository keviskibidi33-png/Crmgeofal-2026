# Use the latest stable Directus image
FROM directus/directus:latest

# Set environment variables for Node.js
ENV NODE_ENV=production
ENV NPM_CONFIG_LOGLEVEL=warn

# Create directories for extensions and uploads
RUN mkdir -p /directus/extensions /directus/uploads

# Copy custom extension (without node_modules)
COPY ./extensions/directus-extension-cotizador /directus/extensions/directus-extension-cotizador

# Set working directory
WORKDIR /directus

# Expose Directus port
EXPOSE 8055

# Copy initialization script
COPY ./scripts/init-directus.sh /directus/init-directus.sh
RUN chmod +x /directus/init-directus.sh

# Default command with custom initialization
CMD ["/directus/init-directus.sh"]

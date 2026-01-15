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

# Default command (Directus will use its own entrypoint)
CMD ["npx", "directus", "start"]

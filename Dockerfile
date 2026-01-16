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

# Copy pre-built custom extension (dist folder must be committed)
COPY --chown=node:node ./extensions/directus-extension-cotizador /directus/extensions/directus-extension-cotizador

# Copy SQL initialization scripts
COPY --chown=node:node ./scripts/init-schema.sql /directus/scripts/init-schema.sql
COPY --chown=node:node ./scripts/fix-permissions.sql /directus/scripts/fix-permissions.sql
COPY --chown=node:node ./scripts/check-db.sql /directus/scripts/check-db.sql
COPY --chown=node:node ./scripts/diagnose-and-fix.sh /directus/scripts/diagnose-and-fix.sh
COPY --chown=node:node ./scripts/fix-directus11.sql /directus/scripts/fix-directus11.sql
COPY --chown=node:node ./scripts/fix-user-permissions.sql /directus/scripts/fix-user-permissions.sql
COPY --chown=node:node ./scripts/emergency-fix.sql /directus/scripts/emergency-fix.sql
COPY --chown=node:node ./scripts/uuid-fix.sql /directus/scripts/uuid-fix.sql
COPY --chown=node:node ./scripts/final-fix.sql /directus/scripts/final-fix.sql

# Set working directory
WORKDIR /directus

# Expose Directus port
EXPOSE 8055

# Default command - bootstrap, final fix, then start
CMD ["sh", "-c", "echo 'Starting Directus bootstrap...' && sleep 5 && npx directus bootstrap && echo 'Applying final fix...' && PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -U $DB_USER -d $DB_DATABASE -f /directus/scripts/final-fix.sql && echo 'Starting Directus...' && npx directus start"]

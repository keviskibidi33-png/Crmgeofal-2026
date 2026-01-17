FROM directus/directus:latest

ENV NODE_ENV=production \
    NPM_CONFIG_LOGLEVEL=warn

USER root
WORKDIR /directus

# Copy manifest files separately so dependency installs are cached
COPY --chown=node:node package*.json ./

RUN npm install --omit=dev --no-audit && \
    mkdir -p /directus/uploads && \
    chown -R node:node /directus

# Copy extensions at build time to bake them into the image
COPY --chown=node:node ./extensions ./extensions

USER node

EXPOSE 8055

CMD ["npx", "directus", "start"]

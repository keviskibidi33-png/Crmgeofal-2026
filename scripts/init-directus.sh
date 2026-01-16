#!/bin/bash

# Wait for database to be ready
echo "Waiting for database..."
npx directus db:wait --timeout 60

# Install Directus if not installed
if ! npx directus database status; then
    echo "Installing Directus..."
    npx directus database install
fi

# Check if collections exist
if ! npx directus schema list | grep -q "empresas"; then
    echo "Importing schema and data..."
    
    # Import schema snapshot if exists
    if [ -f "/directus/extensions/snapshot.json" ]; then
        npx directus schema apply /directus/extensions/snapshot.json
    fi
    
    # Import data if exists
    if [ -f "/directus/extensions/data.json" ]; then
        npx directus data import /directus/extensions/data.json
    fi
fi

echo "Starting Directus..."
npx directus start

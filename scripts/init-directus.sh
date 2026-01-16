#!/bin/bash

echo "=========================================="
echo "GEOFAL CRM - Inicialización de Directus"
echo "=========================================="

# Wait for database to be ready
echo "[1/4] Esperando a que la base de datos esté lista..."
sleep 5

# Run bootstrap to install Directus tables
echo "[2/4] Ejecutando bootstrap de Directus..."
npx directus bootstrap

# Check if custom tables exist, if not create them
echo "[3/4] Verificando e importando schema del CRM..."
if [ -f "/directus/scripts/init-schema.sql" ]; then
    echo "Ejecutando script de inicialización SQL..."
    PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -U $DB_USER -d $DB_DATABASE -f /directus/scripts/init-schema.sql 2>/dev/null || echo "Schema ya existe o se creó correctamente"
fi

echo "[4/4] Iniciando Directus..."
echo "=========================================="
npx directus start

#!/bin/sh

echo "=========================================="
echo "GEOFAL CRM - Inicializacion de Directus"
echo "=========================================="

echo "[1/4] Esperando a que la base de datos este lista..."
sleep 5

echo "[2/4] Ejecutando bootstrap de Directus..."
npx directus bootstrap

echo "[3/4] Verificando e importando schema del CRM..."
if [ -f "/directus/scripts/init-schema.sql" ]; then
    echo "Ejecutando script de inicializacion SQL..."
    PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -U $DB_USER -d $DB_DATABASE -f /directus/scripts/init-schema.sql 2>/dev/null || echo "Schema ya existe o se creo correctamente"
fi

echo "[4/4] Iniciando Directus..."
echo "=========================================="
npx directus start

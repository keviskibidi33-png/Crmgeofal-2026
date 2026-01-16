#!/bin/sh
# Script para diagnosticar y reparar problemas de permisos

echo "=== DIAGNÓSTICO DE BASE DE DATOS ==="
PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -U $DB_USER -d $DB_DATABASE -c "
SELECT 'Tablas CRM:' as info;
SELECT table_name FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name IN ('empresas', 'contactos', 'cotizaciones', 'cotizacion_items', 'quote_sequences');

SELECT 'Colecciones Directus:' as info;
SELECT collection FROM directus_collections 
WHERE collection IN ('empresas', 'contactos', 'cotizaciones', 'cotizacion_items', 'quote_sequences');

SELECT 'Rol Administrator ID:' as info;
SELECT id FROM directus_roles WHERE admin_access = true;

SELECT 'Permisos Administrator:' as info;
SELECT p.role, p.collection, p.action 
FROM directus_permissions p
JOIN directus_roles r ON p.role = r.id
WHERE r.admin_access = true 
AND p.collection IN ('empresas', 'contactos', 'cotizaciones', 'cotizacion_items', 'quote_sequences');
"

echo ""
echo "=== APLICANDE REPARACIÓN ==="
PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -U $DB_USER -d $DB_DATABASE -f /directus/scripts/fix-permissions.sql

echo ""
echo "=== VERIFICACIÓN FINAL ==="
PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -U $DB_USER -d $DB_DATABASE -c "
SELECT count(*) as tablas_creadas FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name IN ('empresas', 'contactos', 'cotizaciones', 'cotizacion_items', 'quote_sequences');

SELECT count(*) as colecciones_registradas FROM directus_collections 
WHERE collection IN ('empresas', 'contactos', 'cotizaciones', 'cotizacion_items', 'quote_sequences');

SELECT count(*) as permisos_admin FROM directus_permissions p
JOIN directus_roles r ON p.role = r.id
WHERE r.admin_access = true 
AND p.collection IN ('empresas', 'contactos', 'cotizaciones', 'cotizacion_items', 'quote_sequences');
"

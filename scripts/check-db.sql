-- Script para verificar estado de la base de datos
SELECT 'Tablas CRM:' as info;
SELECT table_name FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name IN ('empresas', 'contactos', 'cotizaciones', 'cotizacion_items', 'quote_sequences');

SELECT 'Colecciones Directus:' as info;
SELECT collection FROM directus_collections 
WHERE collection IN ('empresas', 'contactos', 'cotizaciones', 'cotizacion_items', 'quote_sequences');

SELECT 'Permisos Administrator:' as info;
SELECT role, collection, action FROM directus_permissions p
JOIN directus_roles r ON p.role = r.id
WHERE r.admin_access = true 
AND p.collection IN ('empresas', 'contactos', 'cotizaciones', 'cotizacion_items', 'quote_sequences');

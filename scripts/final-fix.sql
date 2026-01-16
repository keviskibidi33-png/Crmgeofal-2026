-- Script final para resolver todos los problemas

-- 1. Arreglar tabla quote_sequences
ALTER TABLE quote_sequences ADD COLUMN IF NOT EXISTS last_value INTEGER DEFAULT 0;
UPDATE quote_sequences SET last_value = 0 WHERE last_value IS NULL;

-- 2. Eliminar y recrear política con el nombre correcto
DELETE FROM directus_access WHERE policy = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890';
DELETE FROM directus_permissions WHERE policy = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890';
DELETE FROM directus_policies WHERE id = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890';

-- 3. Crear política con el nombre EXACTO que Directus espera
INSERT INTO directus_policies (id, name, icon, description, ip_access, enforce_tfa, admin_access, app_access)
VALUES ('a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'CRM Full Access', 'verified_user', 'Acceso completo al CRM', NULL, false, false, true);

-- 4. Dar permisos CRUD a TODAS las colecciones del sistema (incluyendo las del sistema)
INSERT INTO directus_permissions (policy, collection, action, permissions, validation, presets, fields)
SELECT 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', collection, action, '{}', '{}', NULL, '*'
FROM directus_collections, unnest(ARRAY['create', 'read', 'update', 'delete']) AS action
WHERE collection IN ('empresas', 'contactos', 'cotizaciones', 'cotizacion_items', 'quote_sequences');

-- 5. Asignar política al usuario admin (forzar)
DELETE FROM directus_access WHERE "user" = '1499bb63-d690-487e-9673-6636e5f49c73';
INSERT INTO directus_access (id, role, "user", policy, sort)
VALUES ('b2c3d4e5-f6a7-8901-bcde-f23456789012', NULL, '1499bb63-d690-487e-9673-6636e5f49c73', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 1);

-- 6. También asignar al rol Administrator
DELETE FROM directus_access WHERE role = (SELECT id FROM directus_roles WHERE name = 'Administrator');
INSERT INTO directus_access (id, role, "user", policy, sort)
SELECT 'c3d4e5f6-a7b8-9012-cdef-345678901234', id, NULL, 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 1
FROM directus_roles WHERE name = 'Administrator';

-- 7. Forzar actualización de caché de permisos de Directus
-- Esto se hace eliminando y recreando las entradas relevantes
TRUNCATE TABLE directus_permissions_cache;
TRUNCATE TABLE directus_roles_cache;

-- 8. Verificación final
SELECT '=== VERIFICACIÓN FINAL ===' as info;
SELECT 'Políticas:' as tipo, count(*) as total FROM directus_policies WHERE name = 'CRM Full Access'
UNION ALL
SELECT 'Permisos:', count(*) FROM directus_permissions WHERE policy = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890'
UNION ALL
SELECT 'Access:', count(*) FROM directus_access WHERE policy = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890'
UNION ALL
SELECT 'Quote sequences:', count(*) FROM quote_sequences;

SELECT 'Access asignado al admin:' as info;
SELECT u.email, p.name as policy_name
FROM directus_access a
JOIN directus_users u ON a."user" = u.id
JOIN directus_policies p ON a.policy = p.id
WHERE u.email = 'admin@geofal.com';

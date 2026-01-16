-- Script de emergencia para dar todos los permisos posibles

-- 1. Eliminar políticas existentes para limpiar
DELETE FROM directus_access WHERE policy = 'crm-full-access';
DELETE FROM directus_permissions WHERE policy = 'crm-full-access';
DELETE FROM directus_policies WHERE id = 'crm-full-access';

-- 2. Crear política sin restricciones
INSERT INTO directus_policies (id, name, icon, description, ip_access, enforce_tfa, admin_access, app_access)
VALUES ('crm-full-access', 'CRM Full Access', 'verified_user', 'Acceso completo sin restricciones', NULL, false, false, true);

-- 3. Dar permisos a TODAS las colecciones del sistema
INSERT INTO directus_permissions (policy, collection, action, permissions, validation, presets, fields)
SELECT 'crm-full-access', collection, action, '{}', '{}', NULL, '*'
FROM directus_collections, unnest(ARRAY['create', 'read', 'update', 'delete']) AS action
WHERE collection IN ('empresas', 'contactos', 'cotizaciones', 'cotizacion_items', 'quote_sequences', 'directus_users', 'directus_roles');

-- 4. Asignar a TODOS los usuarios (muy agresivo)
INSERT INTO directus_access (id, role, "user", policy, sort)
SELECT 
    'all-users-' || collection,
    NULL,
    u.id,
    'crm-full-access',
    1
FROM directus_users u, unnest(ARRAY['empresas', 'contactos', 'cotizaciones']) AS collection
WHERE NOT EXISTS (SELECT 1 FROM directus_access WHERE "user" = u.id AND policy = 'crm-full-access');

-- 5. Asignar a TODOS los roles
INSERT INTO directus_access (id, role, "user", policy, sort)
SELECT 
    'all-roles-' || collection,
    r.id,
    NULL,
    'crm-full-access',
    1
FROM directus_roles r, unnest(ARRAY['empresas', 'contactos', 'cotizaciones']) AS collection
WHERE NOT EXISTS (SELECT 1 FROM directus_access WHERE role = r.id AND policy = 'crm-full-access');

-- 6. Verificar qué se creó
SELECT 'Políticas creadas:' as info;
SELECT id, name FROM directus_policies WHERE id = 'crm-full-access';

SELECT 'Permisos creados:' as info;
SELECT count(*) as total_permisos FROM directus_permissions WHERE policy = 'crm-full-access';

SELECT 'Access asignado:' as info;
SELECT count(*) as total_access FROM directus_access WHERE policy = 'crm-full-access';

SELECT 'Usuarios con acceso:' as info;
SELECT u.email, a.policy FROM directus_access a
JOIN directus_users u ON a."user" = u.id
WHERE a.policy = 'crm-full-access';

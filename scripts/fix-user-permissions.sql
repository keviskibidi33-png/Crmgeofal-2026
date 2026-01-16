-- Script para asignar permisos directamente al usuario admin

-- 1. Verificar usuarios existentes
SELECT 'Usuarios existentes:' as info;
SELECT id, email, first_name, last_name FROM directus_users;

-- 2. Verificar si el admin user existe
SELECT 'Admin user ID:' as info;
SELECT id, email FROM directus_users WHERE email = 'admin@geofal.com';

-- 3. Crear política si no existe
INSERT INTO directus_policies (id, name, icon, description, ip_access, enforce_tfa, admin_access, app_access)
SELECT 
    'crm-full-access',
    'CRM Full Access',
    'verified_user',
    'Acceso completo a las colecciones del CRM',
    NULL,
    false,
    false,
    true
WHERE NOT EXISTS (SELECT 1 FROM directus_policies WHERE id = 'crm-full-access');

-- 4. Permisos para la política CRM
INSERT INTO directus_permissions (policy, collection, action, permissions, validation, presets, fields)
SELECT 'crm-full-access', 'empresas', action, '{}', '{}', NULL, '*'
FROM unnest(ARRAY['create', 'read', 'update', 'delete']) AS action
ON CONFLICT DO NOTHING;

INSERT INTO directus_permissions (policy, collection, action, permissions, validation, presets, fields)
SELECT 'crm-full-access', 'contactos', action, '{}', '{}', NULL, '*'
FROM unnest(ARRAY['create', 'read', 'update', 'delete']) AS action
ON CONFLICT DO NOTHING;

INSERT INTO directus_permissions (policy, collection, action, permissions, validation, presets, fields)
SELECT 'crm-full-access', 'cotizaciones', action, '{}', '{}', NULL, '*'
FROM unnest(ARRAY['create', 'read', 'update', 'delete']) AS action
ON CONFLICT DO NOTHING;

INSERT INTO directus_permissions (policy, collection, action, permissions, validation, presets, fields)
SELECT 'crm-full-access', 'cotizacion_items', action, '{}', '{}', NULL, '*'
FROM unnest(ARRAY['create', 'read', 'update', 'delete']) AS action
ON CONFLICT DO NOTHING;

INSERT INTO directus_permissions (policy, collection, action, permissions, validation, presets, fields)
SELECT 'crm-full-access', 'quote_sequences', action, '{}', '{}', NULL, '*'
FROM unnest(ARRAY['create', 'read', 'update', 'delete']) AS action
ON CONFLICT DO NOTHING;

-- 5. Asignar política directamente al usuario admin
INSERT INTO directus_access (id, role, "user", policy, sort)
SELECT
    'admin-user-crm-access',
    NULL,
    (SELECT id FROM directus_users WHERE email = 'admin@geofal.com'),
    'crm-full-access',
    1
WHERE NOT EXISTS (SELECT 1 FROM directus_access WHERE "user" = (SELECT id FROM directus_users WHERE email = 'admin@geofal.com'))
AND EXISTS (SELECT 1 FROM directus_users WHERE email = 'admin@geofal.com');

-- 6. También asignar al rol Administrator por si acaso
INSERT INTO directus_access (id, role, "user", policy, sort)
SELECT
    'admin-role-crm-access',
    (SELECT id FROM directus_roles WHERE name = 'Administrator'),
    NULL,
    'crm-full-access',
    1
WHERE NOT EXISTS (SELECT 1 FROM directus_access WHERE id = 'admin-role-crm-access')
AND EXISTS (SELECT 1 FROM directus_roles WHERE name = 'Administrator');

-- 7. Verificación final
SELECT 'Permisos asignados:' as info;
SELECT a.role, a."user", a.policy, u.email as user_email, r.name as role_name
FROM directus_access a
LEFT JOIN directus_users u ON a."user" = u.id
LEFT JOIN directus_roles r ON a.role = r.id
WHERE a.policy = 'crm-full-access';

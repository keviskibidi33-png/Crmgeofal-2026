-- Script con UUIDs válidos para Directus 11

-- 1. Generar UUIDs válidos para la política
DO $$
BEGIN
    -- Eliminar política existente si existe
    DELETE FROM directus_access WHERE policy = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890';
    DELETE FROM directus_permissions WHERE policy = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890';
    DELETE FROM directus_policies WHERE id = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890';
    
    -- Crear política con UUID válido
    INSERT INTO directus_policies (id, name, icon, description, ip_access, enforce_tfa, admin_access, app_access)
    VALUES ('a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'CRM Full Access', 'verified_user', 'Acceso completo a las colecciones del CRM', NULL, false, false, true);
    
    -- Crear permisos para cada colección
    INSERT INTO directus_permissions (policy, collection, action, permissions, validation, presets, fields)
    SELECT 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'empresas', action, '{}', '{}', NULL, '*'
    FROM unnest(ARRAY['create', 'read', 'update', 'delete']) AS action;
    
    INSERT INTO directus_permissions (policy, collection, action, permissions, validation, presets, fields)
    SELECT 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'contactos', action, '{}', '{}', NULL, '*'
    FROM unnest(ARRAY['create', 'read', 'update', 'delete']) AS action;
    
    INSERT INTO directus_permissions (policy, collection, action, permissions, validation, presets, fields)
    SELECT 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'cotizaciones', action, '{}', '{}', NULL, '*'
    FROM unnest(ARRAY['create', 'read', 'update', 'delete']) AS action;
    
    INSERT INTO directus_permissions (policy, collection, action, permissions, validation, presets, fields)
    SELECT 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'cotizacion_items', action, '{}', '{}', NULL, '*'
    FROM unnest(ARRAY['create', 'read', 'update', 'delete']) AS action;
    
    INSERT INTO directus_permissions (policy, collection, action, permissions, validation, presets, fields)
    SELECT 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'quote_sequences', action, '{}', '{}', NULL, '*'
    FROM unnest(ARRAY['create', 'read', 'update', 'delete']) AS action;
    
    -- Asignar política directamente al usuario admin
    INSERT INTO directus_access (id, role, "user", policy, sort)
    VALUES ('b2c3d4e5-f6a7-8901-bcde-f23456789012', NULL, '1499bb63-d690-487e-9673-6636e5f49c73', 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 1);
    
    -- También asignar al rol Administrator
    INSERT INTO directus_access (id, role, "user", policy, sort)
    VALUES ('c3d4e5f6-a7b8-9012-cdef-345678901234', (SELECT id FROM directus_roles WHERE name = 'Administrator'), NULL, 'a1b2c3d4-e5f6-7890-abcd-ef1234567890', 1);
END $$;

-- 2. Verificación
SELECT 'Política creada:' as info;
SELECT id, name FROM directus_policies WHERE id = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890';

SELECT 'Permisos creados:' as info;
SELECT count(*) as total FROM directus_permissions WHERE policy = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890';

SELECT 'Access asignado:' as info;
SELECT 
    a.id, 
    u.email as user_email, 
    r.name as role_name,
    p.name as policy_name
FROM directus_access a
LEFT JOIN directus_users u ON a."user" = u.id
LEFT JOIN directus_roles r ON a.role = r.id
LEFT JOIN directus_policies p ON a.policy = p.id
WHERE a.policy = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890';

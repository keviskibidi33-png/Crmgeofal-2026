-- Script compatible con Directus 11

-- 1. Crear tablas sin foreign keys a usuarios (Directus 11 usa UUID)
CREATE TABLE IF NOT EXISTS empresas (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(255) NOT NULL,
    ruc VARCHAR(20),
    direccion TEXT,
    telefono VARCHAR(50),
    email VARCHAR(255),
    sitio_web VARCHAR(255),
    notas TEXT,
    status VARCHAR(50) DEFAULT 'activo'
);

CREATE TABLE IF NOT EXISTS contactos (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(255) NOT NULL,
    apellido VARCHAR(255),
    email VARCHAR(255),
    telefono VARCHAR(50),
    celular VARCHAR(50),
    cargo VARCHAR(100),
    empresa_id INTEGER,
    notas TEXT,
    status VARCHAR(50) DEFAULT 'activo'
);

CREATE TABLE IF NOT EXISTS cotizaciones (
    id SERIAL PRIMARY KEY,
    numero VARCHAR(50) UNIQUE,
    empresa_id INTEGER,
    contacto_id INTEGER,
    fecha DATE DEFAULT CURRENT_DATE,
    fecha_validez DATE,
    estado VARCHAR(50) DEFAULT 'borrador',
    subtotal DECIMAL(15,2) DEFAULT 0,
    igv DECIMAL(15,2) DEFAULT 0,
    total DECIMAL(15,2) DEFAULT 0,
    items_count INTEGER DEFAULT 0,
    moneda VARCHAR(10) DEFAULT 'PEN',
    notas TEXT,
    condiciones TEXT,
    tiempo_entrega VARCHAR(100),
    forma_pago VARCHAR(100),
    archivo_url VARCHAR(500),
    template_id VARCHAR(50)
);

CREATE TABLE IF NOT EXISTS cotizacion_items (
    id SERIAL PRIMARY KEY,
    cotizacion_id INTEGER,
    descripcion TEXT NOT NULL,
    cantidad DECIMAL(15,4) DEFAULT 1,
    unidad VARCHAR(50) DEFAULT 'UND',
    precio_unitario DECIMAL(15,2) DEFAULT 0,
    descuento DECIMAL(5,2) DEFAULT 0,
    subtotal DECIMAL(15,2) DEFAULT 0,
    orden INTEGER DEFAULT 0
);

CREATE TABLE IF NOT EXISTS quote_sequences (
    id SERIAL PRIMARY KEY,
    year INTEGER NOT NULL,
    last_number INTEGER DEFAULT 0,
    prefix VARCHAR(10) DEFAULT 'COT',
    UNIQUE(year, prefix)
);

-- Insertar secuencia del año actual
INSERT INTO quote_sequences (year, last_number, prefix)
VALUES (EXTRACT(YEAR FROM CURRENT_DATE)::INTEGER, 0, 'COT')
ON CONFLICT (year, prefix) DO NOTHING;

-- 2. Verificar estructura de tablas de Directus
SELECT 'directus_permissions columns:' as info;
SELECT column_name, data_type FROM information_schema.columns 
WHERE table_name = 'directus_permissions' AND table_schema = 'public';

SELECT 'directus_roles columns:' as info;
SELECT column_name, data_type FROM information_schema.columns 
WHERE table_name = 'directus_roles' AND table_schema = 'public';

-- 3. Registrar colecciones (ya existen según logs)
-- Las colecciones ya están registradas, no es necesario repetir

-- 4. Dar permisos usando la estructura correcta de Directus 11
-- Primero verificamos si existe la política pública
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

-- Permisos para la política CRM
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

-- Asignar política al rol Administrator (usando el nombre correcto de la columna)
INSERT INTO directus_access (id, role, "user", policy, sort)
SELECT
    'admin-crm-access',
    (SELECT id FROM directus_roles WHERE name = 'Administrator'),
    NULL,
    'crm-full-access',
    1
WHERE NOT EXISTS (SELECT 1 FROM directus_access WHERE id = 'admin-crm-access')
AND EXISTS (SELECT 1 FROM directus_roles WHERE name = 'Administrator');

-- 5. Configurar branding
UPDATE directus_settings SET
    project_name = 'GEOFAL CRM',
    project_descriptor = 'Sistema de Gestión de Cotizaciones',
    project_color = '#1E40AF',
    default_language = 'es-ES',
    public_note = 'Bienvenido al CRM de GEOFAL - Sistema de Cotizaciones'
WHERE id = 1;

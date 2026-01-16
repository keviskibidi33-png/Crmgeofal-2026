-- Script para reparar todo el sistema de permisos y tablas

-- 1. Crear tablas si no existen
CREATE TABLE IF NOT EXISTS empresas (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(255) NOT NULL,
    ruc VARCHAR(20),
    direccion TEXT,
    telefono VARCHAR(50),
    email VARCHAR(255),
    sitio_web VARCHAR(255),
    notas TEXT,
    status VARCHAR(50) DEFAULT 'activo',
    user_created INTEGER REFERENCES directus_users(id),
    date_created TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    user_updated INTEGER REFERENCES directus_users(id),
    date_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS contactos (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(255) NOT NULL,
    apellido VARCHAR(255),
    email VARCHAR(255),
    telefono VARCHAR(50),
    celular VARCHAR(50),
    cargo VARCHAR(100),
    empresa_id INTEGER REFERENCES empresas(id) ON DELETE SET NULL,
    notas TEXT,
    status VARCHAR(50) DEFAULT 'activo',
    user_created INTEGER REFERENCES directus_users(id),
    date_created TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    user_updated INTEGER REFERENCES directus_users(id),
    date_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS cotizaciones (
    id SERIAL PRIMARY KEY,
    numero VARCHAR(50) UNIQUE,
    empresa_id INTEGER REFERENCES empresas(id) ON DELETE SET NULL,
    contacto_id INTEGER REFERENCES contactos(id) ON DELETE SET NULL,
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
    template_id VARCHAR(50),
    user_created INTEGER REFERENCES directus_users(id),
    date_created TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    user_updated INTEGER REFERENCES directus_users(id),
    date_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS cotizacion_items (
    id SERIAL PRIMARY KEY,
    cotizacion_id INTEGER REFERENCES cotizaciones(id) ON DELETE CASCADE,
    descripcion TEXT NOT NULL,
    cantidad DECIMAL(15,4) DEFAULT 1,
    unidad VARCHAR(50) DEFAULT 'UND',
    precio_unitario DECIMAL(15,2) DEFAULT 0,
    descuento DECIMAL(5,2) DEFAULT 0,
    subtotal DECIMAL(15,2) DEFAULT 0,
    orden INTEGER DEFAULT 0,
    date_created TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS quote_sequences (
    id SERIAL PRIMARY KEY,
    year INTEGER NOT NULL,
    last_number INTEGER DEFAULT 0,
    prefix VARCHAR(10) DEFAULT 'COT',
    UNIQUE(year, prefix)
);

-- Insertar secuencia del año actual si no existe
INSERT INTO quote_sequences (year, last_number, prefix)
VALUES (EXTRACT(YEAR FROM CURRENT_DATE)::INTEGER, 0, 'COT')
ON CONFLICT (year, prefix) DO NOTHING;

-- 2. Registrar colecciones en Directus
INSERT INTO directus_collections (collection, icon, note, display_template, hidden, singleton, translations, archive_field, archive_app_filter, archive_value, unarchive_value, sort_field, accountability, color, item_duplication_fields, sort, "group", collapse, preview_url, versioning)
VALUES ('empresas', 'business', 'Empresas/Clientes del CRM', '{{nombre}}', false, false, NULL, NULL, true, NULL, NULL, NULL, 'all', NULL, NULL, NULL, NULL, 'open', NULL, false)
ON CONFLICT (collection) DO NOTHING;

INSERT INTO directus_collections (collection, icon, note, display_template, hidden, singleton, translations, archive_field, archive_app_filter, archive_value, unarchive_value, sort_field, accountability, color, item_duplication_fields, sort, "group", collapse, preview_url, versioning)
VALUES ('contactos', 'people', 'Contactos de empresas', '{{nombre}} {{apellido}}', false, false, NULL, NULL, true, NULL, NULL, NULL, 'all', NULL, NULL, NULL, NULL, 'open', NULL, false)
ON CONFLICT (collection) DO NOTHING;

INSERT INTO directus_collections (collection, icon, note, display_template, hidden, singleton, translations, archive_field, archive_app_filter, archive_value, unarchive_value, sort_field, accountability, color, item_duplication_fields, sort, "group", collapse, preview_url, versioning)
VALUES ('cotizaciones', 'request_quote', 'Cotizaciones generadas', '{{numero}} - {{empresa_id.nombre}}', false, false, NULL, NULL, true, NULL, NULL, NULL, 'all', NULL, NULL, NULL, NULL, 'open', NULL, false)
ON CONFLICT (collection) DO NOTHING;

INSERT INTO directus_collections (collection, icon, note, display_template, hidden, singleton, translations, archive_field, archive_app_filter, archive_value, unarchive_value, sort_field, accountability, color, item_duplication_fields, sort, "group", collapse, preview_url, versioning)
VALUES ('cotizacion_items', 'list', 'Items de cotizaciones', '{{descripcion}}', true, false, NULL, NULL, true, NULL, NULL, 'orden', 'all', NULL, NULL, NULL, NULL, 'open', NULL, false)
ON CONFLICT (collection) DO NOTHING;

INSERT INTO directus_collections (collection, icon, note, display_template, hidden, singleton, translations, archive_field, archive_app_filter, archive_value, unarchive_value, sort_field, accountability, color, item_duplication_fields, sort, "group", collapse, preview_url, versioning)
VALUES ('quote_sequences', 'numbers', 'Secuencias de numeración', NULL, true, false, NULL, NULL, true, NULL, NULL, NULL, 'all', NULL, NULL, NULL, NULL, 'open', NULL, false)
ON CONFLICT (collection) DO NOTHING;

-- 3. Dar permisos al rol Administrator
INSERT INTO directus_permissions (role, collection, action, permissions, validation, presets, fields)
SELECT r.id, 'empresas', action, '{}', '{}', NULL, '*'
FROM directus_roles r, unnest(ARRAY['create', 'read', 'update', 'delete']) AS action
WHERE r.admin_access = true
ON CONFLICT (role, collection, action) DO NOTHING;

INSERT INTO directus_permissions (role, collection, action, permissions, validation, presets, fields)
SELECT r.id, 'contactos', action, '{}', '{}', NULL, '*'
FROM directus_roles r, unnest(ARRAY['create', 'read', 'update', 'delete']) AS action
WHERE r.admin_access = true
ON CONFLICT (role, collection, action) DO NOTHING;

INSERT INTO directus_permissions (role, collection, action, permissions, validation, presets, fields)
SELECT r.id, 'cotizaciones', action, '{}', '{}', NULL, '*'
FROM directus_roles r, unnest(ARRAY['create', 'read', 'update', 'delete']) AS action
WHERE r.admin_access = true
ON CONFLICT (role, collection, action) DO NOTHING;

INSERT INTO directus_permissions (role, collection, action, permissions, validation, presets, fields)
SELECT r.id, 'cotizacion_items', action, '{}', '{}', NULL, '*'
FROM directus_roles r, unnest(ARRAY['create', 'read', 'update', 'delete']) AS action
WHERE r.admin_access = true
ON CONFLICT (role, collection, action) DO NOTHING;

INSERT INTO directus_permissions (role, collection, action, permissions, validation, presets, fields)
SELECT r.id, 'quote_sequences', action, '{}', '{}', NULL, '*'
FROM directus_roles r, unnest(ARRAY['create', 'read', 'update', 'delete']) AS action
WHERE r.admin_access = true
ON CONFLICT (role, collection, action) DO NOTHING;

-- 4. Configurar branding
UPDATE directus_settings SET
    project_name = 'GEOFAL CRM',
    project_descriptor = 'Sistema de Gestión de Cotizaciones',
    project_color = '#1E40AF',
    default_language = 'es-ES',
    public_note = 'Bienvenido al CRM de GEOFAL - Sistema de Cotizaciones'
WHERE id = 1;

INSERT INTO directus_settings (id, project_name, project_descriptor, project_color, default_language, public_note)
SELECT 1, 'GEOFAL CRM', 'Sistema de Gestión de Cotizaciones', '#1E40AF', 'es-ES', 'Bienvenido al CRM de GEOFAL - Sistema de Cotizaciones'
WHERE NOT EXISTS (SELECT 1 FROM directus_settings WHERE id = 1);

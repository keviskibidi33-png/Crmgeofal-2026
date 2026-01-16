-- ============================================
-- GEOFAL CRM - Schema de Producción
-- ============================================
-- Este script crea las tablas necesarias para el CRM

-- Tabla: empresas
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

-- Tabla: contactos
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

-- Tabla: cotizaciones
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

-- Tabla: cotizacion_items
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

-- Tabla: quote_sequences (para numeración automática)
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

-- ============================================
-- Registrar colecciones en Directus
-- ============================================

-- Registrar colección: empresas
INSERT INTO directus_collections (collection, icon, note, display_template, hidden, singleton, translations, archive_field, archive_app_filter, archive_value, unarchive_value, sort_field, accountability, color, item_duplication_fields, sort, "group", collapse, preview_url, versioning)
VALUES ('empresas', 'business', 'Empresas/Clientes del CRM', '{{nombre}}', false, false, NULL, NULL, true, NULL, NULL, NULL, 'all', NULL, NULL, NULL, NULL, 'open', NULL, false)
ON CONFLICT (collection) DO NOTHING;

-- Registrar colección: contactos
INSERT INTO directus_collections (collection, icon, note, display_template, hidden, singleton, translations, archive_field, archive_app_filter, archive_value, unarchive_value, sort_field, accountability, color, item_duplication_fields, sort, "group", collapse, preview_url, versioning)
VALUES ('contactos', 'people', 'Contactos de empresas', '{{nombre}} {{apellido}}', false, false, NULL, NULL, true, NULL, NULL, NULL, 'all', NULL, NULL, NULL, NULL, 'open', NULL, false)
ON CONFLICT (collection) DO NOTHING;

-- Registrar colección: cotizaciones
INSERT INTO directus_collections (collection, icon, note, display_template, hidden, singleton, translations, archive_field, archive_app_filter, archive_value, unarchive_value, sort_field, accountability, color, item_duplication_fields, sort, "group", collapse, preview_url, versioning)
VALUES ('cotizaciones', 'request_quote', 'Cotizaciones generadas', '{{numero}} - {{empresa_id.nombre}}', false, false, NULL, NULL, true, NULL, NULL, NULL, 'all', NULL, NULL, NULL, NULL, 'open', NULL, false)
ON CONFLICT (collection) DO NOTHING;

-- Registrar colección: cotizacion_items
INSERT INTO directus_collections (collection, icon, note, display_template, hidden, singleton, translations, archive_field, archive_app_filter, archive_value, unarchive_value, sort_field, accountability, color, item_duplication_fields, sort, "group", collapse, preview_url, versioning)
VALUES ('cotizacion_items', 'list', 'Items de cotizaciones', '{{descripcion}}', true, false, NULL, NULL, true, NULL, NULL, 'orden', 'all', NULL, NULL, NULL, NULL, 'open', NULL, false)
ON CONFLICT (collection) DO NOTHING;

-- Registrar colección: quote_sequences (oculta)
INSERT INTO directus_collections (collection, icon, note, display_template, hidden, singleton, translations, archive_field, archive_app_filter, archive_value, unarchive_value, sort_field, accountability, color, item_duplication_fields, sort, "group", collapse, preview_url, versioning)
VALUES ('quote_sequences', 'numbers', 'Secuencias de numeración', NULL, true, false, NULL, NULL, true, NULL, NULL, NULL, 'all', NULL, NULL, NULL, NULL, 'open', NULL, false)
ON CONFLICT (collection) DO NOTHING;

-- ============================================
-- Permisos para el rol Admin
-- ============================================

-- Dar permisos completos a admin en todas las colecciones
INSERT INTO directus_permissions (role, collection, action, permissions, validation, presets, fields)
SELECT NULL, 'empresas', action, '{}', '{}', NULL, '*'
FROM unnest(ARRAY['create', 'read', 'update', 'delete']) AS action
ON CONFLICT DO NOTHING;

INSERT INTO directus_permissions (role, collection, action, permissions, validation, presets, fields)
SELECT NULL, 'contactos', action, '{}', '{}', NULL, '*'
FROM unnest(ARRAY['create', 'read', 'update', 'delete']) AS action
ON CONFLICT DO NOTHING;

INSERT INTO directus_permissions (role, collection, action, permissions, validation, presets, fields)
SELECT NULL, 'cotizaciones', action, '{}', '{}', NULL, '*'
FROM unnest(ARRAY['create', 'read', 'update', 'delete']) AS action
ON CONFLICT DO NOTHING;

INSERT INTO directus_permissions (role, collection, action, permissions, validation, presets, fields)
SELECT NULL, 'cotizacion_items', action, '{}', '{}', NULL, '*'
FROM unnest(ARRAY['create', 'read', 'update', 'delete']) AS action
ON CONFLICT DO NOTHING;

INSERT INTO directus_permissions (role, collection, action, permissions, validation, presets, fields)
SELECT NULL, 'quote_sequences', action, '{}', '{}', NULL, '*'
FROM unnest(ARRAY['create', 'read', 'update', 'delete']) AS action
ON CONFLICT DO NOTHING;

-- ============================================
-- Índices para mejor rendimiento
-- ============================================
CREATE INDEX IF NOT EXISTS idx_empresas_nombre ON empresas(nombre);
CREATE INDEX IF NOT EXISTS idx_empresas_ruc ON empresas(ruc);
CREATE INDEX IF NOT EXISTS idx_contactos_empresa ON contactos(empresa_id);
CREATE INDEX IF NOT EXISTS idx_contactos_email ON contactos(email);
CREATE INDEX IF NOT EXISTS idx_cotizaciones_empresa ON cotizaciones(empresa_id);
CREATE INDEX IF NOT EXISTS idx_cotizaciones_numero ON cotizaciones(numero);
CREATE INDEX IF NOT EXISTS idx_cotizaciones_user_created ON cotizaciones(user_created);
CREATE INDEX IF NOT EXISTS idx_cotizacion_items_cotizacion ON cotizacion_items(cotizacion_id);

-- ============================================
-- BRANDING Y CONFIGURACIÓN DEL PROYECTO
-- ============================================

-- Configurar branding de GEOFAL CRM
UPDATE directus_settings SET
    project_name = 'GEOFAL CRM',
    project_descriptor = 'Sistema de Gestión de Cotizaciones',
    project_color = '#1E40AF',
    default_language = 'es-ES',
    public_note = 'Bienvenido al CRM de GEOFAL - Sistema de Cotizaciones'
WHERE id = 1;

-- Si no existe, insertar configuración
INSERT INTO directus_settings (id, project_name, project_descriptor, project_color, default_language, public_note)
SELECT 1, 'GEOFAL CRM', 'Sistema de Gestión de Cotizaciones', '#1E40AF', 'es-ES', 'Bienvenido al CRM de GEOFAL - Sistema de Cotizaciones'
WHERE NOT EXISTS (SELECT 1 FROM directus_settings WHERE id = 1);

COMMIT;

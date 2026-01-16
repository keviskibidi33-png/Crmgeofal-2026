# Geofal CRM

Sistema CRM de Geofal con módulo de cotizaciones integrado. Basado en Directus + FastAPI + React.

## 🏗️ Arquitectura

```
┌──────────────────────────────────────────────────────────────┐
│                     Geofal CRM (Docker)                       │
├──────────────┬──────────────┬──────────────┬────────────────┤
│  Geofal CRM  │  Cotizador   │  Cotizador   │   PostgreSQL   │
│  (Directus)  │     API      │     Web      │   (Database)   │
│    :8055     │    :8000     │     :80      │     :5432      │
└──────────────┴──────────────┴──────────────┴────────────────┘
```

## 📁 Estructura del Proyecto

```
geofal-crm/
├── docker-compose.yml              # Orquestación (Coolify/Traefik ready)
├── Dockerfile                      # Imagen CRM personalizada
├── package.json                    # Scripts de gestión
├── .env.example                    # Variables de entorno
├── extensions/
│   └── directus-extension-cotizador/
│       └── src/module.vue          # Módulo Cotizador
├── cotizacion-twenty/
│   ├── quotes-service/             # Backend Python/FastAPI
│   └── cotizador-web/              # Frontend React/Vite
└── uploads/                        # Archivos generados
```

## 🚀 Inicio Rápido (Desarrollo Local)

### 1. Prerrequisitos

- Docker y Docker Compose instalados
- Node.js 18+ (para compilar extensiones)

### 2. Configuración

```bash
# Clonar o entrar al proyecto
cd crmtwenty

# Copiar variables de entorno
cp .env.example .env

# Editar .env con tus credenciales
# IMPORTANTE: Genera claves únicas para KEY y SECRET
openssl rand -hex 32  # Ejecuta esto 2 veces para KEY y SECRET
```

### 3. Compilar la Extensión Cotizador

```bash
# Instalar dependencias de la extensión
cd extensions/directus-extension-cotizador
npm install

# Compilar la extensión
npm run build

# Volver a la raíz
cd ../..
```

### 4. Levantar los Servicios

```bash
# Usando npm scripts
npm start

# O directamente con Docker
docker-compose up -d

# Ver logs en tiempo real
npm run logs
```

### 5. Acceder a Directus

- **URL:** http://localhost:8055
- **Usuario:** El configurado en `ADMIN_EMAIL`
- **Contraseña:** La configurada en `ADMIN_PASSWORD`

## ☁️ Despliegue en Coolify con Traefik

### Variables de Entorno Requeridas

```env
# Seguridad (genera con: openssl rand -hex 32)
DIRECTUS_KEY=<clave-unica>
DIRECTUS_SECRET=<secreto-unico>

# Base de Datos
DB_DATABASE=geofal_db
DB_USER=postgres
DB_PASSWORD=<password-seguro>

# Admin
ADMIN_EMAIL=admin@geofal.com
ADMIN_PASSWORD=<password-admin>

# Dominios (Traefik)
CRM_DOMAIN=crm.geofal.com
API_DOMAIN=api.geofal.com
COTIZADOR_DOMAIN=cotizador.geofal.com

# URLs Públicas
PUBLIC_URL=https://crm.geofal.com
COTIZADOR_EXTERNAL_URL=https://cotizador.geofal.com
COTIZADOR_API_URL=https://api.geofal.com
```

### Pasos en Coolify

1. **New Project** → **Docker Compose**
2. Conectar repositorio: `https://github.com/keviskibidi33-png/Crmgeofal-2026`
3. Agregar variables de entorno
4. **Deploy**

Los certificados SSL se generan automáticamente via Let's Encrypt.

## 🔧 Servicios

| Servicio | Dominio | Descripción |
|----------|---------|-------------|
| `geofal-crm` | crm.geofal.com | CRM Principal |
| `cotizador-api` | api.geofal.com | API Cotizaciones |
| `cotizador-web` | cotizador.geofal.com | Frontend Cotizador |
| `postgres` | (interno) | Base de datos |

## 📝 Comandos Útiles

```bash
npm start          # Levantar servicios
npm stop           # Detener servicios
npm run logs       # Ver logs
npm run rebuild    # Reconstruir
```

## 📄 Licencia

MIT - Geofal 2026

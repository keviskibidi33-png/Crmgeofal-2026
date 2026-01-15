# CRM Directus + Cotizador

CRM empresarial basado en **Directus** con módulo de cotización integrado (Python + React), conectado a **PostgreSQL** compartido.

## 🏗️ Arquitectura

```
┌─────────────────────────────────────────────────────────────┐
│                    Docker Compose                            │
├─────────────┬─────────────┬─────────────┬──────────────────┤
│  Directus   │  Cotizador  │  Cotizador  │    PostgreSQL    │
│   (CRM)     │    API      │    Web      │   (Shared DB)    │
│  :8055      │   :8000     │   :5173     │     :5432        │
└─────────────┴─────────────┴─────────────┴──────────────────┘
```

## 📁 Estructura del Proyecto

```
crmtwenty/
├── docker-compose.yml              # Orquestación de 4 servicios
├── Dockerfile                      # Imagen Directus personalizada
├── package.json                    # Scripts de gestión
├── .env.example                    # Variables de entorno
├── extensions/
│   └── directus-extension-cotizador/
│       ├── package.json
│       └── src/
│           ├── index.js            # Registro del módulo
│           └── module.vue          # Iframe al cotizador
├── cotizacion-twenty/              # Sistema de cotización
│   ├── quotes-service/             # Backend Python/FastAPI
│   │   ├── Dockerfile
│   │   ├── app/
│   │   │   ├── main.py
│   │   │   ├── database.py         # DB compartida con Directus
│   │   │   └── xlsx_direct_v2.py
│   │   └── requirements.txt
│   ├── cotizador-web/              # Frontend React/Vite
│   │   ├── Dockerfile
│   │   ├── src/
│   │   └── package.json
│   └── Formato-cotizacion.xlsx     # Template Excel
└── uploads/                        # Archivos compartidos
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

## 📊 Instalación de Spreadsheet Layout (Vista Tabular tipo Excel)

El equipo de ventas necesita una vista tipo Excel. Directus tiene la extensión oficial:

### Opción 1: Desde el Marketplace (Recomendado)

1. Ir a **Settings → Extensions** en Directus
2. Buscar "Spreadsheet Layout"
3. Instalar con un clic

### Opción 2: Via NPM

```bash
# Agregar al Dockerfile o ejecutar en el contenedor
npm install directus-extension-spreadsheet-layout
```

### Opción 3: Configurar en docker-compose.yml

Agregar la variable de entorno:

```yaml
environment:
  EXTENSIONS_AUTO_RELOAD: "true"
  # La extensión se puede instalar desde el marketplace
```

**Nota:** Una vez instalada, al crear/editar una colección, podrás seleccionar "Spreadsheet" como tipo de layout.

## 🗄️ Gestión del Schema (Migraciones)

### Crear Snapshot del Schema Actual

```bash
npm run schema:snapshot
```

Esto genera/actualiza `snapshot.yaml` con el estado actual de la base de datos.

### Aplicar Snapshot a Otra Base de Datos

```bash
npm run schema:apply
```

### Ver Diferencias

```bash
npm run schema:diff
```

## ☁️ Despliegue en Coolify

### Paso 1: Preparar el Repositorio

1. Subir el proyecto a GitHub/GitLab
2. Asegurarse de que `.env` está en `.gitignore`
3. Commit del `snapshot.yaml` si quieres versionar el schema

### Paso 2: Crear Proyecto en Coolify

1. Ir a **Projects → New Project**
2. Seleccionar **Docker Compose**
3. Conectar tu repositorio Git

### Paso 3: Configurar Variables de Entorno

En Coolify, ir a **Environment Variables** y agregar:

| Variable | Valor |
|----------|-------|
| `DIRECTUS_KEY` | (genera con `openssl rand -hex 32`) |
| `DIRECTUS_SECRET` | (genera con `openssl rand -hex 32`) |
| `DB_HOST` | `postgres` o IP de tu DB externa |
| `DB_PORT` | `5432` |
| `DB_DATABASE` | nombre_de_tu_db |
| `DB_USER` | usuario_postgres |
| `DB_PASSWORD` | contraseña_segura |
| `ADMIN_EMAIL` | admin@tuempresa.com |
| `ADMIN_PASSWORD` | contraseña_admin |
| `PUBLIC_URL` | https://crm.tudominio.com |
| `COTIZADOR_EXTERNAL_URL` | https://legacy.tudominio.com/cotizador.php |

### Paso 4: Configurar Base de Datos

**Opción A: PostgreSQL existente (externo)**
- Cambiar `DB_HOST` a la IP/dominio de tu servidor PostgreSQL
- Asegurar que el puerto 5432 está accesible desde Coolify

**Opción B: PostgreSQL en Coolify**
- Dejar el `docker-compose.yml` como está
- Coolify levantará PostgreSQL junto con Directus

### Paso 5: Configurar Dominio

1. En Coolify, ir a **Domains**
2. Agregar tu dominio: `crm.tudominio.com`
3. Habilitar SSL automático (Let's Encrypt)

### Paso 6: Desplegar

1. Clic en **Deploy**
2. Esperar a que la imagen se construya
3. Verificar logs si hay errores

## 🔧 Módulo Cotizador (Integrado)

El cotizador está completamente integrado como extensión de Directus y comparte la misma base de datos PostgreSQL.

### Servicios Docker

| Servicio | Puerto | Descripción |
|----------|--------|-------------|
| `directus` | 8055 | CRM principal |
| `cotizador-api` | 8000 | Backend Python/FastAPI |
| `cotizador-web` | 5173 | Frontend React/Vite |
| `postgres` | 5432 | Base de datos compartida |

### Flujo de Datos

1. Usuario abre "Cotizador" en Directus → iframe carga `localhost:5173`
2. Frontend React hace peticiones a `localhost:8000` (API Python)
3. API Python guarda cotización en PostgreSQL (misma DB que Directus)
4. Cotización aparece automáticamente en Directus

### Base de Datos Compartida

Tanto Directus como el Cotizador usan la misma base de datos. La tabla `cotizaciones` es accesible desde ambos:

```sql
-- Tabla creada por el cotizador, visible en Directus
cotizaciones (
  id, numero, year, cliente_nombre, cliente_ruc,
  proyecto, total, estado, archivo_path, items_json, ...
)
```

## 📝 Comandos Útiles

| Comando | Descripción |
|---------|-------------|
| `npm start` | Levantar servicios |
| `npm stop` | Detener servicios |
| `npm run logs` | Ver logs de Directus |
| `npm run rebuild` | Reconstruir imagen Docker |
| `npm run schema:snapshot` | Exportar schema actual |
| `npm run schema:apply` | Aplicar schema desde archivo |
| `npm run extension:build` | Compilar extensión Cotizador |
| `npm run extension:dev` | Modo desarrollo de extensión |

## 🐛 Solución de Problemas

### La extensión no aparece en el menú

1. Verificar que `dist/index.js` existe en la extensión
2. Reiniciar Directus: `docker-compose restart directus`
3. Revisar logs: `npm run logs`

### Error de conexión a PostgreSQL

1. Verificar que el servicio postgres está corriendo
2. Comprobar credenciales en `.env`
3. Si usas DB externa, verificar firewall/puertos

### El iframe no carga

1. Verificar que la URL en `COTIZADOR_EXTERNAL_URL` es correcta
2. El sistema legacy debe permitir ser embebido (sin `X-Frame-Options: DENY`)
3. Revisar consola del navegador para errores CORS

## 📄 Licencia

MIT - Libre para uso comercial y modificación.

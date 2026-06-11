# loans-software — Orquestación (Sistema de Préstamos)

Repo de **orquestación**: levanta todos los microservicios, sus bases de datos, el **API gateway**
(Nginx) y el **frontend** con un solo `docker-compose`. Empieza por aquí si quieres testear el sistema.

> Esta carpeta es solo orquestación. El código de cada servicio vive en su propio repo
> (`../user-login`, `../user-service`, `../loan-service`, `../admin-service`, `../loans-frontend`).

---

## 1. Arquitectura (cómo encajan las piezas)

```
                    Navegador
                        │  (solo habla con el gateway)
                        ▼
              ┌───────────────────────┐
              │  API Gateway (Nginx)  │  :3005  → enruta /api/v1/*
              └───────────┬───────────┘
        ┌─────────────┬────┴───────┬──────────────┐
        ▼             ▼            ▼              ▼
   user-login    user-service  loan-service   admin-service
   (auth/JWT)    (perfiles)    (préstamos)    (métricas/análisis)
     :3001          :3000        :3002           :3003
        │             │            │  └── HTTP → user-service
        │             │            │     admin-service ── HTTP → user-service + loan-service
        ▼             ▼            ▼              ▼
   pg 5433         pg 5432      pg 5434        pg 5435

   loans-frontend (React+MUI) :3004  → sirve el SPA (build estático con Nginx)
```

- **Todo el tráfico del navegador pasa por el gateway** (`:3005`), versionado en `/api/v1`.
  El gateway enruta a cada servicio: `/api/v1/auth` → user-login, `/api/v1/profiles` → user-service,
  `/api/v1/loans` → loan-service, `/api/v1/admin` y `/api/v1/credit-analysis` → admin-service.
- Comunicación entre servicios: **HTTP síncrono** (no hay broker). Cada servicio tiene su propia BD
  PostgreSQL (no comparten esquema; las relaciones entre datos son lógicas, sin FK físicas).
- **Auth:** `user-login` emite un JWT (HS256). Todos los servicios firman/verifican con el **mismo
  `JWT_SECRET`**. El frontend lo guarda y lo manda como `Authorization: Bearer <token>`.

| Componente | Puerto host | Rol | BD (puerto host) |
|---|---|---|---|
| user-login | 3001 | Autenticación / JWT | user-login-db (5433) |
| user-service | 3000 | Perfiles de usuario | user-service-db (5432) |
| loan-service | 3002 | Préstamos y pagos | loans-service (5434) |
| admin-service | 3003 | Backoffice / análisis crediticio | admin_service_db (5435) |
| loans-frontend | 3004 | SPA React | — |
| api-gateway | 3005 | Nginx (enrutado, CORS, rate limit) | — |

---

## 2. Arrancar todo (vía Docker — recomendado)

Requisitos: **Docker Desktop** corriendo y puertos 3000-3005 + 5432-5435 libres.

```bash
cd loans-software
# (opcional) configurar secretos; sin .env usa valores por defecto de desarrollo
copy .env.example .env

docker compose up --build          # primera vez tarda (compila 4 servicios + frontend)
docker compose up -d --wait        # en segundo plano y esperar a que estén "healthy"
docker compose ps                  # ver estado (los 4 servicios deben quedar "healthy")
```

Apagar:
```bash
docker compose down        # conserva los datos
docker compose down -v      # borra también los datos de las BD
```

### Variables de entorno (`.env`)
`docker-compose` lee `loans-software/.env` automáticamente. Lo importante:
- `JWT_SECRET`: **el mismo para los 4 servicios** (obligatorio en producción).
- `*_DB_PASSWORD`: contraseñas de cada Postgres.
- `CORS_ORIGINS`, `THROTTLE_TTL`, `THROTTLE_LIMIT`, `SALT_ROUNDS`.

---

## 3. Verificar salud

```bash
docker compose ps
# Health por servicio (OJO: la URL lleva /api/v1):
curl http://localhost:3000/api/v1/health/readiness   # user-service
curl http://localhost:3001/api/v1/health/readiness   # user-login
curl http://localhost:3002/api/v1/health/readiness   # loan-service
curl http://localhost:3003/api/v1/health/readiness   # admin-service
curl http://localhost:3005/health                     # gateway
```

Swagger (documentación viva) por servicio: `http://localhost:{3000,3001,3002,3003}/api/docs`.

---

## 3b. Datos de prueba (seed)

En `seeds/` hay un seed **idempotente** y coherente entre las 4 bases de datos (mismos UUID en
`users`, `profiles`, `loans` y `metrics`). Con el stack arriba (y los servicios `healthy` al menos
una vez, para que existan las tablas):

```bash
bash seeds/seed.sh                                       # Git Bash / WSL
powershell -ExecutionPolicy Bypass -File seeds\seed.ps1  # PowerShell
```

Usuarios creados (contraseña de todos: **`Password123!`**):

| Usuario | Rol | Datos asociados |
|---|---|---|
| `seed.admin` | admin | Perfil; puede ver dashboard, métricas y análisis crediticio |
| `seed.client1` | client | Perfil (ingreso 5.000.000, doc `1000000001`), 1 préstamo **activo** con 2 pagos y 1 **pagado** |
| `seed.client2` | client | Perfil (ingreso 2.500.000, doc `1000000002`), 1 préstamo **pendiente_aprobacion** |
| `seed.teller` | teller | Solo cuenta (el rol no tiene flujo implementado) |

Re-ejecutar el seed no duplica datos (`ON CONFLICT DO NOTHING`).

---

## 4. Flujo de uso end-to-end (lo que pasa entre servicios)

1. **Registro** — `POST /api/v1/auth/register` (user-login) crea el usuario y devuelve `access_token`.
2. **Perfil** — con ese token, `POST /api/v1/profiles` (user-service) crea el perfil (incluye
   `monthly_income`, usado luego por el análisis crediticio). Si falla, el frontend hace rollback
   con `DELETE /api/v1/auth/users/:id` (auto-borrado autorizado por el propio token).
3. **Solicitar préstamo** — `POST /api/v1/loans/request` (loan-service). Antes de crearlo valida la
   **capacidad de endeudamiento** consultando el perfil (HTTP a user-service).
4. **Aprobar/Rechazar** (admin) — `PUT /api/v1/loans/:id/approve` o `/reject`.
5. **Pagar** — `POST /api/v1/loans/:id/payments` (acepta header `Idempotency-Key` para no duplicar).
6. **Análisis/métricas** (admin) — admin-service consulta perfil (user-service) y préstamos
   (loan-service) para calcular score, capacidad y recomendaciones.

### Prueba rápida por el gateway (curl)
```bash
# 1) Registro (guarda el access_token y el id_user de la respuesta)
curl -s -X POST http://localhost:3005/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{"username":"juan01","email":"juan@test.com","password":"Password123!","role":"client"}'

# 2) Crear perfil (usa el token del paso 1)
TOKEN=...; UID=...
curl -s -X POST http://localhost:3005/api/v1/profiles \
  -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" \
  -d "{\"id_user\":\"$UID\",\"first_name\":\"Juan\",\"last_name\":\"Perez\",\"document_type\":\"CC\",\"document_number\":\"1020304050\",\"phone\":\"3001234567\",\"address\":\"Calle 1\"}"

# 3) Solicitar préstamo
curl -s -X POST http://localhost:3005/api/v1/loans/request \
  -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" \
  -d "{\"userId\":\"$UID\",\"amount\":1000000,\"typeId\":\"monthly_interest\"}"
```

O simplemente abre el **frontend** en http://localhost:3004 y usa la UI.

---

## 5. Gateway (Nginx)

`nginx.conf` (único archivo, montado en el contenedor `gateway`):
- Enruta `/api/v1/{auth,users,profiles,loans,admin,credit-analysis}` a cada upstream.
- **CORS** restringido por allowlist (no `*`); compatible con credentials.
- Cabeceras de seguridad (`X-Content-Type-Options`, `X-Frame-Options`, `Referrer-Policy`), gzip.
- **Rate limiting** (`limit_req`): más estricto en `/api/v1/auth/`.

Para añadir un origen permitido (p.ej. tu dominio), edita el bloque `map $http_origin $cors_origin`.

---

## 6. Problemas frecuentes

- **Un servicio queda `unhealthy`**: revisa `docker compose logs <servicio>`. Los healthchecks usan
  `127.0.0.1` (no `localhost`, que en Alpine resuelve a IPv6 y daría "connection refused").
- **`npm ci` falla en el build** (lock desincronizado): regenera el lock con npm 10 dentro del
  contenedor: `docker run --rm -v "<repo>:/app" -w /app node:20-alpine npm install --package-lock-only`.
- **CORS bloqueado en el navegador**: sirve el front desde `:3004` (no con `npm start` en otro
  puerto) o añade tu origen al gateway.
- **Dashboard de admin sin datos / error de tabla**: `admin-service` corre con `synchronize: false`,
  así que en una BD nueva no crea sus tablas. Ver el README de admin-service.

---

## 7. Convenciones

- Todas las rutas bajo **`/api/v1`** (prefijo global + versionado URI en Nest).
- Respuestas de user-service: `{ message, data }`.
- Logs estructurados JSON (pino) en los servicios (salvo admin-service, ver su README).

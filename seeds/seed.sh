#!/usr/bin/env bash
# Aplica los seeds a las 4 bases de datos (contenedores de docker-compose).
# Requisitos: stack levantado (docker compose up) y servicios "healthy" al menos
# una vez, para que synchronize haya creado las tablas en cada BD.
#
# Uso (desde loans-software/, en Git Bash o WSL):
#   bash seeds/seed.sh
#
# Es idempotente: re-ejecutarlo no duplica datos (ON CONFLICT DO NOTHING).
# Credenciales seed → usuario: seed.admin / seed.client1 / seed.client2 / seed.teller
#                    contraseña (todos): Password123!

set -euo pipefail
cd "$(dirname "$0")/.."

run_sql() {
  local container="$1" user="$2" db="$3" file="$4"
  echo "── $file → $container ($db)"
  docker compose exec -T "$container" psql -U "$user" -d "$db" -v ON_ERROR_STOP=1 < "seeds/$file"
}

run_sql postgres-user-login    authuser "user-login-db"    01-user-login.sql
run_sql postgres-user-service  admin    "user-service-db"  02-user-service.sql
run_sql postgres-loan-service  admin    "loans-service"    03-loan-service.sql
run_sql postgres-admin-service postgres "admin_service_db" 04-admin-service.sql

echo ""
echo "✅ Seed aplicado. Usuarios: seed.admin / seed.client1 / seed.client2 / seed.teller"
echo "   Contraseña (todos): Password123!"

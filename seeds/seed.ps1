# Aplica los seeds a las 4 bases de datos (contenedores de docker-compose).
# Requisitos: stack levantado (docker compose up) y servicios "healthy" al menos
# una vez, para que synchronize haya creado las tablas en cada BD.
#
# Uso (desde loans-software\):
#   powershell -ExecutionPolicy Bypass -File seeds\seed.ps1
#
# Es idempotente: re-ejecutarlo no duplica datos (ON CONFLICT DO NOTHING).
# Credenciales seed -> usuario: seed.admin / seed.client1 / seed.client2 / seed.teller
#                     contrasena (todos): Password123!

$ErrorActionPreference = 'Stop'
Set-Location (Join-Path $PSScriptRoot '..')

function Run-Sql([string]$Container, [string]$User, [string]$Db, [string]$File) {
  Write-Host ("-- {0} -> {1} ({2})" -f $File, $Container, $Db)
  Get-Content -Raw (Join-Path 'seeds' $File) |
    docker compose exec -T $Container psql -U $User -d $Db -v ON_ERROR_STOP=1
  if ($LASTEXITCODE -ne 0) { throw "Fallo aplicando $File en $Container" }
}

Run-Sql 'postgres-user-login'    'authuser' 'user-login-db'    '01-user-login.sql'
Run-Sql 'postgres-user-service'  'admin'    'user-service-db'  '02-user-service.sql'
Run-Sql 'postgres-loan-service'  'admin'    'loans-service'    '03-loan-service.sql'
Run-Sql 'postgres-admin-service' 'postgres' 'admin_service_db' '04-admin-service.sql'

Write-Host ''
Write-Host 'Seed aplicado. Usuarios: seed.admin / seed.client1 / seed.client2 / seed.teller'
Write-Host 'Contrasena (todos): Password123!'

# Loans Software - Sistema de Gestión de Préstamos

Sistema de gestión de préstamos construido con arquitectura de **microservicios** y **arquitectura hexagonal**. Este repositorio es el orquestador principal que contiene la configuración de Docker Compose para levantar todos los servicios del sistema.

## Descripción

Loans Software es una plataforma completa para la gestión de préstamos financieros. Utiliza microservicios independientes comunicados entre sí, desplegados con Docker y orquestados por Nginx como gateway de entrada.

## Arquitectura

El sistema está compuesto por los siguientes microservicios:

| Servicio | Repositorio | Descripción |
|---|---|---|
| **user-service** | [user-service](https://github.com/JuanPar063/user-service) | Gestión de usuarios y perfiles |
| **user-login** | [user-login](https://github.com/JuanPar063/user-login) | Autenticación con NestJS + PostgreSQL |
| **loan-service** | [loan-service](https://github.com/JuanPar063/loan-service) | Lógica de préstamos |
| **admin-service** | [admin-service](https://github.com/JuanPar063/admin-service) | Funciones administrativas |
| **loans-frontend** | [loans-frontend](https://github.com/JuanPar063/loans-frontend) | Frontend en TypeScript |

## Tecnologías Utilizadas

- **Docker & Docker Compose** – Contenedorización y orquestación
- **Nginx** – Gateway y proxy inverso
- **NestJS** – Framework backend (TypeScript)
- **PostgreSQL** – Base de datos relacional
- **Arquitectura Hexagonal** – Separación de capas de dominio, aplicación e infraestructura

## Requisitos Previos

- Docker >= 20.x
- Docker Compose >= 2.x

## Instalación y Ejecución

### Entorno de Desarrollo

```bash
git clone https://github.com/JuanPar063/loans-software.git
cd loans-software
docker-compose -f docker-compose.dev.yml up
```

### Entorno de Producción

```bash
docker-compose up -d
```

## Estructura del Repositorio

```
loans-software/
├── docker-compose.yml          # Configuración de producción
├── docker-compose.dev.yml      # Configuración de desarrollo
├── nginx-gateway.conf          # Configuración del gateway Nginx
├── nginx.conf                  # Configuración general de Nginx
├── .env                        # Variables de entorno
└── package.json
```

## Autor

Juan Sebastian Pardo Anzola – [@JuanPar063](https://github.com/JuanPar063)

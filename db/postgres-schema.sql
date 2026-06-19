-- ══════════════════════════════════════════════════════════════════════════════
-- BanQuito V2 — Cloud SQL PostgreSQL
-- Una sola base de datos "banquito" con schemas por servicio
--
-- Ejecutar con:
--   psql -h 136.112.87.173 -U <user> -d banquito < postgres-schema.sql
-- ══════════════════════════════════════════════════════════════════════════════

-- Schema: account_core  (account-core-service)
CREATE SCHEMA IF NOT EXISTS account_core;

-- Schema: accounting    (accounting-service)
CREATE SCHEMA IF NOT EXISTS accounting;
